import { NextResponse } from "next/server";
import { recordUpdateResult } from "@/server/releases/release-service";
import type { ReleaseChannel } from "@/server/releases/types";

/**
 * Updater telemetry endpoint (Website Edition).
 * Auth: Bearer UPDATE_REPORT_SECRET or x-tgm-update-secret (dev default allowed non-prod).
 * Public to desktop updater — not a portal session route.
 */
export async function POST(req: Request) {
  const secret = process.env.UPDATE_REPORT_SECRET || "dev-update-report-secret";
  const hdr =
    req.headers.get("x-tgm-update-secret") ||
    req.headers.get("authorization")?.replace(/^Bearer\s+/i, "") ||
    "";
  if (process.env.NODE_ENV === "production" && !process.env.UPDATE_REPORT_SECRET) {
    return NextResponse.json({ error: "REPORT_SECRET_REQUIRED" }, { status: 503 });
  }
  if (hdr !== secret) {
    return NextResponse.json({ error: "UNAUTHORIZED" }, { status: 401 });
  }

  try {
    const body = await req.json();
    const result = String(body.result || "") as "success" | "fail" | "rollback";
    if (!["success", "fail", "rollback"].includes(result)) {
      return NextResponse.json({ error: "INVALID_RESULT" }, { status: 400 });
    }
    recordUpdateResult({
      email: body.email ? String(body.email) : undefined,
      fromVersion: String(body.fromVersion || ""),
      toVersion: String(body.toVersion || ""),
      channel: (body.channel || "stable") as ReleaseChannel,
      result,
      detail: String(body.detail || ""),
      packageId: body.packageId ? String(body.packageId) : undefined,
    });
    return NextResponse.json({ ok: true });
  } catch (e) {
    const msg = e instanceof Error ? e.message : "ERROR";
    return NextResponse.json({ error: msg }, { status: 500 });
  }
}
