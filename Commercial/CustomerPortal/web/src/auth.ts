import NextAuth from "next-auth";
import Google from "next-auth/providers/google";
import Credentials from "next-auth/providers/credentials";
import type { Provider } from "next-auth/providers";
import { authConfig } from "@/auth.config";
import { writeAudit } from "@/server/cloud/audit";
import { clearLoginFailures, isLoginBlocked, recordLoginFailure } from "@/server/cloud/security";
import { cacheSet, CacheKeys } from "@/server/cloud/cache";
import type { CloudRole } from "@/server/cloud/types";
import { normalizeAdminRole } from "@/server/admin/roles";
import { authenticatePassword, upsertOAuthAccount } from "@/server/accounts/service";

/**
 * Enterprise portal auth — Google OAuth · verified email/password · JWT · RBAC.
 * Standalone commercial service — no MetaTrader / Core Trading Engine imports.
 */

const providers: Provider[] = [];

function envList(name: string, fallback = ""): string[] {
  return (process.env[name] || fallback)
    .split(",")
    .map((s) => s.trim().toLowerCase())
    .filter(Boolean);
}

function resolveRole(email: string, explicit?: string): CloudRole {
  const e = (email || "").toLowerCase().trim();
  // Env roster always wins for elevation (even if JWT/session previously said "customer").
  if (e && envList("PORTAL_SUPER_ADMIN_EMAILS").includes(e)) return "super_admin";
  if (e && envList("PORTAL_ADMIN_EMAILS").includes(e)) return "super_admin";
  if (e && envList("PORTAL_COMMERCIAL_MANAGER_EMAILS").includes(e)) return "commercial_manager";
  if (e && envList("PORTAL_FINANCE_EMAILS").includes(e)) return "finance_manager";
  if (e && envList("PORTAL_QA_EMAILS").includes(e)) return "qa_manager";
  if (e && envList("PORTAL_AUDITOR_EMAILS").includes(e)) return "auditor";
  if (e && envList("PORTAL_SUPPORT_EMAILS").includes(e)) return "support_agent";
  if (explicit) {
    const n = normalizeAdminRole(explicit);
    if (n !== "customer") return n as CloudRole;
  }
  return "customer";
}

const googleClientId = (process.env.AUTH_GOOGLE_ID || process.env.GOOGLE_CLIENT_ID || "").trim();
const googleClientSecret = (process.env.AUTH_GOOGLE_SECRET || process.env.GOOGLE_CLIENT_SECRET || "").trim();
const googleLooksValid =
  googleClientId.includes(".apps.googleusercontent.com") && googleClientSecret.length >= 20;

if (googleLooksValid) {
  providers.push(
    Google({
      clientId: googleClientId,
      clientSecret: googleClientSecret,
      // Google advertises authorization_response_iss_parameter_supported but often omits `iss`
      // on the auth redirect; Auth.js then fails with Configuration / CallbackRouteError.
      // Use OAuth + userinfo (not discovery OIDC) so iss is not required on the callback.
      type: "oauth",
      authorization: {
        url: "https://accounts.google.com/o/oauth2/v2/auth",
        params: {
          scope: "openid email profile",
          prompt: "select_account",
        },
      },
      token: "https://oauth2.googleapis.com/token",
      userinfo: "https://openidconnect.googleapis.com/v1/userinfo",
      checks: ["pkce", "state"],
      profile(profile) {
        return {
          id: profile.sub,
          name: profile.name,
          email: profile.email,
          image: profile.picture,
        };
      },
    } as Parameters<typeof Google>[0])
  );
}

providers.push(
  Credentials({
    id: "credentials",
    name: "Email & Password",
    credentials: {
      email: { label: "Email", type: "email" },
      password: { label: "Password", type: "password" },
    },
    async authorize(credentials) {
      try {
        const email = String(credentials?.email || "").trim().toLowerCase();
        const password = String(credentials?.password || "");
        if (!email || !password) return null;
        if (await isLoginBlocked(email)) {
          writeAudit({
            user: email,
            action: "login_failed",
            ip: "auth",
            result: "denied",
            detail: "brute-force lockout",
          });
          return null;
        }
        const account = await authenticatePassword(email, password);
        if (!account) {
          await recordLoginFailure(email, "auth");
          writeAudit({
            user: email,
            action: "login_failed",
            ip: "auth",
            result: "denied",
            detail: "invalid credentials or unverified email",
          });
          return null;
        }
        await clearLoginFailures(email);
        const role = resolveRole(email);
        return {
          id: account.id,
          name: account.name,
          email: account.email,
          role,
        };
      } catch (e) {
        // Never let store/cache faults become an unhandled 500 on /login.
        console.error("[auth] credentials authorize failed", e instanceof Error ? e.message : e);
        return null;
      }
    },
  })
);

export const { handlers, auth, signIn, signOut } = NextAuth({
  ...authConfig,
  secret: process.env.AUTH_SECRET || process.env.NEXTAUTH_SECRET,
  providers,
  callbacks: {
    async signIn({ user, account }) {
      try {
        const email = (user.email || "").toLowerCase();
        if (!email) return false;
        if (await isLoginBlocked(email)) return false;
        if (account?.provider === "google") {
          await upsertOAuthAccount({ email, name: user.name });
        }
        return true;
      } catch (e) {
        console.error("[auth] signIn callback failed", e instanceof Error ? e.message : e);
        return false;
      }
    },
    async jwt({ token, user, trigger }) {
      try {
        const email = ((user?.email || token.email || "") as string).toLowerCase();
        if (email) token.email = email;
        if (user?.image) token.picture = user.image;

        // Re-resolve on every token pass so Vercel admin-roster env changes apply
        // without forcing a full re-login after deploy.
        const previous = String(token.role || "");
        token.role = email
          ? resolveRole(email, user ? (user as { role?: string }).role : undefined)
          : "customer";

        if (user) {
          writeAudit({
            user: email || "unknown",
            action: "login",
            ip: "auth",
            result: "success",
            detail: `provider login · role=${token.role}`,
          });
        }

        if (email && (user || trigger === "update" || previous !== String(token.role))) {
          await cacheSet(CacheKeys.session(email), String(token.role || "customer"), 60 * 60 * 8);
        }
        if (!token.role) token.role = "customer";
      } catch (e) {
        console.error("[auth] jwt callback failed", e instanceof Error ? e.message : e);
        if (!token.role) token.role = "customer";
      }
      return token;
    },
    async session({ session, token }) {
      if (session.user) {
        (session.user as { role?: string }).role = (token.role as string) || "customer";
        if (token.picture) session.user.image = token.picture as string;
        else if (token.image) session.user.image = token.image as string;
      }
      return session;
    },
  },
  events: {
    async signOut(message) {
      const token = "token" in message ? message.token : null;
      const email = (token?.email as string) || "unknown";
      writeAudit({
        user: email,
        action: "logout",
        ip: "auth",
        result: "success",
      });
    },
  },
  trustHost: true,
});

export { recordLoginFailure, resolveRole };
