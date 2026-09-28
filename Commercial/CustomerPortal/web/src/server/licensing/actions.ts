"use server";

import { revalidatePath } from "next/cache";
import { auth } from "@/auth";
import { createClient } from "@supabase/supabase-js";
import { openSecret } from "./crypto";
import { createLicense, activateLicense, renewLicense, cancelLicense } from "./license-service";
import type { LicenseType } from "./types";

export async function actionCreateLicense(type: LicenseType) {
  const session = await auth();
  if (!session?.user?.email) throw new Error("Unauthorized");
  
  const result = await createLicense({
    customerEmail: session.user.email,
    customerName: session.user.name || session.user.email.split("@")[0],
    type,
    clientIp: "127.0.0.1", 
    bypassIpCheck: true,
  });
  return result;
}

export async function actionActivateLicense(formData: FormData) {
  const session = await auth();
  if (!session?.user?.email) throw new Error("Unauthorized");

  const key = String(formData.get("licenseKey") || "");
  const deviceName = String(formData.get("deviceName") || "Portal Workstation");
  const fingerprint = String(formData.get("deviceFingerprint") || "portal-browser-fingerprint");
  const mt5AccountNumber = String(formData.get("mt5AccountNumber") || "");

  const result = await activateLicense({
    plaintextKey: key,
    customerEmail: session.user.email,
    deviceName,
    deviceFingerprint: fingerprint,
    mt5AccountNumber: mt5AccountNumber || undefined,
  });
  
  if (result.ok) {
    revalidatePath("/portal/licenses");
    revalidatePath("/portal/billing");
  }
  return result;
}

export async function actionRevealLicenseKey(licenseId: string) {
  const session = await auth();
  if (!session?.user?.email) return { ok: false, error: "UNAUTHORIZED" };
  
  const supabaseAdmin = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!,
    { auth: { persistSession: false } }
  );
  
  const { data, error } = await supabaseAdmin
    .from("licenses")
    .select("key_envelope, customer_email")
    .eq("id", licenseId)
    .single();

  if (error || !data) {
    return { ok: false, error: "LICENSE_NOT_FOUND" };
  }

  if (data.customer_email.toLowerCase() !== session.user.email.toLowerCase()) {
    return { ok: false, error: "UNAUTHORIZED" };
  }

  if (!data.key_envelope) {
    return { ok: false, error: "KEY_NOT_AVAILABLE" };
  }

  const plaintextKey = openSecret(data.key_envelope);
  if (!plaintextKey) {
    return { ok: false, error: "DECRYPTION_FAILED" };
  }

  return { ok: true, key: plaintextKey };
}

// --- Device Actions ---

export async function actionRenameDevice(formData: FormData) {
  const session = await auth();
  if (!session?.user?.email) return { ok: false, error: "UNAUTHORIZED", detail: "Unauthorized" };

  const deviceId = String(formData.get("deviceId") || "");
  const newName = String(formData.get("newName") || "");

  if (!deviceId || !newName) return { ok: false, error: "MISSING_FIELDS", detail: "Missing fields" };

  const supabaseAdmin = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!,
    { auth: { persistSession: false } }
  );

  const { data: device } = await supabaseAdmin.from("devices").select("license_id").eq("id", deviceId).single();
  if (!device) return { ok: false, error: "DEVICE_NOT_FOUND", detail: "Device not found" };

  const { data: license } = await supabaseAdmin.from("licenses").select("customer_email").eq("id", device.license_id).single();
  if (license?.customer_email.toLowerCase() !== session.user.email.toLowerCase()) {
    return { ok: false, error: "UNAUTHORIZED", detail: "Unauthorized" };
  }

  const { error } = await supabaseAdmin.from("devices").update({ name: newName }).eq("id", deviceId);
  if (error) return { ok: false, error: error.message, detail: error.message };
  
  revalidatePath("/portal/licenses");
  return { ok: true, detail: "Device renamed successfully" };
}

export async function actionDeactivateDevice(formData: FormData) {
  const session = await auth();
  if (!session?.user?.email) return { ok: false, error: "UNAUTHORIZED", detail: "Unauthorized" };

  const deviceId = String(formData.get("deviceId") || "");
  if (!deviceId) return { ok: false, error: "MISSING_FIELDS", detail: "Missing fields" };

  const supabaseAdmin = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!,
    { auth: { persistSession: false } }
  );

  const { data: device } = await supabaseAdmin.from("devices").select("license_id").eq("id", deviceId).single();
  if (!device) return { ok: false, error: "DEVICE_NOT_FOUND", detail: "Device not found" };

  const { data: license } = await supabaseAdmin.from("licenses").select("customer_email").eq("id", device.license_id).single();
  if (license?.customer_email.toLowerCase() !== session.user.email.toLowerCase()) {
    return { ok: false, error: "UNAUTHORIZED", detail: "Unauthorized" };
  }

  const { error } = await supabaseAdmin.from("devices").update({ status: "inactive" }).eq("id", deviceId);
  if (error) return { ok: false, error: error.message, detail: error.message };
  
  revalidatePath("/portal/licenses");
  return { ok: true, detail: "Device deactivated successfully" };
}

