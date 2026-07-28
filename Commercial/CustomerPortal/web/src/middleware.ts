import NextAuth from "next-auth";
import { NextResponse } from "next/server";
import { authConfig } from "@/auth.config";
import { applySecurityHeaders, checkCsrf, enforceHttps } from "@/server/cloud/security-headers";

/**
 * Edge middleware — session gate only (no Node crypto / accounts store).
 * Full Google + credentials providers live in auth.ts (Node runtime).
 */
const { auth } = NextAuth({
  ...authConfig,
  secret: process.env.AUTH_SECRET || process.env.NEXTAUTH_SECRET,
});

export default auth((req) => {
  const httpsRedirect = enforceHttps(req);
  if (httpsRedirect) return applySecurityHeaders(httpsRedirect);

  const path = req.nextUrl.pathname;
  const isLoggedIn = !!(req.auth?.user?.email || req.auth?.user?.id);

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
    path === "/api/trading/sync" ||
    path === "/api/notifications/trade-closed" ||
    path.startsWith("/brand/") ||
    path.startsWith("/media/") ||
    path === "/favicon.ico" ||
    path === "/site.webmanifest" ||
    path === "/robots.txt" ||
    path === "/sitemap.xml";

  if (!checkCsrf(req, path)) {
    const denied = NextResponse.json(
      { ok: false, error: { code: "CSRF", message: "Origin mismatch" } },
      { status: 403 }
    );
    return applySecurityHeaders(denied);
  }

  if (!isLoggedIn && !isPublic) {
    if (path.startsWith("/api/")) {
      const res = NextResponse.json(
        { ok: false, error: { code: "UNAUTHORIZED", message: "Authentication required" } },
        { status: 401 }
      );
      return applySecurityHeaders(res);
    }
    const url = new URL("/login", req.nextUrl.origin);
    url.searchParams.set("callbackUrl", path);
    return applySecurityHeaders(NextResponse.redirect(url));
  }

  if (isLoggedIn && path === "/login") {
    return applySecurityHeaders(NextResponse.redirect(new URL("/portal", req.nextUrl.origin)));
  }

  return applySecurityHeaders(NextResponse.next());
});

export const config = {
  matcher: ["/((?!_next/static|_next/image|favicon.ico).*)"],
};
