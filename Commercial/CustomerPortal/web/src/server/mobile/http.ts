/**
 * Extract Bearer token for Mobile Companion commercial APIs.
 */
import { resolveMobileAccessToken } from "./auth";
import type { MobileSession } from "./types";

export function bearerFromRequest(req: Request): string | null {
  const h = req.headers.get("authorization") || req.headers.get("Authorization") || "";
  const m = /^Bearer\s+(.+)$/i.exec(h.trim());
  return m ? m[1].trim() : null;
}

export function requireMobileSession(req: Request): MobileSession {
  const token = bearerFromRequest(req);
  if (!token) throw new Error("UNAUTHORIZED");
  const session = resolveMobileAccessToken(token);
  if (!session) throw new Error("UNAUTHORIZED");
  if (!session.twoFactorVerified) throw new Error("2FA_REQUIRED");
  return session;
}

export function optionalMobileSession(req: Request): MobileSession | null {
  const token = bearerFromRequest(req);
  if (!token) return null;
  return resolveMobileAccessToken(token);
}
