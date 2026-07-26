/**
 * Admin security — session timeout · 2FA architecture · sensitive confirmations · IP logging.
 * Commercial admin layer only.
 */
import { createHash, randomBytes } from "crypto";
import { writeAudit } from "@/server/cloud/audit";
import { cacheGet, cacheSet, cacheDel, CacheKeys } from "@/server/cloud/cache";

/** Admin idle timeout (minutes). Shorter than general portal session. */
export function getAdminIdleTimeoutMinutes(): number {
  return Number(process.env.ADMIN_IDLE_TIMEOUT_MINUTES || 30);
}

export function getAdminSessionMaxHours(): number {
  return Number(process.env.ADMIN_SESSION_MAX_HOURS || 4);
}

export interface TwoFactorArchitecture {
  status: "architecture_ready";
  providers: Array<"totp" | "webauthn" | "email_otp">;
  enforcedForRoles: string[];
  enrollmentPath: string;
  recoveryCodes: boolean;
  note: string;
}

/** 2FA architecture (enrollment UI deferred; structure ready for Sprint+). */
export function getTwoFactorArchitecture(): TwoFactorArchitecture {
  return {
    status: "architecture_ready",
    providers: ["totp", "webauthn", "email_otp"],
    enforcedForRoles: ["super_admin", "finance_manager", "commercial_manager"],
    enrollmentPath: "/portal/admin/security#2fa",
    recoveryCodes: true,
    note: "Architecture defined — wire authenticator apps / WebAuthn before public launch. Trading Engine unrelated.",
  };
}

/** Sensitive action confirmation tokens (short-lived). */
export async function issueSensitiveConfirmToken(actor: string, action: string): Promise<string> {
  const token = randomBytes(16).toString("hex");
  const payload = JSON.stringify({ actor, action, at: Date.now() });
  await cacheSet(`tgm:confirm:${token}`, payload, 300);
  writeAudit({
    user: actor,
    action: "admin_action",
    ip: "admin",
    result: "success",
    detail: `confirm token issued for ${action}`,
  });
  return token;
}

export async function consumeSensitiveConfirmToken(
  token: string,
  actor: string,
  action: string
): Promise<boolean> {
  const raw = await cacheGet(`tgm:confirm:${token}`);
  if (!raw) return false;
  try {
    const parsed = JSON.parse(raw) as { actor: string; action: string };
    if (parsed.actor !== actor || parsed.action !== action) return false;
    await cacheDel(`tgm:confirm:${token}`);
    writeAudit({
      user: actor,
      action: "admin_action",
      ip: "admin",
      result: "success",
      detail: `confirmed sensitive action ${action}`,
    });
    return true;
  } catch {
    return false;
  }
}

export function hashIp(ip: string): string {
  return createHash("sha256").update(ip).digest("hex").slice(0, 16);
}

export async function logAdminSecurityEvent(input: {
  user: string;
  ip: string;
  event: string;
  result: "success" | "failure" | "denied";
}) {
  writeAudit({
    user: input.user,
    action: "admin_action",
    ip: input.ip,
    result: input.result,
    detail: input.event,
    meta: { ipHash: hashIp(input.ip), security: "1" },
  });
  await cacheSet(
    CacheKeys.perf(`admin-sec:${input.user}`),
    JSON.stringify({ at: new Date().toISOString(), event: input.event }),
    3600
  );
}

export function getAdminSecurityPolicy() {
  return {
    idleTimeoutMinutes: getAdminIdleTimeoutMinutes(),
    sessionMaxHours: getAdminSessionMaxHours(),
    twoFactor: getTwoFactorArchitecture(),
    ipLogging: true,
    permissionValidation: true,
    sensitiveActionConfirmation: true,
    securityEventLogging: true,
    tradingEngineAccess: false,
  };
}
