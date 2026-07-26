import { withApiGateway, apiSuccess } from "@/server/cloud/gateway";
import {
  ensureSprint8Evidence,
  getPhase11Sprint8Dashboard,
  runFullPhase11Sprint8Suite,
} from "@/server/api-platform/suite";
import { usageAnalytics } from "@/server/api-platform/usage";
import { fullCatalog } from "@/server/api-platform/catalog";

/** GET /api/admin/api-platform */
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
      if (view === "run") return apiSuccess({ suite: await runFullPhase11Sprint8Suite() }, ctx.requestId);
      if (view === "usage") return apiSuccess({ usage: usageAnalytics() }, ctx.requestId);
      if (view === "catalog") return apiSuccess({ catalog: fullCatalog() }, ctx.requestId);
      await ensureSprint8Evidence();
      return apiSuccess({ dashboard: await getPhase11Sprint8Dashboard() }, ctx.requestId);
    }
  );
}
