import { NextResponse } from "next/server";
import { requireSession } from "@/server/licensing/session";
import { listPublished, recordUpdateResult } from "@/server/releases/release-service";
import type { ReleaseChannel } from "@/server/releases/types";

export async function GET() {
  try {
    await requireSession();
    return NextResponse.json({
      packages: listPublished(),
      channels: ["stable", "rc", "development"],
    });
  } catch (e) {
    const msg = e instanceof Error ? e.message : "ERROR";
    return NextResponse.json({ error: msg }, { status: msg === "UNAUTHORIZED" ? 401 : 500 });
  }
}

export async function POST(req: Request) {
  try {
    const s = await requireSession();
    const body = await req.json();
    if (body.action === "report") {
      recordUpdateResult({
        email: s.email,
        fromVersion: String(body.fromVersion || ""),
        toVersion: String(body.toVersion || ""),
        channel: (body.channel || "stable") as ReleaseChannel,
        result: body.result,
        detail: String(body.detail || ""),
        packageId: body.packageId,
      });
      return NextResponse.json({ ok: true });
    }
    return NextResponse.json({ error: "UNKNOWN_ACTION" }, { status: 400 });
  } catch (e) {
    const msg = e instanceof Error ? e.message : "ERROR";
    return NextResponse.json({ error: msg }, { status: msg === "UNAUTHORIZED" ? 401 : 500 });
  }
}
