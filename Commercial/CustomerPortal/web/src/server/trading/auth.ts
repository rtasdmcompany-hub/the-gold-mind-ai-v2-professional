import { findLicenseByKey, parseValidationToken } from "@/server/licensing/license-service";
import { ensureStoreLoaded, readStore } from "@/server/licensing/store";
import { sha256 } from "@/server/licensing/crypto";

export type TradingCallerAuth =
  | { mode: "token"; token: string }
  | { mode: "fingerprint"; email: string; deviceFingerprint: string }
  | { mode: "license"; email: string; licenseKey: string };

export type TradingCallerIdentity =
  | { ok: true; email: string; licenseType?: string }
  | { ok: false; error: string; status: number };

/**
 * Shared commercial auth for EA/agent callbacks (trading sync + trade-closed notify).
 * Matches installer / notification patterns: Bearer validation token, or email+license, or email+fingerprint.
 */
export async function authenticateTradingCaller(auth: TradingCallerAuth): Promise<TradingCallerIdentity> {
  await ensureStoreLoaded();

  if (auth.mode === "token") {
    const parsed = parseValidationToken(auth.token);
    if (!parsed) return { ok: false, error: "INVALID_TOKEN", status: 401 };
    const data = readStore();
    const lic = data.licenses.find((l) => l.id === parsed.licenseId);
    const device = data.devices.find(
      (d) => d.id === parsed.deviceId && d.licenseId === parsed.licenseId && d.status === "active"
    );
    if (!lic || !device || lic.customerEmail !== parsed.email) {
      return { ok: false, error: "TOKEN_LICENSE_MISMATCH", status: 401 };
    }
    return { ok: true, email: parsed.email, licenseType: lic.type };
  }

  if (auth.mode === "license") {
    const email = auth.email.trim().toLowerCase();
    const lic = findLicenseByKey(auth.licenseKey);
    if (!lic || lic.customerEmail !== email) {
      return { ok: false, error: "LICENSE_AUTH_FAILED", status: 401 };
    }
    if (lic.status !== "active" && lic.status !== "grace") {
      return { ok: false, error: "LICENSE_NOT_ACTIVE", status: 403 };
    }
    return { ok: true, email, licenseType: lic.type };
  }

  const email = auth.email.trim().toLowerCase();
  const fpHash = sha256(auth.deviceFingerprint.trim());
  const data = readStore();
  const device = data.devices.find(
    (d) => d.customerEmail === email && d.fingerprintHash === fpHash && d.status === "active"
  );
  if (!device) return { ok: false, error: "DEVICE_NOT_FOUND", status: 401 };
  const lic = data.licenses.find((l) => l.id === device.licenseId);
  return { ok: true, email, licenseType: lic?.type };
}

export function parseTradingAuthFromRequest(input: {
  bearer?: string | null;
  body: Record<string, unknown>;
}): TradingCallerAuth | null {
  const email = String(input.body.email || input.body.customerEmail || "").trim();
  const deviceFingerprint = String(input.body.deviceFingerprint || "").trim();
  const licenseKey = String(input.body.licenseKey || input.body.plaintextKey || "").trim();
  const token =
    (input.bearer || "").trim() || String(input.body.token || input.body.validationToken || "").trim();

  if (token) return { mode: "token", token };
  if (email && licenseKey) return { mode: "license", email, licenseKey };
  if (email && deviceFingerprint) return { mode: "fingerprint", email, deviceFingerprint };
  return null;
}
