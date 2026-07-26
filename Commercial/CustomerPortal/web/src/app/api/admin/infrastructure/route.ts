import { withApiGateway, apiSuccess } from "@/server/cloud/gateway";
import {
  ensureSprint9Evidence,
  getPhase11Sprint9Dashboard,
  runFullPhase11Sprint9Suite,
} from "@/server/infrastructure/suite";
import { buildEnterpriseOpsCenter } from "@/server/infrastructure/ops-center";

/** GET /api/admin/infrastructure */
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
      if (view === "run") return apiSuccess({ suite: await runFullPhase11Sprint9Suite() }, ctx.requestId);
      if (view === "ops") return apiSuccess({ ops: buildEnterpriseOpsCenter() }, ctx.requestId);
      await ensureSprint9Evidence();
      return apiSuccess({ dashboard: await getPhase11Sprint9Dashboard() }, ctx.requestId);
    }
  );
}
