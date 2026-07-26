import { withApiGateway, apiSuccess } from "@/server/cloud/gateway";
import {
  getClosureDashboard,
  runFullClosureSuite,
  ensureSprint10Evidence,
} from "@/server/closure/dashboard";
import { latestClosureRun, listClosureRuns } from "@/server/closure/store";

/** GET /api/admin/closure */
export async function GET(req: Request) {
  return withApiGateway(
    req,
    {
      auth: "admin",
      permission: "admin.launch.read",
      rateLimit: { limit: 15, windowSec: 60 },
      auditAction: "admin_action",
    },
    async (ctx) => {
      const view = new URL(req.url).searchParams.get("view") || "dashboard";
      if (view === "run") return apiSuccess({ suite: await runFullClosureSuite() }, ctx.requestId);
      await ensureSprint10Evidence();
      if (view === "decision") return apiSuccess({ run: latestClosureRun("decision") }, ctx.requestId);
      if (view === "scorecard") return apiSuccess({ run: latestClosureRun("scorecard") }, ctx.requestId);
      if (view === "history") return apiSuccess({ runs: listClosureRuns() }, ctx.requestId);
      return apiSuccess({ dashboard: await getClosureDashboard() }, ctx.requestId);
    }
  );
}
