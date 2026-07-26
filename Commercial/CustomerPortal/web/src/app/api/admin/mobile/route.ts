import { withApiGateway, apiSuccess } from "@/server/cloud/gateway";
import {
  ensureSprint6Evidence,
  getPhase11Sprint6Dashboard,
  runFullPhase11Sprint6Suite,
} from "@/server/mobile/suite";

/** GET /api/admin/mobile */
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
      if (view === "run") return apiSuccess({ suite: await runFullPhase11Sprint6Suite() }, ctx.requestId);
      await ensureSprint6Evidence();
      return apiSuccess({ dashboard: await getPhase11Sprint6Dashboard() }, ctx.requestId);
    }
  );
}
