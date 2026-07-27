import NextAuth from "next-auth";
import Google from "next-auth/providers/google";
import Credentials from "next-auth/providers/credentials";
import type { Provider } from "next-auth/providers";
import { writeAudit } from "@/server/cloud/audit";
import { clearLoginFailures, isLoginBlocked, recordLoginFailure } from "@/server/cloud/security";
import { cacheSet, CacheKeys } from "@/server/cloud/cache";
import type { CloudRole } from "@/server/cloud/types";
import { normalizeAdminRole } from "@/server/admin/roles";
import { shouldEnableDemoAuth } from "@/server/security/dev-bypass";

/**
 * Enterprise portal auth — Google OAuth · Email/Demo login · JWT sessions · RBAC.
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

if (process.env.GOOGLE_CLIENT_ID && process.env.GOOGLE_CLIENT_SECRET) {
  providers.push(
    Google({
      clientId: process.env.GOOGLE_CLIENT_ID,
      clientSecret: process.env.GOOGLE_CLIENT_SECRET,
    })
  );
}

if (shouldEnableDemoAuth(providers.length > 0)) {
  providers.push(
    Credentials({
      id: "demo",
      name: "Email Login",
      credentials: {
        email: { label: "Email", type: "email" },
      },
      async authorize(credentials) {
        const email = ((credentials?.email as string) || "demo@goldmind.local").toLowerCase();
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
        const role = resolveRole(email);
        await clearLoginFailures(email);
        const label =
          role === "super_admin" || role === "admin"
            ? "Portal Admin"
            : role === "support_agent" || role === "support"
              ? "Support Agent"
              : role === "finance_manager"
                ? "Finance Manager"
                : role === "commercial_manager"
                  ? "Commercial Manager"
                  : role === "qa_manager"
                    ? "QA Manager"
                    : role === "auditor"
                      ? "Auditor"
                      : "Customer";
        return {
          id: `${role}-${email}`,
          name: label,
          email,
          role,
        };
      },
    })
  );
}

export const { handlers, auth, signIn, signOut } = NextAuth({
  // Prefer AUTH_SECRET; fall back to NEXTAUTH_SECRET for Auth.js v5
  secret: process.env.AUTH_SECRET || process.env.NEXTAUTH_SECRET,
  providers,
  session: {
    strategy: "jwt",
    // Access session 8h; JWT acts as refreshable session token (Auth.js rotation on activity)
    maxAge: 60 * 60 * 8,
    updateAge: 60 * 30,
  },
  pages: {
    signIn: "/login",
  },
  callbacks: {
    async signIn({ user }) {
      const email = (user.email || "").toLowerCase();
      if (!email) return false;
      if (await isLoginBlocked(email)) return false;
      return true;
    },
    async jwt({ token, user, trigger }) {
      if (user) {
        const email = (user.email || "").toLowerCase();
        token.role = resolveRole(email, (user as { role?: string }).role);
        token.email = email;
        // Session cache hint for gateway / rate-limit affinity
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
      // Soft refresh: on session update, extend cache
      if (trigger === "update" && token.email) {
        await cacheSet(CacheKeys.session(String(token.email)), String(token.role), 60 * 60 * 8);
      }
      return token;
    },
    async session({ session, token }) {
      if (session.user) {
        (session.user as { role?: string }).role = (token.role as string) || "customer";
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

/** Export for login page brute-force recording */
export { recordLoginFailure, resolveRole };
