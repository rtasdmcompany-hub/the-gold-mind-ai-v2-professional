import { withApiGateway, apiSuccess } from "@/server/cloud/gateway";
import {
  ensureSprint3Evidence,
  getPhase11Sprint3Dashboard,
  runFullPhase11Sprint3Suite,
} from "@/server/partners/suite";
import { getAdminPartnersOverview } from "@/server/partners/portal";

/** GET /api/admin/partners */
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
      if (view === "run") return apiSuccess({ suite: await runFullPhase11Sprint3Suite() }, ctx.requestId);
      await ensureSprint3Evidence();
      if (view === "overview") return apiSuccess({ overview: getAdminPartnersOverview() }, ctx.requestId);
      return apiSuccess({ dashboard: await getPhase11Sprint3Dashboard() }, ctx.requestId);
    }
  );
}
