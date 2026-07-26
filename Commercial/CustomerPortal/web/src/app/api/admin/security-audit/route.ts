import { withApiGateway, apiSuccess } from "@/server/cloud/gateway";
import {
  getExecutiveSecurityDashboard,
  runFullSecuritySuite,
  ensureSprint6Evidence,
} from "@/server/security/dashboard";
import { latestSecurityRun, listSecurityRuns } from "@/server/security/store";

/** GET /api/admin/security-audit */
export async function GET(req: Request) {
  return withApiGateway(
    req,
    {
      auth: "admin",
      permission: "admin.security.manage",
      rateLimit: { limit: 20, windowSec: 60 },
      auditAction: "admin_action",
    },
    async (ctx) => {
      const url = new URL(req.url);
      const view = url.searchParams.get("view") || "dashboard";
      if (view === "run") {
        const suite = await runFullSecuritySuite();
        return apiSuccess({ suite }, ctx.requestId);
      }
      await ensureSprint6Evidence();
      if (view === "assessment") return apiSuccess({ run: latestSecurityRun("assessment") }, ctx.requestId);
      if (view === "pentest") return apiSuccess({ run: latestSecurityRun("pentest") }, ctx.requestId);
      if (view === "owasp") return apiSuccess({ run: latestSecurityRun("owasp") }, ctx.requestId);
      if (view === "secrets") return apiSuccess({ run: latestSecurityRun("secrets") }, ctx.requestId);
      if (view === "data_protection") return apiSuccess({ run: latestSecurityRun("data_protection") }, ctx.requestId);
      if (view === "disaster_recovery")
        return apiSuccess({ run: latestSecurityRun("disaster_recovery") }, ctx.requestId);
      if (view === "compliance") return apiSuccess({ run: latestSecurityRun("compliance") }, ctx.requestId);
      if (view === "history") return apiSuccess({ runs: listSecurityRuns() }, ctx.requestId);
      return apiSuccess({ dashboard: await getExecutiveSecurityDashboard() }, ctx.requestId);
    }
  );
}
