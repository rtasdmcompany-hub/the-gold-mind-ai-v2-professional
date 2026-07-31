/**
 * Edge-safe security helpers (middleware-compatible).
 * No fs / Node crypto — safe for Next.js Edge runtime.
 */
import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";

export function applySecurityHeaders(res: NextResponse): NextResponse {
  res.headers.set("X-Content-Type-Options", "nosniff");
  res.headers.set("X-Frame-Options", "DENY");
  res.headers.set("Referrer-Policy", "strict-origin-when-cross-origin");
  res.headers.set("Permissions-Policy", "camera=(), microphone=(), geolocation=()");
  res.headers.set("X-TGM-Cloud", "commercial-isolated");
  if (process.env.NODE_ENV === "production") {
    res.headers.set("Strict-Transport-Security", "max-age=31536000; includeSubDomains");
  }
  res.headers.set(
    "Content-Security-Policy",
    "default-src 'self'; img-src 'self' data: https:; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; connect-src 'self' https:; frame-ancestors 'none'"
  );
  return res;
}

export function enforceHttps(req: NextRequest): NextResponse | null {
  if (process.env.NODE_ENV !== "production") return null;
  if (process.env.ENFORCE_HTTPS === "false") return null;
  const proto = req.headers.get("x-forwarded-proto");
  if (proto && proto !== "https") {
    const url = req.nextUrl.clone();
    url.protocol = "https:";
    return NextResponse.redirect(url, 308);
  }
  return null;
}

export function applyCors(req: Request, res: NextResponse): NextResponse {
  const origin = req.headers.get("origin") || "";
  const allowed = (process.env.CORS_ALLOWED_ORIGINS || process.env.NEXTAUTH_URL || "")
    .split(",")
    .map((s) => s.trim())
    .filter(Boolean);
  if (origin && (allowed.includes(origin) || allowed.includes("*"))) {
    res.headers.set("Access-Control-Allow-Origin", origin);
    res.headers.set("Vary", "Origin");
    res.headers.set("Access-Control-Allow-Credentials", "true");
    res.headers.set("Access-Control-Allow-Headers", "Content-Type, Authorization, X-TGM-Request-Id");
    res.headers.set("Access-Control-Allow-Methods", "GET, POST, PUT, PATCH, DELETE, OPTIONS");
  }
  return res;
}

export function checkCsrf(req: NextRequest, path: string): boolean {
  if (req.method === "GET" || req.method === "HEAD" || req.method === "OPTIONS") return true;
  // Desktop / EA / webhook clients POST JSON without browser Origin — route handlers
  // authenticate via license key, email+fingerprint, or shared secrets.
  if (
    path.startsWith("/api/billing/webhooks") ||
    path.startsWith("/api/releases/report") ||
    path.startsWith("/api/releases/check") ||
    path === "/api/licenses/installer-activate" ||
    path === "/api/licenses/ready" ||
    path === "/api/notifications/trade-closed" ||
    path === "/api/trading/sync" ||
    path === "/api/partners/click" ||
    path.startsWith("/api/auth") ||
    path.startsWith("/api/health")
  ) {
    return true;
  }
  if (!path.startsWith("/api/")) return true;
  const origin = req.headers.get("origin");
  const referer = req.headers.get("referer");
  const host = req.headers.get("host") || "";
  const expected = process.env.NEXTAUTH_URL || "";
  if (origin) {
    try {
      const o = new URL(origin);
      if (expected && o.origin === new URL(expected).origin) return true;
      if (o.host === host) return true;
      return false;
    } catch {
      return false;
    }
  }
  if (referer) {
    try {
      const r = new URL(referer);
      if (r.host === host) return true;
    } catch {
      return false;
    }
  }
  // Production: fail closed when Origin/Referer absent on mutating API calls
  if (process.env.NODE_ENV === "production") return false;
  return true;
}
