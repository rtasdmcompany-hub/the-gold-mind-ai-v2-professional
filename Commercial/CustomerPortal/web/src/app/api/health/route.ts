import { NextResponse } from "next/server";
import { runHealthChecks } from "@/server/cloud/monitoring";
import { applyCors, applySecurityHeaders } from "@/server/cloud/security-headers";

/**
 * GET /api/health — public liveness / readiness for commercial cloud.
 * Cloud failures must never stop local Trading Engine operations.
 */
export async function GET(req: Request) {
  const detailed = new URL(req.url).searchParams.get("detailed") === "1";
  const report = await runHealthChecks(detailed);
  const status = report.status === "unhealthy" ? 503 : 200;
  let res: NextResponse = NextResponse.json(
    {
      ok: report.status !== "unhealthy",
      data: report,
      meta: {
        version: "v1",
        requestId: `health_${Date.now().toString(36)}`,
        timestamp: new Date().toISOString(),
      },
    },
    { status }
  );
  res = applyCors(req, res);
  res = applySecurityHeaders(res);
  res.headers.set("X-TGM-API-Version", "v1");
  res.headers.set("Cache-Control", "no-store");
  return res;
}
