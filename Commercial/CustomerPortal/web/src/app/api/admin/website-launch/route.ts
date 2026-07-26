import { withApiGateway, apiSuccess } from "@/server/cloud/gateway";
import {
  getExecutiveWebsiteLaunchDashboard,
  runFullWebsiteLaunchSuite,
  ensureSprint8Evidence,
} from "@/server/website-launch/dashboard";
import { latestWebsiteLaunchRun, listWebsiteLaunchRuns } from "@/server/website-launch/store";

/** GET /api/admin/website-launch */
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
      if (view === "run") return apiSuccess({ suite: await runFullWebsiteLaunchSuite() }, ctx.requestId);
      await ensureSprint8Evidence();
      if (view === "website") return apiSuccess({ run: latestWebsiteLaunchRun("website") }, ctx.requestId);
      if (view === "journey") return apiSuccess({ run: latestWebsiteLaunchRun("journey") }, ctx.requestId);
      if (view === "workflows") return apiSuccess({ run: latestWebsiteLaunchRun("workflows") }, ctx.requestId);
      if (view === "deployment") return apiSuccess({ run: latestWebsiteLaunchRun("deployment") }, ctx.requestId);
      if (view === "operations") return apiSuccess({ run: latestWebsiteLaunchRun("operations") }, ctx.requestId);
      if (view === "certification")
        return apiSuccess({ run: latestWebsiteLaunchRun("certification") }, ctx.requestId);
      if (view === "history") return apiSuccess({ runs: listWebsiteLaunchRuns() }, ctx.requestId);
      return apiSuccess({ dashboard: await getExecutiveWebsiteLaunchDashboard() }, ctx.requestId);
    }
  );
}
