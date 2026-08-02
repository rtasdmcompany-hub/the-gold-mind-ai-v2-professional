"use server";

import { revalidatePath } from "next/cache";
import { headers } from "next/headers";
import { activateLicense, createLicense, renewLicense, cancelLicense } from "@/server/licensing/license-service";
import {
  deactivateDevice,
  renameDevice,
  requestDeviceTransfer,
  completeDeviceTransfer,
} from "@/server/licensing/device-service";
import { requireAdmin, requireSession } from "@/server/licensing/session";
import { ensureStoreLoaded, flushStoreVerified } from "@/server/licensing/store";
import { assertDurableStoreForLicensing } from "@/server/cloud/cache";
import { clientIpFromHeaders } from "@/server/cloud/audit";
import type { LicenseType } from "@/server/licensing/types";
import {
  isFreeRenewAllowed,
  isSelfServeLicenseTypeAllowed,
} from "@/server/billing/config";
import { cancelBillingSubscriptionForLicense } from "@/server/billing/billing-service";
import { ensureBillingStoreLoaded, flushBillingStore } from "@/server/billing/store";

export async function actionCreateLicense(type: LicenseType) {
  const s = await requireSession();
  if (!isSelfServeLicenseTypeAllowed(type)) {
    return {
      ok: false as const,
      error:
        "SELF_SERVE_LICENSE_BLOCKED: Paid keys are issued after verified checkout (Billing) or by an admin. Trial remains available, or set PORTAL_ALLOW_SELF_SERVE_LICENSE=true for non-payment minting.",
      plaintextKey: "",
      license: null,
      reused: false,
    };
  }
  try {
    await ensureStoreLoaded();
    const h = await headers();
    const clientIp = clientIpFromHeaders(h);
    const result = createLicense({
      customerEmail: s.email,
      customerName: s.name,
      type,
      actorEmail: s.email,
      clientIp,
    });
    if (!result.ok) {
      await flushStoreVerified().catch(() => undefined);
      revalidatePath("/portal/licenses");
      return {
        ok: false as const,
        error: result.error,
        plaintextKey: "",
        license: result.license ?? null,
        reused: false,
      };
    }
    await flushStoreVerified().catch(() => undefined);
    revalidatePath("/portal");
    revalidatePath("/portal/licenses");
    revalidatePath("/portal/subscriptions");
    return {
      ok: true as const,
      license: result.license,
      plaintextKey: result.plaintextKey,
      reused: result.reused,
    };
  } catch (e) {
    const msg = e instanceof Error ? e.message : "LICENSE_CREATE_FAILED";
    console.error("[licensing] actionCreateLicense failed", msg);
    return {
      ok: false as const,
      error: msg.includes("DURABLE_STORE")
        ? "License storage is temporarily unavailable. Please try again shortly or contact support."
        : msg,
      plaintextKey: "",
      license: null,
      reused: false,
    };
  }
}

export async function actionActivateLicense(formData: FormData) {
  const s = await requireSession();
  assertDurableStoreForLicensing();
  await ensureStoreLoaded();
  const plaintextKey = String(formData.get("licenseKey") || "");
  const deviceName = String(formData.get("deviceName") || "Portal Device");
  const deviceFingerprint = String(formData.get("deviceFingerprint") || `portal-${s.email}`);
  const result = activateLicense({
    plaintextKey,
    customerEmail: s.email,
    deviceName,
    deviceFingerprint,
  });
  await flushStoreVerified();
  revalidatePath("/portal");
  revalidatePath("/portal/licenses");
  revalidatePath("/portal/devices");
  revalidatePath("/portal/subscriptions");
  return result;
}

export async function actionRenameDevice(formData: FormData): Promise<{ ok: boolean; error?: string }> {
  const s = await requireSession();
  assertDurableStoreForLicensing();
  await ensureStoreLoaded();
  const id = String(formData.get("deviceId") || "");
  const name = String(formData.get("name") || "");
  if (!id || !name.trim()) return { ok: false, error: "NAME_REQUIRED" };
  const result = renameDevice(id, s.email, name);
  if (!result) return { ok: false, error: "DEVICE_NOT_FOUND" };
  await flushStoreVerified();
  revalidatePath("/portal/devices");
  return { ok: true };
}

