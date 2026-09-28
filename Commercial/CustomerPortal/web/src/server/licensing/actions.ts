"use server";

import { revalidatePath } from "next/cache";
import { requireSession } from "@/server/licensing/session";
import { createClient } from "@supabase/supabase-js";
import { openSecret } from "./crypto";
import { createLicense, activateLicense } from "./license-service";
import type { LicenseType } from "./types";

export async function actionCreateLicense(type: LicenseType) {
  const s = await requireSession();
  const result = await createLicense({
    customerEmail: s.email,
    customerName: s.name || s.email.split("@")[0],
    type,
    clientIp: "127.0.0.1", // Adjust if you have real IP logic
    bypassIpCheck: true,
  });
  return result;
}

export async function actionActivateLicense(formData: FormData) {
  const s = await requireSession();
  const key = String(formData.get("licenseKey") || "");
  const deviceName = String(formData.get("deviceName") || "Portal Workstation");
  const fingerprint = String(formData.get("deviceFingerprint") || "portal-browser-fingerprint");

  const result = await activateLicense({
    plaintextKey: key,
    customerEmail: s.email,
    deviceName,
    deviceFingerprint: fingerprint,
  });
  return result;
}

// ✅ NEW: Action to reveal the license key securely
export async function actionRevealLicenseKey(licenseId: string) {
  const s = await requireSession();
  
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

  if (data.customer_email.toLowerCase() !== s.email.toLowerCase()) {
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