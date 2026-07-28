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
  if (explicit) {
    const n = normalizeAdminRole(explicit);
    if (n !== "customer") return n as CloudRole;
    if (explicit === "customer") return "customer";
  }
  const e = email.toLowerCase();
  if (envList("PORTAL_SUPER_ADMIN_EMAILS", "admin@goldmind.local").includes(e)) return "super_admin";
  if (envList("PORTAL_ADMIN_EMAILS", "admin@goldmind.local").includes(e)) return "super_admin";
  if (envList("PORTAL_COMMERCIAL_MANAGER_EMAILS").includes(e)) return "commercial_manager";
  if (envList("PORTAL_FINANCE_EMAILS", "finance@goldmind.local").includes(e)) return "finance_manager";
  if (envList("PORTAL_QA_EMAILS", "qa@goldmind.local").includes(e)) return "qa_manager";
  if (envList("PORTAL_AUDITOR_EMAILS", "auditor@goldmind.local").includes(e)) return "auditor";
  if (envList("PORTAL_SUPPORT_EMAILS", "support@goldmind.local").includes(e)) return "support_agent";
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
    },
  })
);

export const { handlers, auth, signIn, signOut } = NextAuth({
  ...authConfig,
  secret: process.env.AUTH_SECRET || process.env.NEXTAUTH_SECRET,
  providers,
  callbacks: {
    async signIn({ user, account }) {
      const email = (user.email || "").toLowerCase();
      if (!email) return false;
      if (await isLoginBlocked(email)) return false;
      if (account?.provider === "google") {
        await upsertOAuthAccount({ email, name: user.name });
      }
      return true;
    },
    async jwt({ token, user, trigger }) {
      if (user) {
        const email = (user.email || "").toLowerCase();
        token.role = resolveRole(email, (user as { role?: string }).role);
        token.email = email;
        if (user.image) token.picture = user.image;
        if (email) {
          await cacheSet(CacheKeys.session(email), String(token.role || "customer"), 60 * 60 * 8);
        }
        writeAudit({
          user: email || "unknown",
          action: "login",
          ip: "auth",
          result: "success",
          detail: `provider login · role=${token.role}`,
        });
      }
      if (!token.role && token.email) {
        token.role = resolveRole(String(token.email));
      }
      if (!token.role) token.role = "customer";
      if (trigger === "update" && token.email) {
        await cacheSet(CacheKeys.session(String(token.email)), String(token.role), 60 * 60 * 8);
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
