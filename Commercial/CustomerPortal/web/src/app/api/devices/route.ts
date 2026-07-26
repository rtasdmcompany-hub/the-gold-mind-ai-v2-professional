import { NextResponse } from "next/server";
import { requireSession } from "@/server/licensing/session";
import {
  deactivateDevice,
  listDevicesForCustomer,
  renameDevice,
  requestDeviceTransfer,
} from "@/server/licensing/device-service";

export async function GET() {
  try {
    const s = await requireSession();
    return NextResponse.json({ devices: listDevicesForCustomer(s.email) });
  } catch (e) {
    const msg = e instanceof Error ? e.message : "ERROR";
    return NextResponse.json({ error: msg }, { status: msg === "UNAUTHORIZED" ? 401 : 500 });
  }
}

export async function POST(req: Request) {
  try {
    const s = await requireSession();
    const body = await req.json();
    const action = body.action as string;
    const deviceId = String(body.deviceId || "");

    if (action === "rename") {
      const dto = renameDevice(deviceId, s.email, String(body.name || ""));
      return NextResponse.json({ device: dto }, { status: dto ? 200 : 404 });
    }
    if (action === "deactivate") {
      return NextResponse.json({ ok: deactivateDevice(deviceId, s.email) });
    }
    if (action === "transfer") {
      return NextResponse.json({ ok: requestDeviceTransfer(deviceId, s.email) });
    }
    return NextResponse.json({ error: "UNKNOWN_ACTION" }, { status: 400 });
  } catch (e) {
    const msg = e instanceof Error ? e.message : "ERROR";
    return NextResponse.json({ error: msg }, { status: msg === "UNAUTHORIZED" ? 401 : 500 });
  }
}
