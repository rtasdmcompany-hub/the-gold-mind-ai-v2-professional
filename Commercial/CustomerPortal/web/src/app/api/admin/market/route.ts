import { withApiGateway, apiSuccess } from "@/server/cloud/gateway";
import { getExecutiveMarketDashboard, runFullMarketSuite, ensureSprint7Evidence } from "@/server/market/dashboard";
import { latestMarketRun, listMarketRuns } from "@/server/market/store";

/** GET /api/admin/market */
export async function GET(req: Request) {
  return withApiGateway(
    req,
    {
      auth: "admin",
      permission: "admin.releases.read",
      rateLimit: { limit: 20, windowSec: 60 },
      auditAction: "admin_action",
    },
    async (ctx) => {
      const view = new URL(req.url).searchParams.get("view") || "dashboard";
      if (view === "run") {
        return apiSuccess({ suite: await runFullMarketSuite() }, ctx.requestId);
      }
      await ensureSprint7Evidence();
      if (view === "edition") return apiSuccess({ run: latestMarketRun("edition") }, ctx.requestId);
      if (view === "compliance") return apiSuccess({ run: latestMarketRun("compliance") }, ctx.requestId);
      if (view === "assets") return apiSuccess({ run: latestMarketRun("assets") }, ctx.requestId);
      if (view === "documentation") return apiSuccess({ run: latestMarketRun("documentation") }, ctx.requestId);
      if (view === "metadata") return apiSuccess({ run: latestMarketRun("metadata") }, ctx.requestId);
      if (view === "validation") return apiSuccess({ run: latestMarketRun("validation") }, ctx.requestId);
      if (view === "submission") return apiSuccess({ run: latestMarketRun("submission") }, ctx.requestId);
      if (view === "history") return apiSuccess({ runs: listMarketRuns() }, ctx.requestId);
      return apiSuccess({ dashboard: await getExecutiveMarketDashboard() }, ctx.requestId);
    }
  );
}
