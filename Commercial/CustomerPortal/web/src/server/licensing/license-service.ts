import { createAdminClient } from "@/utils/supabase/admin";
import {
  addDays,
  deriveTrialKey,
  generateLicenseKey,
  graceDays,
  hashClientIp,
  normalizeTrialEmail,
  nowIso,
  openSecret,
  safeEqualHex,
  sealSecret,
  seatsForType,
  sha256,
} from "./crypto";
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

export type CreateLicenseResult =
  | { ok: true; license: LicensePublicDto; plaintextKey: string; reused: boolean }
  | { ok: false; error: string; license?: LicensePublicDto | null };

function withoutMac(lic: Partial<LicenseRecord>): Omit<Partial<LicenseRecord>, "integrityMac"> {
  const { integrityMac, ...rest } = lic;
  void integrityMac;
  return rest;
}

function renewalLabel(lic: Partial<LicenseRecord>): string {
  if (lic.type === "lifetime") return "Lifetime — no renewal";
  if (lic.status === "cancelled") return "Cancelled";
  if (lic.status === "expired") return "Expired";
  if (lic.status === "grace") return "In grace period";
  if (lic.status === "active") return "Auto-renew eligible";
  return lic.status || "unknown";
}

export function toPublicLicense(lic: Partial<LicenseRecord>, seatsUsed: number): LicensePublicDto {
  return {
    id: lic.id!,
    keyMasked: `${lic.keyPrefix}-****-****-${lic.keyLast4}`,
    type: (lic.type as LicenseType) || "trial",
    status: (lic.status as LicenseStatus) || "pending",
    edition: lic.edition || "Professional",
    seatsUsed,
    seatsMax: lic.seatsMax || 1,
    createdAt: lic.createdAt || nowIso(),
    activatedAt: lic.activatedAt || null,
    expiresAt: lic.expiresAt || null,
    graceEndsAt: lic.graceEndsAt || null,
    renewalStatus: renewalLabel(lic),
    lastValidatedAt: lic.lastValidatedAt || null,
  };
}

async function findOldestTrialForEmailNorm(emailNorm: string): Promise<Partial<LicenseRecord> | null> {
  const supabase = createAdminClient();
  const { data, error } = await supabase
    .from("licenses")
    .select("*")
    .eq("type", "trial")
    .neq("status", "revoked")
    .eq("email_norm", emailNorm)
    .order("created_at", { ascending: true })
    .limit(1)
    .single();

  if (error || !data) return null;
  return mapSupabaseLicense(data);
}

function mapSupabaseLicense(row: any): Partial<LicenseRecord> {
  return {
    id: row.id,
    customerEmail: row.customer_email,
    customerName: row.customer_name,
    keyHash: row.key_hash,
    keyPrefix: row.key_prefix,
    keyLast4: row.key_last4,
    type: row.type,
    status: row.status,
    edition: row.edition,
    seatsMax: row.seats_max,
    createdAt: row.created_at,
    activatedAt: row.activated_at,
    expiresAt: row.expires_at,
    graceEndsAt: row.grace_ends_at,
    lastValidatedAt: row.last_validated_at,
    keyEnvelope: row.key_envelope,
    emailNorm: row.email_norm,
    issuedIpHash: row.issued_ip_hash,
    integrityMac: row.integrity_mac || "",
  };
}

function resolveTrialPlaintext(lic: Partial<LicenseRecord>, email: string): string | null {
  const sealed = openSecret(lic.keyEnvelope || "");
  if (sealed) return sealed.trim().toUpperCase();
  const derived = deriveTrialKey(email);
  if (safeEqualHex(lic.keyHash || "", sha256(derived)) || lic.keyHash === sha256(derived)) {
    return derived;
  }
  const derivedNorm = deriveTrialKey(lic.customerEmail || "");
  if (safeEqualHex(lic.keyHash || "", sha256(derivedNorm)) || lic.keyHash === sha256(derivedNorm)) {
    return derivedNorm;
  }
  return null;
}