export async function actionTransferDevice(formData: FormData) {
  const session = await auth();
  if (!session?.user?.email) return { ok: false, error: "UNAUTHORIZED", detail: "Unauthorized" };

  const deviceId = String(formData.get("deviceId") || "");
  const targetLicenseId = String(formData.get("targetLicenseId") || "");

  if (!deviceId || !targetLicenseId) return { ok: false, error: "MISSING_FIELDS", detail: "Missing fields" };

  const supabaseAdmin = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!,
    { auth: { persistSession: false } }
  );

  const { data: device } = await supabaseAdmin.from("devices").select("license_id").eq("id", deviceId).single();
  if (!device) return { ok: false, error: "DEVICE_NOT_FOUND", detail: "Device not found" };

  const { data: sourceLicense } = await supabaseAdmin.from("licenses").select("customer_email").eq("id", device.license_id).single();
  if (sourceLicense?.customer_email.toLowerCase() !== session.user.email.toLowerCase()) {
    return { ok: false, error: "UNAUTHORIZED", detail: "Unauthorized" };
  }

  const { data: targetLicense } = await supabaseAdmin.from("licenses").select("customer_email").eq("id", targetLicenseId).single();
  if (targetLicense?.customer_email.toLowerCase() !== session.user.email.toLowerCase()) {
    return { ok: false, error: "TARGET_LICENSE_UNAUTHORIZED", detail: "Unauthorized for target license" };
  }

  const { error } = await supabaseAdmin.from("devices").update({ license_id: targetLicenseId, status: "pending_transfer" }).eq("id", deviceId);
  if (error) return { ok: false, error: error.message, detail: error.message };
  
  revalidatePath("/portal/licenses");
  return { ok: true, detail: "Device transfer initiated successfully" };
}

export async function actionCompleteDeviceTransfer(formData: FormData) {
  const session = await auth();
  if (!session?.user?.email) return { ok: false, error: "UNAUTHORIZED", detail: "Unauthorized" };

  const deviceId = String(formData.get("deviceId") || "");
  if (!deviceId) return { ok: false, error: "MISSING_FIELDS", detail: "Missing fields" };

  const supabaseAdmin = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!,
    { auth: { persistSession: false } }
  );

  const { data: device } = await supabaseAdmin.from("devices").select("license_id, status").eq("id", deviceId).single();
  if (!device || device.status !== "pending_transfer") {
    return { ok: false, error: "INVALID_TRANSFER_STATE", detail: "Invalid transfer state" };
  }

  const { data: license } = await supabaseAdmin.from("licenses").select("customer_email").eq("id", device.license_id).single();
  if (license?.customer_email.toLowerCase() !== session.user.email.toLowerCase()) {
    return { ok: false, error: "UNAUTHORIZED", detail: "Unauthorized" };
  }

  const { error } = await supabaseAdmin.from("devices").update({ status: "active" }).eq("id", deviceId);
  if (error) return { ok: false, error: error.message, detail: error.message };
  
  revalidatePath("/portal/licenses");
  return { ok: true, detail: "Device transfer completed successfully" };
}

// --- Subscription Actions (Updated to return 'detail' property) ---

export async function actionRenewLicense(formData: FormData) {
  const session = await auth();
  if (!session?.user?.email) return { ok: false, error: "UNAUTHORIZED", detail: "Unauthorized" };

  const licenseId = String(formData.get("licenseId") || "");
  if (!licenseId) return { ok: false, error: "MISSING_FIELDS", detail: "Missing license ID" };

  const supabaseAdmin = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!,
    { auth: { persistSession: false } }
  );

  const { data: license } = await supabaseAdmin.from("licenses").select("customer_email").eq("id", licenseId).single();
  if (license?.customer_email.toLowerCase() !== session.user.email.toLowerCase()) {
    return { ok: false, error: "UNAUTHORIZED", detail: "Unauthorized" };
  }

  const success = await renewLicense(licenseId, session.user.email);
  if (!success) return { ok: false, error: "RENEWAL_FAILED", detail: "Renewal failed" };
  
  revalidatePath("/portal/licenses");
  revalidatePath("/portal/billing");
  return { ok: true, detail: "License renewed successfully" };
}

export async function actionCancelSubscription(formData: FormData) {
  const session = await auth();
  if (!session?.user?.email) return { ok: false, error: "UNAUTHORIZED", detail: "Unauthorized" };

  const licenseId = String(formData.get("licenseId") || "");
  if (!licenseId) return { ok: false, error: "MISSING_FIELDS", detail: "Missing license ID" };

  const supabaseAdmin = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!,
    { auth: { persistSession: false } }
  );

  const { data: license } = await supabaseAdmin.from("licenses").select("customer_email").eq("id", licenseId).single();
  if (license?.customer_email.toLowerCase() !== session.user.email.toLowerCase()) {
    return { ok: false, error: "UNAUTHORIZED", detail: "Unauthorized" };
  }

  const success = await cancelLicense(licenseId, session.user.email);
  if (!success) return { ok: false, error: "CANCELLATION_FAILED", detail: "Cancellation failed" };
  
  revalidatePath("/portal/licenses");
  revalidatePath("/portal/billing");
  return { ok: true, detail: "Subscription cancelled successfully" };
}