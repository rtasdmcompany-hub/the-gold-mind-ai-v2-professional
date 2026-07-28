import { NextResponse } from "next/server";
import { activateLicense } from "@/server/licensing/license-service";
import { ensureStoreLoaded, flushStoreVerified } from "@/server/licensing/store";
import { assertDurableStoreForLicensing } from "@/server/cloud/cache";

/**
 * Desktop installer activation — no browser session required.
 * Validates license key + customer email + device fingerprint.
 * Must succeed for Setup.exe to finish (installer enforces this).
 * Trial / monthly / yearly / lifetime — same activation standard.
 * On success, license-service sends activation email via Resend (masked key + package).
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
      return NextResponse.json(result, { status: 400 });
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
