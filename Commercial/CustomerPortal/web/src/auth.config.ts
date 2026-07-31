import type { NextAuthConfig } from "next-auth";
import { RELEASE_INTERNAL_FETCH_HEADER } from "@/server/releases/internal-fetch";

/**
 * Edge-safe Auth.js config (middleware only).
 * Heavy Node providers / crypto stay in auth.ts — never import accounts store here.
 */
export const authConfig = {
  providers: [],
  session: {
    strategy: "jwt",
    maxAge: 60 * 60 * 8,
    updateAge: 60 * 30,
  },
  pages: {
    signIn: "/login",
    error: "/login",
  },
  trustHost: true,
  callbacks: {
    authorized({ auth, request }) {
      const path = request.nextUrl.pathname;
      const isLoggedIn = !!(auth?.user?.email || auth?.user?.id);
      const isPublic =
        path === "/" ||
        path === "/about" ||
        path === "/company" ||
        path === "/technology" ||
        path === "/infrastructure" ||
        path === "/security" ||
        path === "/login" ||
        path === "/register" ||
        path === "/verify-email" ||
        path === "/forgot-password" ||
        path === "/reset-password" ||
        path === "/pricing" ||
        path === "/docs" ||
        path === "/contact" ||
        path === "/privacy" ||
        path === "/terms" ||
        path === "/cookies" ||
        path === "/refund" ||
        path === "/risk" ||
        path.startsWith("/partners") ||
        path.startsWith("/developers") ||
        path.startsWith("/api/auth") ||
        path.startsWith("/api/health") ||
        path === "/api/v1/health" ||
        path === "/api/mobile/health" ||
        path.startsWith("/api/contact") ||
        path.startsWith("/api/billing/webhooks") ||
        path.startsWith("/api/releases/check") ||
        path.startsWith("/api/releases/download") ||
        path.startsWith("/api/releases/report") ||
        path === "/api/licenses/installer-activate" ||
        path === "/api/licenses/ready" ||
        path === "/api/notifications/trade-closed" ||
        path === "/api/trading/sync" ||
        path === "/api/partners/click" ||
        (path.startsWith("/releases/") &&
          !!(process.env.AUTH_SECRET || process.env.NEXTAUTH_SECRET || "").trim() &&
          request.headers.get(RELEASE_INTERNAL_FETCH_HEADER) ===
            (process.env.AUTH_SECRET || process.env.NEXTAUTH_SECRET || "").trim()) ||
        path.startsWith("/brand/") ||
        path.startsWith("/media/") ||
        path === "/favicon.ico" ||
        path === "/site.webmanifest" ||
        path === "/robots.txt" ||
        path === "/sitemap.xml";
      if (isPublic) return true;
      return isLoggedIn;
    },
  },
} satisfies NextAuthConfig;
