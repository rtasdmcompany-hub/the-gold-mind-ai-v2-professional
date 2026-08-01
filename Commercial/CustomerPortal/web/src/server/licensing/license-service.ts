import {
  addDays,
  generateLicenseKey,
  graceDays,
  nowIso,
  safeEqualHex,
  seatsForType,
  sha256,
} from "./crypto";
import {
  appendAudit,
  computeIntegrityMac,
  mutateStore,
  readStore,
  verifyIntegrity,
} from "./store";
import { autoCompletePendingTransfers } from "./device-service";
import type {
  LicensePublicDto,
  LicenseRecord,
  LicenseStatus,
  LicenseType,
  SubscriptionStatus,
} from "./types";
import {
  sendLicenseActivatedEmail,
  sendLicenseCreatedEmail,
} from "@/server/accounts/license-emails";
import { product, productDurationDays } from "@/lib/product";

function withoutMac(lic: LicenseRecord): Omit<LicenseRecord, "integrityMac"> {
  const { integrityMac, ...rest } = lic;
  void integrityMac;
  return rest;
}

function renewalLabel(lic: LicenseRecord): string {
  if (lic.type === "lifetime") return "Lifetime — no renewal";
  if (lic.status === "cancelled") return "Cancelled";
  if (lic.status === "expired") return "Expired";
  if (lic.status === "grace") return "In grace period";
  if (lic.status === "active") return "Auto-renew eligible";
  return lic.status;
}

export function toPublicLicense(lic: LicenseRecord, seatsUsed: number): LicensePublicDto {
  return {
    id: lic.id,
    keyMasked: `${lic.keyPrefix}-****-****-${lic.keyLast4}`,
    type: lic.type,
    status: lic.status,
    edition: lic.edition,
    seatsUsed,
    seatsMax: lic.seatsMax,
    activatedAt: lic.activatedAt,
    expiresAt: lic.expiresAt,
    graceEndsAt: lic.graceEndsAt,
    renewalStatus: renewalLabel(lic),
    lastValidatedAt: lic.lastValidatedAt,
  };
}

function expiresForType(type: LicenseType, from: Date = new Date()): string | null {
  const days = productDurationDays(type);
  if (days === null) return null;
  return addDays(from, days);
}

function subStatusFromLicense(status: LicenseStatus): SubscriptionStatus {
  switch (status) {
    case "pending":
      return "trialing";
    case "active":
      return "active";
    case "grace":
      return "grace";
    case "cancelled":
      return "cancelled";
    case "expired":
    case "revoked":
      return "expired";
    default:
      return "active";
  }
}

/** Purchase → License Generation (returns plaintext key ONCE) */
export function createLicense(input: {
  customerEmail: string;
  customerName: string;
  type: LicenseType;
  actorEmail?: string;
  /** Skip Resend delivery (seed / internal). */
  skipEmail?: boolean;
}): { license: LicensePublicDto; plaintextKey: string } {
  const email = input.customerEmail.trim().toLowerCase();
  const plaintextKey = generateLicenseKey(input.type);
  const keyHash = sha256(plaintextKey);
  const parts = plaintextKey.split("-");
  const keyPrefix = parts.slice(0, 2).join("-");
  const keyLast4 = parts[parts.length - 1] || "XXXX";
  const id = `lic_${Date.now().toString(36)}_${Math.random().toString(36).slice(2, 7)}`;
  const createdAt = nowIso();
  const expiresAt = expiresForType(input.type);

  const base: Omit<LicenseRecord, "integrityMac"> = {
    id,
    customerEmail: email,
    customerName: input.customerName,
    keyHash,
    keyPrefix,
    keyLast4,
    type: input.type,
    status: "pending",
    edition: product.edition,
    seatsMax: seatsForType(input.type),
    createdAt,
    activatedAt: null,
    expiresAt,
    graceEndsAt: null,
    lastValidatedAt: null,
  };

  const license: LicenseRecord = {
    ...base,
    integrityMac: computeIntegrityMac(base),
  };

  const seatsUsed = 0;
  mutateStore((data) => {
    data.licenses.push(license);
    data.subscriptions.push({
      id: `sub_${id}`,
      licenseId: id,
      customerEmail: email,
      plan: input.type,
      status: subStatusFromLicense("pending"),
      renewalDate: expiresAt,
      expirationDate: expiresAt,
      graceEndsAt: null,
      cancelledAt: null,
      renewedAt: null,
      pendingPlanChange: null,
    });
    appendAudit(data, {
      actorEmail: input.actorEmail || email,
      action: "license.created",
      entityType: "license",
      entityId: id,
      detail: `Created ${input.type} license for ${email}`,
    });
  });

  const publicLic = toPublicLicense(license, seatsUsed);
  if (!input.skipEmail) {
    void sendLicenseCreatedEmail({
      to: email,
      customerName: input.customerName,
      packageType: input.type,
      plaintextKey,
      licenseId: id,
    }).catch((e) => console.warn("[licensing] create email failed:", e));
  }

  return { license: publicLic, plaintextKey };
}

