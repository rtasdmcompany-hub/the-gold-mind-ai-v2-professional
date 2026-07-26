import { withApiGateway, apiSuccess } from "@/server/cloud/gateway";
import {
  ensurePhase12Evidence,
  getPhase12Dashboard,
  runFullPhase12LtsSuite,
} from "@/server/phase12/suite";

/** GET /api/admin/phase12 */
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
      if (view === "run") return apiSuccess({ suite: await runFullPhase12LtsSuite() }, ctx.requestId);
      await ensurePhase12Evidence();
      return apiSuccess({ dashboard: await getPhase12Dashboard() }, ctx.requestId);
    }
  );
}
