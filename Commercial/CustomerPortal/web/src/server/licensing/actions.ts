"use server";

import { revalidatePath } from "next/cache";
import { activateLicense, createLicense, renewLicense, cancelLicense } from "@/server/licensing/license-service";
import {
  deactivateDevice,
  renameDevice,
  requestDeviceTransfer,
} from "@/server/licensing/device-service";
import { requireAdmin, requireSession } from "@/server/licensing/session";
import { ensureStoreLoaded, flushStoreVerified } from "@/server/licensing/store";
import { assertDurableStoreForLicensing } from "@/server/cloud/cache";
import type { LicenseType } from "@/server/licensing/types";

export async function actionCreateLicense(type: LicenseType) {
  const s = await requireSession();
  assertDurableStoreForLicensing();
  await ensureStoreLoaded();
  const result = createLicense({
    customerEmail: s.email,
    customerName: s.name,
    type,
    actorEmail: s.email,
  });
  await flushStoreVerified();
  revalidatePath("/portal");
  revalidatePath("/portal/licenses");
  revalidatePath("/portal/subscriptions");
  // plaintext returned once to the caller (server action result) — UI should show then discard
  // License delivery email is sent by createLicense (Resend) unless skipEmail.
  return result;
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

export async function actionRenameDevice(formData: FormData): Promise<void> {
  const s = await requireSession();
  const id = String(formData.get("deviceId") || "");
  const name = String(formData.get("name") || "");
  renameDevice(id, s.email, name);
  revalidatePath("/portal/devices");
}

export async function actionDeactivateDevice(formData: FormData): Promise<void> {
  const s = await requireSession();
  const id = String(formData.get("deviceId") || "");
  deactivateDevice(id, s.email);
  revalidatePath("/portal/devices");
  revalidatePath("/portal/licenses");
}

export async function actionTransferDevice(formData: FormData): Promise<void> {
  const s = await requireSession();
  const id = String(formData.get("deviceId") || "");
  requestDeviceTransfer(id, s.email);
  revalidatePath("/portal/devices");
}

export async function actionCancelSubscription(formData: FormData): Promise<void> {
  const s = await requireSession();
  const licenseId = String(formData.get("licenseId") || "");
  cancelLicense(licenseId, s.email);
  revalidatePath("/portal/subscriptions");
  revalidatePath("/portal/licenses");
}

export async function actionRenewLicense(formData: FormData): Promise<void> {
  const s = await requireSession();
  const licenseId = String(formData.get("licenseId") || "");
  renewLicense(licenseId, s.email);
  revalidatePath("/portal/subscriptions");
  revalidatePath("/portal/licenses");
}

export async function actionAdminCreateLicenseForCustomer(formData: FormData) {
  await requireAdmin();
  const email = String(formData.get("email") || "").toLowerCase();
  const name = String(formData.get("name") || "Customer");
  const type = String(formData.get("type") || "monthly") as LicenseType;
  const result = createLicense({ customerEmail: email, customerName: name, type, actorEmail: "admin" });
  revalidatePath("/portal/admin");
  return result;
}