export function listLicensesForCustomer(email: string): LicensePublicDto[] {
  const e = email.trim().toLowerCase();
  const data = readStore();
  return data.licenses
    .filter((l) => l.customerEmail === e)
    .map((l) => {
      assertNotTampered(l, e);
      const seatsUsed = data.devices.filter((d) => d.licenseId === l.id && d.status === "active").length;
      return toPublicLicense(refreshLicenseState(l), seatsUsed);
    });
}

function assertNotTampered(lic: LicenseRecord, actor: string): void {
  if (!verifyIntegrity(lic)) {
    mutateStore((data) => {
      appendAudit(data, {
        actorEmail: actor,
        action: "tamper.detected",
        entityType: "license",
        entityId: lic.id,
        detail: "License integrity MAC mismatch",
      });
    });
    throw new Error("LICENSE_TAMPER_DETECTED");
  }
}

/** Apply expiry / grace transitions (in-memory refresh + persist) */
export function refreshLicenseState(lic: LicenseRecord): LicenseRecord {
  const now = Date.now();
  let next = { ...lic };

  if (next.status === "revoked" || next.status === "cancelled") {
    return next;
  }

  if (next.expiresAt) {
    const exp = Date.parse(next.expiresAt);
    if (now > exp) {
      const graceEnd = next.graceEndsAt
        ? Date.parse(next.graceEndsAt)
        : Date.parse(addDays(next.expiresAt, graceDays()));
      if (!next.graceEndsAt) {
        next.graceEndsAt = addDays(next.expiresAt, graceDays());
      }
      if (now <= graceEnd && next.status !== "expired") {
        if (next.status !== "grace") {
          next.status = "grace";
          persistLicense(next, "system", "license.grace", "Entered grace period");
        }
      } else if (now > graceEnd) {
        if (next.status !== "expired") {
          next.status = "expired";
          persistLicense(next, "system", "license.expired", "License expired after grace");
        }
      }
    }
  }

  // Recompute MAC after status changes
  const rest = withoutMac(next);
  next = { ...rest, integrityMac: computeIntegrityMac(rest) };
  return next;
}

function persistLicense(
  lic: LicenseRecord,
  actor: string,
  action: "license.grace" | "license.expired" | "license.activated" | "license.validated" | "license.cancelled" | "license.renewed",
  detail: string
): void {
  const rest = withoutMac(lic);
  const updated: LicenseRecord = { ...rest, integrityMac: computeIntegrityMac(rest) };
  mutateStore((data) => {
    const idx = data.licenses.findIndex((l) => l.id === updated.id);
    if (idx >= 0) data.licenses[idx] = updated;
    const sub = data.subscriptions.find((s) => s.licenseId === updated.id);
    if (sub) {
      sub.status = subStatusFromLicense(updated.status);
      sub.expirationDate = updated.expiresAt;
      sub.graceEndsAt = updated.graceEndsAt;
      if (action === "license.cancelled") sub.cancelledAt = nowIso();
      if (action === "license.renewed") {
        sub.renewedAt = nowIso();
        sub.status = "renewed";
      }
    }
    appendAudit(data, {
      actorEmail: actor,
      action,
      entityType: "license",
      entityId: updated.id,
      detail,
    });
  });
}

