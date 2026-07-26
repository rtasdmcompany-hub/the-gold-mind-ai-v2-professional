import { withApiGateway, apiSuccess } from "@/server/cloud/gateway";
import {
  getExecutiveGoNoGoDashboard,
  runFullExecutiveSuite,
  ensureSprint9Evidence,
} from "@/server/executive/dashboard";
import { latestExecutiveRun, listExecutiveRuns } from "@/server/executive/store";

/** GET /api/admin/executive */
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
      if (view === "run") return apiSuccess({ suite: await runFullExecutiveSuite() }, ctx.requestId);
      await ensureSprint9Evidence();
      if (view === "decision") return apiSuccess({ run: latestExecutiveRun("decision") }, ctx.requestId);
      if (view === "scorecard") return apiSuccess({ run: latestExecutiveRun("scorecard") }, ctx.requestId);
      if (view === "risks") return apiSuccess({ run: latestExecutiveRun("risks") }, ctx.requestId);
      if (view === "history") return apiSuccess({ runs: listExecutiveRuns() }, ctx.requestId);
      return apiSuccess({ dashboard: await getExecutiveGoNoGoDashboard() }, ctx.requestId);
    }
  );
}