export async function actionDeactivateDevice(formData: FormData): Promise<{ ok: boolean; error?: string }> {
  const s = await requireSession();
  assertDurableStoreForLicensing();
  await ensureStoreLoaded();
  const id = String(formData.get("deviceId") || "");
  const ok = deactivateDevice(id, s.email);
  if (!ok) return { ok: false, error: "DEVICE_NOT_FOUND" };
  await flushStoreVerified();
  revalidatePath("/portal/devices");
  revalidatePath("/portal/licenses");
  return { ok: true };
}

export async function actionTransferDevice(formData: FormData): Promise<{ ok: boolean; error?: string }> {
  const s = await requireSession();
  assertDurableStoreForLicensing();
  await ensureStoreLoaded();
  const id = String(formData.get("deviceId") || "");
  const ok = requestDeviceTransfer(id, s.email);
  if (!ok) return { ok: false, error: "TRANSFER_NOT_ALLOWED" };
  await flushStoreVerified();
  revalidatePath("/portal/devices");
  return { ok: true };
}

export async function actionCompleteDeviceTransfer(formData: FormData): Promise<{ ok: boolean; error?: string }> {
  const s = await requireSession();
  assertDurableStoreForLicensing();
  await ensureStoreLoaded();
  const id = String(formData.get("deviceId") || "");
  const ok = completeDeviceTransfer(id, s.email);
  if (!ok) return { ok: false, error: "TRANSFER_COMPLETE_FAILED" };
  await flushStoreVerified();
  revalidatePath("/portal/devices");
  revalidatePath("/portal/licenses");
  return { ok: true };
}

export async function actionCancelSubscription(
  formData: FormData
): Promise<{ ok: boolean; detail: string }> {
  const s = await requireSession();
  assertDurableStoreForLicensing();
  await ensureStoreLoaded();
  await ensureBillingStoreLoaded();
  const licenseId = String(formData.get("licenseId") || "");
  if (!licenseId) return { ok: false, detail: "LICENSE_ID_REQUIRED" };

  const cancelled = cancelLicense(licenseId, s.email);
  if (!cancelled) return { ok: false, detail: "LICENSE_NOT_FOUND" };

  const billing = await cancelBillingSubscriptionForLicense({
    customerEmail: s.email,
    licenseId,
  });
  await flushStoreVerified();
  await flushBillingStore();

  revalidatePath("/portal/subscriptions");
  revalidatePath("/portal/licenses");
  revalidatePath("/portal/billing");
  return {
    ok: true,
    detail: billing.localOk
      ? `License cancelled. ${billing.detail}`
      : "License entitlement cancelled. No linked billing subscription found.",
  };
}

export async function actionRenewLicense(
  formData: FormData
): Promise<{ ok: boolean; detail: string; redirectToBilling?: boolean }> {
  const s = await requireSession();
  const licenseId = String(formData.get("licenseId") || "");
  if (!licenseId) return { ok: false, detail: "LICENSE_ID_REQUIRED" };

  if (!isFreeRenewAllowed()) {
    return {
      ok: false,
      detail: "Renewal requires paid checkout. Open Billing to renew — free local renew is disabled in production.",
      redirectToBilling: true,
    };
  }

  assertDurableStoreForLicensing();
  await ensureStoreLoaded();
  const ok = renewLicense(licenseId, s.email);
  if (!ok) return { ok: false, detail: "LICENSE_NOT_FOUND" };
  await flushStoreVerified();
  revalidatePath("/portal/subscriptions");
  revalidatePath("/portal/licenses");
  return { ok: true, detail: "Dev-only free renew applied. Production renewals go through Billing checkout." };
}

export async function actionAdminCreateLicenseForCustomer(formData: FormData) {
  await requireAdmin();
  assertDurableStoreForLicensing();
  await ensureStoreLoaded();
  const email = String(formData.get("email") || "").toLowerCase();
  const name = String(formData.get("name") || "Customer");
  const type = String(formData.get("type") || "monthly") as LicenseType;
  const result = createLicense({
    customerEmail: email,
    customerName: name,
    type,
    actorEmail: "admin",
    bypassIpCheck: true,
  });
  await flushStoreVerified();
  revalidatePath("/portal/admin");
  return result;
}
