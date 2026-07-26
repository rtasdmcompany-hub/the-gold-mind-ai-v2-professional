import { withApiGateway, apiSuccess } from "@/server/cloud/gateway";
import {
  getPhase11Sprint1Dashboard,
  runFullPhase11Sprint1Suite,
  ensureSprint1Evidence,
} from "@/server/phase11/dashboard";
import { latestPhase11Run, listPhase11Runs } from "@/server/phase11/store";

/** GET /api/admin/phase11 */
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
      if (view === "run") return apiSuccess({ suite: await runFullPhase11Sprint1Suite() }, ctx.requestId);
      await ensureSprint1Evidence();
      if (view === "ops") return apiSuccess({ run: latestPhase11Run("ops_center") }, ctx.requestId);
      if (view === "kpis") return apiSuccess({ run: latestPhase11Run("kpis") }, ctx.requestId);
      if (view === "commercial") return apiSuccess({ run: latestPhase11Run("commercial") }, ctx.requestId);
      if (view === "health") return apiSuccess({ run: latestPhase11Run("health") }, ctx.requestId);
      if (view === "success") return apiSuccess({ run: latestPhase11Run("success") }, ctx.requestId);
      if (view === "reports") return apiSuccess({ run: latestPhase11Run("reports") }, ctx.requestId);
      if (view === "history") return apiSuccess({ runs: listPhase11Runs() }, ctx.requestId);
      return apiSuccess({ dashboard: await getPhase11Sprint1Dashboard() }, ctx.requestId);
    }
  );
}
