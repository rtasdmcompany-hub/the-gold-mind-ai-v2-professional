import { withApiGateway, apiSuccess } from "@/server/cloud/gateway";
import {
  ensureSprint7Evidence,
  getPhase11Sprint7Dashboard,
  runFullPhase11Sprint7Suite,
} from "@/server/ai-assistant/suite";
import { buildAiAdminDashboard } from "@/server/ai-assistant/analytics";

/** GET /api/admin/ai */
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
      if (view === "run") return apiSuccess({ suite: await runFullPhase11Sprint7Suite() }, ctx.requestId);
      if (view === "analytics") return apiSuccess({ analytics: buildAiAdminDashboard() }, ctx.requestId);
      await ensureSprint7Evidence();
      return apiSuccess({ dashboard: await getPhase11Sprint7Dashboard() }, ctx.requestId);
    }
  );
}
