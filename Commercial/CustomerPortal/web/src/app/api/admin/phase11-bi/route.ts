import { withApiGateway, apiSuccess } from "@/server/cloud/gateway";
import {
  ensureSprint2Evidence,
  getPhase11Sprint2Dashboard,
  runFullPhase11Sprint2Suite,
} from "@/server/phase11/bi/dashboard";
import { latestPhase11Run, listPhase11Runs } from "@/server/phase11/store";

/** GET /api/admin/phase11-bi */
export async function GET(req: Request) {
  return withApiGateway(
    req,
    {
      auth: "admin",
      permission: "admin.launch.read",
      rateLimit: { limit: 20, windowSec: 60 },
      auditAction: "admin_action",
    },
    async (ctx) => {
      const view = new URL(req.url).searchParams.get("view") || "dashboard";
      if (view === "run") return apiSuccess({ suite: await runFullPhase11Sprint2Suite() }, ctx.requestId);
      await ensureSprint2Evidence();
      if (view === "executive") return apiSuccess({ run: latestPhase11Run("bi_executive") }, ctx.requestId);
      if (view === "revenue") return apiSuccess({ run: latestPhase11Run("bi_revenue") }, ctx.requestId);
      if (view === "subscriptions")
        return apiSuccess({ run: latestPhase11Run("bi_subscriptions") }, ctx.requestId);
      if (view === "customers") return apiSuccess({ run: latestPhase11Run("bi_customers") }, ctx.requestId);
      if (view === "forecast") return apiSuccess({ run: latestPhase11Run("bi_forecast") }, ctx.requestId);
      if (view === "history")
        return apiSuccess(
          { runs: listPhase11Runs().filter((r) => r.kind.startsWith("bi_")) },
          ctx.requestId
        );
      return apiSuccess({ dashboard: await getPhase11Sprint2Dashboard() }, ctx.requestId);
    }
  );
}
