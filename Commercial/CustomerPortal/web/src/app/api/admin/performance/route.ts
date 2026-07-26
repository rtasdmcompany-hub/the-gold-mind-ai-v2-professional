import { withApiGateway, apiSuccess } from "@/server/cloud/gateway";
import { getExecutivePerformanceDashboard, runFullPerformanceSuite, ensureSprint5Evidence } from "@/server/performance/dashboard";
import { latestPerfRun, listPerfRuns } from "@/server/performance/store";

/** GET /api/admin/performance */
export async function GET(req: Request) {
  return withApiGateway(
    req,
    {
      auth: "admin",
      permission: "admin.observability.read",
      rateLimit: { limit: 30, windowSec: 60 },
      auditAction: "admin_action",
    },
    async (ctx) => {
      const url = new URL(req.url);
      const view = url.searchParams.get("view") || "dashboard";
      if (view === "run") {
        const suite = await runFullPerformanceSuite();
        return apiSuccess({ suite }, ctx.requestId);
      }
      await ensureSprint5Evidence();
      if (view === "benchmark") return apiSuccess({ run: latestPerfRun("benchmark") }, ctx.requestId);
      if (view === "scalability") return apiSuccess({ run: latestPerfRun("scalability") }, ctx.requestId);
      if (view === "load") return apiSuccess({ run: latestPerfRun("load") }, ctx.requestId);
      if (view === "database") return apiSuccess({ run: latestPerfRun("database") }, ctx.requestId);
      if (view === "cloud") return apiSuccess({ run: latestPerfRun("cloud") }, ctx.requestId);
      if (view === "resilience") return apiSuccess({ run: latestPerfRun("resilience") }, ctx.requestId);
      if (view === "history") return apiSuccess({ runs: listPerfRuns() }, ctx.requestId);
      return apiSuccess({ dashboard: await getExecutivePerformanceDashboard() }, ctx.requestId);
    }
  );
}
