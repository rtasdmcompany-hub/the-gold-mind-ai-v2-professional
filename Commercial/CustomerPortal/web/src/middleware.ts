import { auth } from "@/auth";
import { NextResponse } from "next/server";
import { applySecurityHeaders, checkCsrf, enforceHttps } from "@/server/cloud/security-headers";

/**
 * Cloud edge middleware — session gate · HTTPS · CSRF · security headers.
 *
 * Public (no session):
 * - /login
 * - /api/auth/*
 * - /api/health
 * - /api/billing/webhooks/*
 * - /api/releases/check|download|report
 *
 * Trading Engine / MQL5 Market are never involved.
 */
export default auth((req) => {
  const httpsRedirect = enforceHttps(req);
  if (httpsRedirect) return applySecurityHeaders(httpsRedirect);

  const path = req.nextUrl.pathname;
  const isLoggedIn = !!req.auth;

  const isPublic =
    path === "/" ||
    path === "/login" ||
    path === "/register" ||
    path === "/pricing" ||
    path === "/docs" ||
    path === "/contact" ||
    path === "/privacy" ||
    path === "/terms" ||
    path === "/cookies" ||
    path === "/refund" ||
    path === "/risk" ||
    path.startsWith("/api/auth") ||
    path.startsWith("/api/health") ||
    path.startsWith("/api/contact") ||
    path.startsWith("/api/billing/webhooks") ||
    path.startsWith("/api/releases/check") ||
    path.startsWith("/api/releases/download") ||
    path.startsWith("/api/releases/report");

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