async function ensureTrialClaim(input: {
  email: string;
  emailNorm: string;
  ipHash: string;
  licenseId: string;
  createdAt: string;
}): Promise<void> {
  const supabase = createAdminClient();
  const { data: existing } = await supabase
    .from("trial_claims")
    .select("id")
    .or(`license_id.eq.${input.licenseId},email_norm.eq.${input.emailNorm}`)
    .limit(1)
    .single();

  if (existing) return;

  await supabase.from("trial_claims").insert({
    id: `tcl_${Date.now().toString(36)}_${Math.random().toString(36).slice(2, 6)}`,
    email: input.email,
    email_norm: input.emailNorm,
    ip_hash: input.ipHash,
    license_id: input.licenseId,
    created_at: input.createdAt,
  });
}

export function rememberTrialKeyPlaintext(licenseId: string, plaintextKey: string): void {
  const key = plaintextKey.trim().toUpperCase();
  if (!key) return;
  
  const supabase = createAdminClient();
  supabase
    .from("licenses")
    .update({ key_envelope: sealSecret(key) })
    .eq("id", licenseId)
    .eq("type", "trial")
    .then(({ error }) => {
      if (error) console.warn("[Supabase] Failed to remember trial key:", error);
    });
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

export async function createLicense(input: {
  customerEmail: string;
  customerName: string;
  type: LicenseType;
  actorEmail?: string;
  skipEmail?: boolean;
  clientIp?: string | null;
  bypassIpCheck?: boolean;
}): Promise<CreateLicenseResult> {
  const email = input.customerEmail.trim().toLowerCase();
  const emailNorm = normalizeTrialEmail(email);
  const ipHash = hashClientIp(input.clientIp || "");
  const supabase = createAdminClient();

  if (input.type === "trial") {
    const existing = await findOldestTrialForEmailNorm(emailNorm);
    if (existing) {
      const plaintextKey = resolveTrialPlaintext(existing, email);
      if (!plaintextKey) {
        return {
          ok: false,
          error:
            "TRIAL_ALREADY_ISSUED: A free trial was already created for this email. The original key and expiry are unchanged. Paste the key you received earlier into Setup, or activate once in the portal so the key can be re-shown.",
          license: toPublicLicense(existing, 0),
        };
      }

      await supabase
        .from("licenses")
        .update({
          key_envelope: sealSecret(plaintextKey),
          email_norm: emailNorm,
          issued_ip_hash: ipHash || existing.issuedIpHash,
        })
        .eq("id", existing.id);

      await ensureTrialClaim({
        email,
        emailNorm,
        ipHash: ipHash || existing.issuedIpHash || "",
        licenseId: existing.id!,
        createdAt: existing.createdAt!,
      });

      return {
        ok: true,
        license: toPublicLicense(existing, 0),
        plaintextKey,
        reused: true,
      };
    }

    if (!input.bypassIpCheck && ipHash) {
      const { data: ipClaim } = await supabase
        .from("trial_claims")
        .select("email_norm")
        .eq("ip_hash", ipHash)
        .neq("email_norm", emailNorm)
        .limit(1)
        .single();

      const { data: licIp } = await supabase
        .from("licenses")
        .select("customer_email")
        .eq("type", "trial")
        .neq("status", "revoked")
        .eq("issued_ip_hash", ipHash)
        .not("email_norm", "eq", emailNorm)
        .limit(1)
        .single();

      if (ipClaim || licIp) {
        return {
          ok: false,
          error:
            "TRIAL_IP_LIMIT: A free trial was already claimed from this network/IP with a different email. One free trial per email and per IP.",
          license: null,
        };
      }
    }
  }

  const plaintextKey =
    input.type === "trial" ? deriveTrialKey(email) : generateLicenseKey(input.type);
  const keyHash = sha256(plaintextKey);
  const parts = plaintextKey.split("-");
  const keyPrefix = parts.slice(0, 2).join("-");
  const keyLast4 = parts[parts.length - 1] || "XXXX";
  const id = `lic_${Date.now().toString(36)}_${Math.random().toString(36).slice(2, 7)}`;
  const createdAt = nowIso();
  const expiresAt = expiresForType(input.type);

  const licenseData = {
    id,
    customer_email: email,
    customer_name: input.customerName,
    key_hash: keyHash,
    key_prefix: keyPrefix,
    key_last4: keyLast4,
    type: input.type,
    status: "pending",
    edition: product.edition,
    seats_max: seatsForType(input.type),
    created_at: createdAt,
    activated_at: null,
    expires_at: expiresAt,
    grace_ends_at: null,
    last_validated_at: null,
    key_envelope: input.type === "trial" ? sealSecret(plaintextKey) : null,
    email_norm: input.type === "trial" ? emailNorm : null,
    issued_ip_hash: input.type === "trial" ? ipHash || null : null,
    integrity_mac: "",
  };

  const { error: licError } = await supabase.from("licenses").insert(licenseData);
  if (licError) {
    console.error("[Supabase] Failed to create license:", licError);
    return { ok: false, error: "DATABASE_ERROR" };
  }

  const subscriptionData = {
    id: `sub_${id}`,
    license_id: id,
    customer_email: email,
    plan: input.type,
    status: subStatusFromLicense("pending"),
    renewal_date: expiresAt,
    expiration_date: expiresAt,
    grace_ends_at: null,
    cancelled_at: null,
    renewed_at: null,
    pending_plan_change: null,
  };

  await supabase.from("subscriptions").insert(subscriptionData);

  if (input.type === "trial") {
    await supabase.from("trial_claims").insert({
      id: `tcl_${Date.now().toString(36)}_${Math.random().toString(36).slice(2, 6)}`,
      email,
      email_norm: emailNorm,
      ip_hash: ipHash || "",
      license_id: id,
      created_at: createdAt,
    });
  }

  const publicLic: LicensePublicDto = {
    id,
    keyMasked: `${keyPrefix}-****-****-${keyLast4}`,
    type: input.type,
    status: "pending",
    edition: product.edition,
    seatsUsed: 0,
    seatsMax: seatsForType(input.type),
    createdAt,
    activatedAt: null,
    expiresAt,
    graceEndsAt: null,
    renewalStatus: "Auto-renew eligible",
    lastValidatedAt: null,
  };

  if (!input.skipEmail) {
    void sendLicenseCreatedEmail({
      to: email,
      customerName: input.customerName,
      packageType: input.type,
      plaintextKey,
      licenseId: id,
    }).catch((e) => console.warn("[licensing] create email failed:", e));
  }

  return { ok: true, license: publicLic, plaintextKey, reused: false };
}

export async function listLicensesForCustomer(email: string): Promise<LicensePublicDto[]> {
  const e = email.trim().toLowerCase();
  const supabase = createAdminClient();
  
  const { data: licenses, error } = await supabase
    .from("licenses")
    .select("*")
    .eq("customer_email", e);

  if (error || !licenses) {
    console.error("[Supabase] Failed to fetch licenses:", error);
    return [];
  }

  const { data: devices } = await supabase
    .from("devices")
    .select("license_id, status")
    .eq("status", "active");

  return licenses.map((lic) => {
    const mappedLic = mapSupabaseLicense(lic);
    const seatsUsed = devices?.filter((d) => d.license_id === lic.id).length || 0;
    return toPublicLicense(mappedLic, seatsUsed);
  });
}

export async function findLicenseByKey(plaintextKey: string): Promise<Partial<LicenseRecord> | null> {
  const hash = sha256(plaintextKey.trim().toUpperCase());
  const supabase = createAdminClient();
  
  const { data, error } = await supabase
    .from("licenses")
    .select("*")
    .eq("key_hash", hash)
    .limit(1)
    .single();

  if (error || !data) {
    const hash2 = sha256(plaintextKey.trim());
    const { data: data2 } = await supabase
      .from("licenses")
      .select("*")
      .eq("key_hash", hash2)
      .limit(1)
      .single();
    return data2 ? mapSupabaseLicense(data2) : null;
  }

  return mapSupabaseLicense(data);
}

export type ActivateResult =
  | { ok: true; license: LicensePublicDto; deviceId: string; token: string }
  | { ok: false; error: string };

export async function activateLicense(input: {
  plaintextKey: string;
  customerEmail: string;
  deviceName: string;
  deviceFingerprint: string;
  skipEmail?: boolean;
  replaceSingleSeat?: boolean;
}): Promise<ActivateResult> {
  const email = input.customerEmail.trim().toLowerCase();
  const key = input.plaintextKey.trim().toUpperCase();
  const supabase = createAdminClient();

  let lic = await findLicenseByKey(key);
  if (!lic) {
    lic = await findLicenseByKey(input.plaintextKey.trim());
  }
  if (!lic) return { ok: false, error: "LICENSE_NOT_FOUND" };

  if (
    lic.customerEmail !== email &&
    !(lic.type === "trial" && normalizeTrialEmail(lic.customerEmail || "") === normalizeTrialEmail(email))
  ) {
    return { ok: false, error: "LICENSE_EMAIL_MISMATCH" };
  }
  if (lic.status === "revoked") return { ok: false, error: "LICENSE_REVOKED" };
  if (lic.status === "expired") return { ok: false, error: "LICENSE_EXPIRED" };
  if (lic.status === "cancelled" && (!lic.expiresAt || Date.now() > Date.parse(lic.expiresAt))) {
    return { ok: false, error: "LICENSE_CANCELLED" };
  }

  if (lic.type === "trial") {
    rememberTrialKeyPlaintext(lic.id!, key);
    const refreshed = await supabase
      .from("licenses")
      .select("*")
      .eq("id", lic.id)
      .single();
    if (refreshed.data) {
      lic = mapSupabaseLicense(refreshed.data);
    }
  }

  const fpHash = sha256(input.deviceFingerprint.trim());
  const PORTAL_BROWSER_FP = "portal-browser-fingerprint";
  const portalBrowserFpHash = sha256(PORTAL_BROWSER_FP);

  const { data: activeDevices } = await supabase
    .from("devices")
    .select("*")
    .eq("license_id", lic.id)
    .eq("status", "active");

  const existing = activeDevices?.find((d) => d.fingerprint_hash === fpHash);

  let deviceId: string;
  if (existing) {
    deviceId = existing.id;
    await supabase
      .from("devices")
      .update({
        last_active_at: nowIso(),
        name: input.deviceName || existing.name,
      })
      .eq("id", existing.id);
  } else {
    const portalSeat = activeDevices?.find((d) => d.fingerprint_hash === portalBrowserFpHash);
    const canReplaceSingle =
      Boolean(input.replaceSingleSeat) &&
      (lic.seatsMax || 1) === 1 &&
      (activeDevices?.length || 0) >= 1 &&
      input.deviceFingerprint.trim() !== PORTAL_BROWSER_FP;
    const seatToReplace = portalSeat || (canReplaceSingle ? activeDevices?.[0] : null);

    if (seatToReplace && (activeDevices?.length || 0) >= (lic.seatsMax || 1)) {
      deviceId = seatToReplace.id;
      await supabase
        .from("devices")
        .update({
          fingerprint_hash: fpHash,
          name: input.deviceName || seatToReplace.name,
          last_active_at: nowIso(),
          transfer_requested_at: null,
        })
        .eq("id", seatToReplace.id);
    } else if ((activeDevices?.length || 0) >= (lic.seatsMax || 1)) {
      return { ok: false, error: "DEVICE_LIMIT_REACHED" };
    } else {
      deviceId = `dev_${Date.now().toString(36)}_${Math.random().toString(36).slice(2, 6)}`;
      await supabase.from("devices").insert({
        id: deviceId,
        license_id: lic.id!,
        customer_email: email,
        name: input.deviceName || "Unnamed device",
        fingerprint_hash: fpHash,
        status: "active",
        activation_date: nowIso(),
        last_active_at: nowIso(),
        transfer_requested_at: null,
      });
    }
  }

  const updatedStatus = lic.status === "grace" ? "grace" : "active";
  await supabase
    .from("licenses")
    .update({
      status: updatedStatus,
      activated_at: lic.activatedAt || nowIso(),
      last_validated_at: nowIso(),
    })
    .eq("id", lic.id);

  await autoCompletePendingTransfers(lic.id!, deviceId, email);

  const token = createValidationToken(lic.id!, deviceId, email);
  
  const { data: activeDevs } = await supabase
    .from("devices")
    .select("*")
    .eq("license_id", lic.id)
    .eq("status", "active");
  const seatsUsed = activeDevs?.length || 0;

  const updatedLic = await supabase
    .from("licenses")
    .select("*")
    .eq("id", lic.id)
    .single();

  const publicLic = toPublicLicense(
    mapSupabaseLicense(updatedLic.data || {}),
    seatsUsed
  );

  if (!input.skipEmail) {
    void sendLicenseActivatedEmail({
      to: email,
      customerName: lic.customerName || "",
      packageType: lic.type as LicenseType,
      keyMasked: publicLic.keyMasked,
      licenseId: lic.id!,
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

export function parseValidationToken(
  token: string
): { licenseId: string; deviceId: string; email: string; exp: string } | null {
  try {
    const raw = Buffer.from(token.trim(), "base64url").toString("utf8");
    const lastDot = raw.lastIndexOf(".");
    if (lastDot <= 0) return null;
    const sig = raw.slice(lastDot + 1);
    const withoutSig = raw.slice(0, lastDot);

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

export async function validateLicenseOnline(input: {
  licenseId: string;
  deviceId: string;
  customerEmail: string;
  deviceFingerprint: string;
}): Promise<{ ok: true; status: LicenseStatus; grace: boolean; token: string } | { ok: false; error: string }> {
  const email = input.customerEmail.trim().toLowerCase();
  const supabase = createAdminClient();

  const { data: licData, error } = await supabase
    .from("licenses")
    .select("*")
    .eq("id", input.licenseId)
    .single();

  if (error || !licData) return { ok: false, error: "LICENSE_NOT_FOUND" };
  
  const lic = mapSupabaseLicense(licData);
  if (lic.customerEmail !== email) return { ok: false, error: "LICENSE_EMAIL_MISMATCH" };

  const { data: device } = await supabase
    .from("devices")
    .select("*")
    .eq("id", input.deviceId)
    .eq("license_id", input.licenseId)
    .eq("status", "active")
    .single();

  if (!device) return { ok: false, error: "DEVICE_NOT_ACTIVE" };
  if (device.fingerprint_hash !== sha256(input.deviceFingerprint.trim())) {
    return { ok: false, error: "FINGERPRINT_MISMATCH" };
  }

  if (lic.status === "expired" || lic.status === "revoked") {
    return { ok: false, error: `LICENSE_${lic.status.toUpperCase()}` };
  }

  await supabase
    .from("licenses")
    .update({ last_validated_at: nowIso() })
    .eq("id", input.licenseId);

  await supabase
    .from("devices")
    .update({ last_active_at: nowIso() })
    .eq("id", input.deviceId);

  return {
    ok: true,
    status: lic.status as LicenseStatus,
    grace: lic.status === "grace",
    token: createValidationToken(lic.id!, device.id, email),
  };
}

export async function cancelLicense(licenseId: string, email: string): Promise<boolean> {
  const supabase = createAdminClient();
  const { error } = await supabase
    .from("licenses")
    .update({ status: "cancelled" })
    .eq("id", licenseId)
    .eq("customer_email", email.toLowerCase());

  return !error;
}

export async function renewLicense(licenseId: string, actorEmail: string): Promise<boolean> {
  const supabase = createAdminClient();
  const { data: lic } = await supabase
    .from("licenses")
    .select("*")
    .eq("id", licenseId)
    .single();

  if (!lic) return false;

  const newExp = expiresForType(lic.type as LicenseType);
  const { error } = await supabase
    .from("licenses")
    .update({
      status: "active",
      expires_at: newExp,
      grace_ends_at: null,
      last_validated_at: nowIso(),
    })
    .eq("id", licenseId);

  return !error;
}

export async function getLicenseById(id: string): Promise<Partial<LicenseRecord> | undefined> {
  const supabase = createAdminClient();
  const { data } = await supabase
    .from("licenses")
    .select("*")
    .eq("id", id)
    .single();

  return data ? mapSupabaseLicense(data) : undefined;
}

export async function listAllLicensesAdmin(): Promise<Partial<LicenseRecord>[]> {
  const supabase = createAdminClient();
  const { data } = await supabase
    .from("licenses")
    .select("*");

  return data?.map(mapSupabaseLicense) || [];
}
