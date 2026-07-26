import { NextResponse } from "next/server";
import { requireAdmin } from "@/server/licensing/session";
import { getAdminReleaseDashboard } from "@/server/releases/release-service";

export async function GET() {
  try {
    await requireAdmin();
    return NextResponse.json(getAdminReleaseDashboard());
  } catch (e) {
    const msg = e instanceof Error ? e.message : "ERROR";
    const status = msg === "UNAUTHORIZED" ? 401 : msg === "FORBIDDEN" ? 403 : 500;
    return NextResponse.json({ error: msg }, { status });
  }
}
