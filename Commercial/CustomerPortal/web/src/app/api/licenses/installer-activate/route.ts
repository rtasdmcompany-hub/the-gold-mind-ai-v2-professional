import { NextResponse } from "next/server";
import { activateLicense } from "@/server/licensing/license-service";
import { ensureStoreLoaded, flushStoreVerified } from "@/server/licensing/store";
import { assertDurableStoreForLicensing } from "@/server/cloud/cache";
import { product } from "@/lib/product";

/**
 * Desktop installer activation — no browser session required.
 * Validates license key + customer email + device fingerprint.
 * Must succeed for {product.installer.name} to finish (installer enforces this).
 * Trial / monthly / yearly / lifetime — same activation standard.
 */
export async function POST(req: Request) {
  try {
    assertDurableStoreForLicensing();
    await ensureStoreLoaded();

    const body = await req.json();
    const licenseKey = String(body.licenseKey || body.plaintextKey || "").trim();
    const customerEmail = String(body.customerEmail || body.email || "").trim();
    const deviceFingerprint = String(body.deviceFingerprint || "").trim();
    const deviceName = String(body.deviceName || "Windows PC").trim();

    if (!licenseKey || !customerEmail || !deviceFingerprint) {
      return NextResponse.json(
        { ok: false, error: "MISSING_FIELDS" },
        { status: 400 }
      );
    }

    const result = activateLicense({
      plaintextKey: licenseKey,
      customerEmail,
      deviceName,
      deviceFingerprint,
    });

    if (!result.ok) {
      const messages: Record<string, string> = {
        MISSING_FIELDS: "License key, customer email, and device fingerprint are required.",
        LICENSE_NOT_FOUND: "License key not found. Generate a new key in Portal → My Licenses.",
        LICENSE_EMAIL_MISMATCH:
          "Email does not match this license. Use the same email shown on My Licenses.",
        LICENSE_REVOKED: "This license has been revoked.",
        LICENSE_EXPIRED: "This license has expired. Renew or create a new trial/subscription.",
        LICENSE_CANCELLED: "This license was cancelled.",
        DEVICE_LIMIT_REACHED:
          "This license is already active on the maximum number of devices. Open Portal → Devices, deactivate a device (or request transfer), then try Setup again.",
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

    return NextResponse.json(
      {
        ok: true,
        license: result.license,
        deviceId: result.deviceId,
        token: result.token,
        activated: true,
        status,
      },
      { status: 200 }
    );
  } catch (e) {
    const msg = e instanceof Error ? e.message : "ERROR";
    const status = msg.startsWith("DURABLE_STORE") ? 503 : 500;
    return NextResponse.json({ ok: false, error: msg }, { status });
  }
}