export function findLicenseByKey(plaintextKey: string): LicenseRecord | null {
  const hash = sha256(plaintextKey.trim().toUpperCase());
  const data = readStore();
  const lic = data.licenses.find((l) => safeEqualHex(l.keyHash, hash) || l.keyHash === sha256(plaintextKey.trim()));
  // try both uppercased and as-is
  if (lic) return lic;
  const hash2 = sha256(plaintextKey.trim());
  return data.licenses.find((l) => l.keyHash === hash2) ?? null;
}

export type ActivateResult =
  | { ok: true; license: LicensePublicDto; deviceId: string; token: string }
  | { ok: false; error: string };

/**
 * Activation Request → Validation → Device Registration → Complete
 */
export function activateLicense(input: {
  plaintextKey: string;
  customerEmail: string;
  deviceName: string;
  deviceFingerprint: string;
  /** Skip Resend delivery (seed / internal). */
  skipEmail?: boolean;
  /**
   * Desktop installer path: when the only seat is already taken (portal soft-activate
   * or a previous PC), replace that seat instead of returning DEVICE_LIMIT_REACHED.
   * Never used for multi-seat paid licenses without an explicit transfer.
   */
  replaceSingleSeat?: boolean;
}): ActivateResult {
  const email = input.customerEmail.trim().toLowerCase();
  const key = input.plaintextKey.trim().toUpperCase();
  let lic = findLicenseByKey(key) || findLicenseByKey(input.plaintextKey.trim());
  if (!lic) return { ok: false, error: "LICENSE_NOT_FOUND" };

  assertNotTampered(lic, email);
  lic = refreshLicenseState(lic);

  if (lic.customerEmail !== email) return { ok: false, error: "LICENSE_EMAIL_MISMATCH" };
  if (lic.status === "revoked") return { ok: false, error: "LICENSE_REVOKED" };
  if (lic.status === "expired") return { ok: false, error: "LICENSE_EXPIRED" };
  if (lic.status === "cancelled" && (!lic.expiresAt || Date.now() > Date.parse(lic.expiresAt))) {
    return { ok: false, error: "LICENSE_CANCELLED" };
  }

  const fpHash = sha256(input.deviceFingerprint.trim());
  /** Soft seat used by portal "Activate in portal" — must not block real Windows Setup. */
  const PORTAL_BROWSER_FP = "portal-browser-fingerprint";
  const portalBrowserFpHash = sha256(PORTAL_BROWSER_FP);
  const data = readStore();
  const activeDevices = data.devices.filter((d) => d.licenseId === lic!.id && d.status === "active");
  const existing = activeDevices.find((d) => d.fingerprintHash === fpHash);

  let deviceId: string;
  if (existing) {
    deviceId = existing.id;
    mutateStore((store) => {
      const d = store.devices.find((x) => x.id === existing.id);
      if (d) {
        d.lastActiveAt = nowIso();
        d.name = input.deviceName || d.name;
      }
    });
  } else {
    const portalSeat = activeDevices.find((d) => d.fingerprintHash === portalBrowserFpHash);
    const canReplaceSingle =
      Boolean(input.replaceSingleSeat) &&
      lic.seatsMax === 1 &&
      activeDevices.length >= 1 &&
      input.deviceFingerprint.trim() !== PORTAL_BROWSER_FP;
    const seatToReplace = portalSeat || (canReplaceSingle ? activeDevices[0] : null);

    // Real installer fingerprint replaces portal soft-activate (or the only 1-seat device).
    if (seatToReplace && activeDevices.length >= lic.seatsMax) {
      deviceId = seatToReplace.id;
      mutateStore((store) => {
        const d = store.devices.find((x) => x.id === seatToReplace.id);
        if (d) {
          d.fingerprintHash = fpHash;
          d.name = input.deviceName || d.name;
          d.lastActiveAt = nowIso();
          d.transferRequestedAt = null;
        }
        appendAudit(store, {
          actorEmail: email,
          action: "device.registered",
          entityType: "device",
          entityId: deviceId,
          detail: portalSeat
            ? `Portal soft-activate seat replaced by real device on license ${lic!.id}`
            : `Single-seat license transferred to new device on license ${lic!.id}`,
        });
      });
    } else if (activeDevices.length >= lic.seatsMax) {
      return { ok: false, error: "DEVICE_LIMIT_REACHED" };
    } else {
      deviceId = `dev_${Date.now().toString(36)}_${Math.random().toString(36).slice(2, 6)}`;
      mutateStore((store) => {
        store.devices.push({
          id: deviceId,
          licenseId: lic!.id,
          customerEmail: email,
          name: input.deviceName || "Unnamed device",
          fingerprintHash: fpHash,
          status: "active",
          activationDate: nowIso(),
          lastActiveAt: nowIso(),
          transferRequestedAt: null,
        });
        appendAudit(store, {
          actorEmail: email,
          action: "device.registered",
          entityType: "device",
          entityId: deviceId,
          detail: `Device registered on license ${lic!.id}`,
        });
      });
    }
  }

  const activated: LicenseRecord = {
    ...lic,
    status: lic.status === "grace" ? "grace" : "active",
    activatedAt: lic.activatedAt || nowIso(),
    lastValidatedAt: nowIso(),
    integrityMac: "",
  };
  const rest = withoutMac(activated);
  const finalLic: LicenseRecord = { ...rest, integrityMac: computeIntegrityMac(rest) };
  persistLicense(finalLic, email, "license.activated", "Activation complete");
  // Destination activation completes any pending transfers on this license.
  autoCompletePendingTransfers(finalLic.id, deviceId, email);

  const token = createValidationToken(finalLic.id, deviceId, email);
  const seatsUsed = readStore().devices.filter((d) => d.licenseId === finalLic.id && d.status === "active").length;
  const publicLic = toPublicLicense(finalLic, seatsUsed);

  if (!input.skipEmail) {
    void sendLicenseActivatedEmail({
      to: email,
      customerName: finalLic.customerName,
      packageType: finalLic.type,
      keyMasked: publicLic.keyMasked,
      licenseId: finalLic.id,
      deviceName: input.deviceName,
    }).catch((e) => console.warn("[licensing] activate email failed:", e));
  }

  return {
    ok: true,
    license: publicLic,
    deviceId,
    token,
  };
}

