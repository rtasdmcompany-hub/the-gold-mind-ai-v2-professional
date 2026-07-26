import { NextResponse } from "next/server";
import { requireSession } from "@/server/licensing/session";
import { activateLicense, createLicense, validateLicenseOnline } from "@/server/licensing/license-service";
import type { LicenseType } from "@/server/licensing/types";

export async function POST(req: Request) {
  try {
    const s = await requireSession();
    const body = await req.json();
    const action = body.action as string;

    if (action === "create") {
      const type = (body.type || "monthly") as LicenseType;
      const result = createLicense({
        customerEmail: s.email,
        customerName: s.name,
        type,
        actorEmail: s.email,
      });
      return NextResponse.json(result);
    }

    if (action === "activate") {
      const result = activateLicense({
        plaintextKey: String(body.licenseKey || ""),
        customerEmail: s.email,
        deviceName: String(body.deviceName || "API Device"),
        deviceFingerprint: String(body.deviceFingerprint || `api-${s.email}`),
      });
      return NextResponse.json(result, { status: result.ok ? 200 : 400 });
    }

    if (action === "validate") {
      const result = validateLicenseOnline({
        licenseId: String(body.licenseId || ""),
        deviceId: String(body.deviceId || ""),
        customerEmail: s.email,
        deviceFingerprint: String(body.deviceFingerprint || ""),
      });
      return NextResponse.json(result, { status: result.ok ? 200 : 400 });
    }

    return NextResponse.json({ error: "UNKNOWN_ACTION" }, { status: 400 });
  } catch (e) {
    const msg = e instanceof Error ? e.message : "ERROR";
    return NextResponse.json({ error: msg }, { status: msg === "UNAUTHORIZED" ? 401 : 500 });
  }
}
