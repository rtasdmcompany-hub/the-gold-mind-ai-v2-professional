import { withApiGateway, apiSuccess } from "@/server/cloud/gateway";
import {
  ensureSprint10Evidence,
  getPhase11Sprint10Dashboard,
  runFullPhase11Sprint10Suite,
} from "@/server/phase11-closure/suite";

/** GET /api/admin/phase11-closure */
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
      if (view === "run") return apiSuccess({ suite: await runFullPhase11Sprint10Suite() }, ctx.requestId);
      await ensureSprint10Evidence();
      return apiSuccess({ dashboard: await getPhase11Sprint10Dashboard() }, ctx.requestId);
    }
  );
}