export function createValidationToken(licenseId: string, deviceId: string, email: string): string {
  const exp = addDays(nowIso(), 1);
  const payload = `${licenseId}.${deviceId}.${email}.${exp}`;
  const sig = sha256(`${payload}|${process.env.LICENSE_STORE_SECRET || process.env.NEXTAUTH_SECRET || "dev"}`);
  return Buffer.from(`${payload}.${sig}`).toString("base64url");
}

/** Verify activation/validation token issued by createValidationToken. */
export function parseValidationToken(
  token: string
): { licenseId: string; deviceId: string; email: string; exp: string } | null {
  try {
    const raw = Buffer.from(token.trim(), "base64url").toString("utf8");
    const lastDot = raw.lastIndexOf(".");
    if (lastDot <= 0) return null;
    const sig = raw.slice(lastDot + 1);
    const withoutSig = raw.slice(0, lastDot);

    // exp is ISO at end (contains `.` for milliseconds): 2026-07-29T18:10:00.000Z
    const expMatch = withoutSig.match(/\.(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z)$/);
    if (!expMatch) return null;
    const exp = expMatch[1];
    const beforeExp = withoutSig.slice(0, -expMatch[0].length);

    const firstDot = beforeExp.indexOf(".");
    const secondDot = beforeExp.indexOf(".", firstDot + 1);
    if (firstDot < 0 || secondDot < 0) return null;

    const licenseId = beforeExp.slice(0, firstDot);
    const deviceId = beforeExp.slice(firstDot + 1, secondDot);
    const emailRaw = beforeExp.slice(secondDot + 1);
    if (!licenseId || !deviceId || !emailRaw || !sig) return null;
    if (Date.parse(exp) < Date.now()) return null;

    const payload = `${licenseId}.${deviceId}.${emailRaw}.${exp}`;
    const expected = sha256(
      `${payload}|${process.env.LICENSE_STORE_SECRET || process.env.NEXTAUTH_SECRET || "dev"}`
    );
    if (!safeEqualHex(sig, expected) && sig !== expected) return null;
    return { licenseId, deviceId, email: emailRaw.toLowerCase(), exp };
  } catch {
    return null;
  }
}

