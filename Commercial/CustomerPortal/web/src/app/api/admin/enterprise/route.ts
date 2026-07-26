import { withApiGateway, apiSuccess } from "@/server/cloud/gateway";
import {
  ensureSprint4Evidence,
  getPhase11Sprint4Dashboard,
  runFullPhase11Sprint4Suite,
} from "@/server/enterprise/suite";

/** GET /api/admin/enterprise */
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
      if (view === "run") return apiSuccess({ suite: await runFullPhase11Sprint4Suite() }, ctx.requestId);
      await ensureSprint4Evidence();
      return apiSuccess({ dashboard: await getPhase11Sprint4Dashboard() }, ctx.requestId);
    }
  );
}
