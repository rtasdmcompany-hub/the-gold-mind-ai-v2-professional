import { NextResponse } from "next/server";
import { activateLicense } from "@/server/licensing/license-service";
import { ensureStoreLoaded, flushStoreVerified } from "@/server/licensing/store";
import { assertDurableStoreForLicensing } from "@/server/cloud/cache";

/**
 * Desktop installer activation — no browser session required.
 * Validates license key + customer email + device fingerprint + MT5 Account + IP.
 */
export async function POST(req: Request) {
  try {
    assertDurableStoreForLicensing();
    await ensureStoreLoaded();

    const body = await req.json();
    const licenseKey = String(body.licenseKey || body.plaintextKey || "").trim();
    const customerEmail = String(body.customerEmail || body.email || "").trim().toLowerCase();
    const deviceFingerprint = String(body.deviceFingerprint || "").trim();
    const deviceName = String(body.deviceName || "Windows PC").trim();
    
    // ✅ NAYA: MT5 Account Number aur IP Address capture karna
    const mt5AccountNumber = String(body.mt5AccountNumber || "").trim();
    const ipAddress = String(
      req.headers.get("x-forwarded-for")?.split(",")[0]?.trim() || 
      req.headers.get("x-real-ip") || 
      "unknown"
    ).trim();

    if (!licenseKey || !customerEmail || !deviceFingerprint) {
      return NextResponse.json(
        { ok: false, error: "MISSING_FIELDS", message: "License key, customer email, and device fingerprint are required." },
        { status: 400 }
      );
    }

    const result = await activateLicense({
      plaintextKey: licenseKey,
      customerEmail,
      deviceName,
      deviceFingerprint,
      mt5AccountNumber, // ✅ NAYA
      ipAddress,        // ✅ NAYA
      replaceSingleSeat: true,
    });

    if (!result.ok) {
      const messages: Record<string, string> = {
        MISSING_FIELDS: "License key, customer email, and device fingerprint are required.",
        LICENSE_NOT_FOUND: "License key not found. Generate a new key in Portal → My Licenses.",
        LICENSE_EMAIL_MISMATCH: "Email does not match this license. Use the same email shown on My Licenses.",
        LICENSE_REVOKED: "This license has been revoked.",
        LICENSE_EXPIRED: "This license has expired. Renew or create a new trial/subscription.",
        LICENSE_CANCELLED: "This license was cancelled.",
        DEVICE_LIMIT_REACHED: "This license is already active on the maximum number of devices.",
        TRIAL_ALREADY_USED: "Free trial already used with this Email or IP address.",
      };
      const message = messages[result.error] || result.error;
      
      return NextResponse.json({ ...result, message }, { status: 400 });
    }

    await flushStoreVerified();

    const status = result.license.status;
    if (status !== "active" && status !== "grace") {
      return NextResponse.json(
        { ok: false, error: "LICENSE_NOT_ACTIVE_AFTER_ACTIVATE", status },
        { status: 500 }
      );
    }

    // ✅ SUCCESS RESPONSE: mt5AccountChanged flag add kiya gaya hai
    return NextResponse.json(
      {
        ok: true,
        license: result.license,
        deviceId: result.deviceId,
        token: result.token,
        activated: true,
        status,
        mt5AccountChanged: result.mt5AccountChanged || false, // ✅ NAYA: Installer ko batane ke liye ke account change hua hai
      },
      { status: 200 }
    );
  } catch (e) {
    const msg = e instanceof Error ? e.message : "ERROR";
    const status = msg.startsWith("DURABLE_STORE") ? 503 : 500;
    return NextResponse.json({ ok: false, error: msg }, { status });
  }
}