export function validateLicenseOnline(input: {
  licenseId: string;
  deviceId: string;
  customerEmail: string;
  deviceFingerprint: string;
}): { ok: true; status: LicenseStatus; grace: boolean; token: string } | { ok: false; error: string } {
  const email = input.customerEmail.trim().toLowerCase();
  const data = readStore();
  let lic = data.licenses.find((l) => l.id === input.licenseId);
  if (!lic) return { ok: false, error: "LICENSE_NOT_FOUND" };
  assertNotTampered(lic, email);
  lic = refreshLicenseState(lic);
  if (lic.customerEmail !== email) return { ok: false, error: "LICENSE_EMAIL_MISMATCH" };

  const device = data.devices.find((d) => d.id === input.deviceId && d.licenseId === lic!.id);
  if (!device || device.status !== "active") return { ok: false, error: "DEVICE_NOT_ACTIVE" };
  if (device.fingerprintHash !== sha256(input.deviceFingerprint.trim())) {
    return { ok: false, error: "FINGERPRINT_MISMATCH" };
  }

  if (lic.status === "expired" || lic.status === "revoked") {
    return { ok: false, error: `LICENSE_${lic.status.toUpperCase()}` };
  }

  mutateStore((store) => {
    const L = store.licenses.find((l) => l.id === lic!.id);
    const D = store.devices.find((d) => d.id === device!.id);
    if (L) {
      L.lastValidatedAt = nowIso();
      const rest = withoutMac(L);
      Object.assign(L, { ...rest, integrityMac: computeIntegrityMac(rest) });
    }
    if (D) D.lastActiveAt = nowIso();
    appendAudit(store, {
      actorEmail: email,
      action: "license.validated",
      entityType: "license",
      entityId: lic!.id,
      detail: "Online validation OK",
    });
  });

  return {
    ok: true,
    status: lic.status,
    grace: lic.status === "grace",
    token: createValidationToken(lic.id, device.id, email),
  };
}

export function cancelLicense(licenseId: string, email: string): boolean {
  const data = readStore();
  const lic = data.licenses.find((l) => l.id === licenseId && l.customerEmail === email.toLowerCase());
  if (!lic) return false;
  const next = { ...lic, status: "cancelled" as const };
  persistLicense(next, email, "license.cancelled", "Subscription cancelled by customer");
  return true;
}

export function renewLicense(licenseId: string, actorEmail: string): boolean {
  const data = readStore();
  const lic = data.licenses.find((l) => l.id === licenseId);
  if (!lic) return false;
  const newExp = expiresForType(lic.type);
  const next: LicenseRecord = {
    ...lic,
    status: "active",
    expiresAt: newExp,
    graceEndsAt: null,
    lastValidatedAt: nowIso(),
    integrityMac: "",
  };
  const rest = withoutMac(next);
  persistLicense({ ...rest, integrityMac: computeIntegrityMac(rest) }, actorEmail, "license.renewed", "License renewed");
  return true;
}

export function getLicenseById(id: string): LicenseRecord | undefined {
  return readStore().licenses.find((l) => l.id === id);
}

export function listAllLicensesAdmin(): LicenseRecord[] {
  return readStore().licenses.map((l) => refreshLicenseState(l));
}
