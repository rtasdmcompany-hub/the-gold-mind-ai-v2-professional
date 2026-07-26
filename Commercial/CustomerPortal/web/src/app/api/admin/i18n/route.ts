import { withApiGateway, apiSuccess } from "@/server/cloud/gateway";
import {
  ensureSprint5Evidence,
  getPhase11Sprint5Dashboard,
  runFullPhase11Sprint5Suite,
} from "@/server/i18n/suite";
import { listInstalledLocales, masterKeys } from "@/server/i18n/packs";
import { missingTranslationReport, getTranslationStatusDashboard } from "@/server/i18n/workflow";
import { runLocalizationQa } from "@/server/i18n/qa";

/** GET /api/admin/i18n */
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
      const locale = new URL(req.url).searchParams.get("locale") || "en";
      if (view === "run") return apiSuccess({ suite: await runFullPhase11Sprint5Suite() }, ctx.requestId);
      if (view === "qa") return apiSuccess({ qa: runLocalizationQa() }, ctx.requestId);
      if (view === "status") return apiSuccess({ status: getTranslationStatusDashboard() }, ctx.requestId);
      if (view === "missing")
        return apiSuccess({ report: missingTranslationReport(locale) }, ctx.requestId);
      if (view === "packs")
        return apiSuccess(
          { packs: listInstalledLocales(), masterKeys: masterKeys().length },
          ctx.requestId
        );
      await ensureSprint5Evidence();
      return apiSuccess({ dashboard: await getPhase11Sprint5Dashboard() }, ctx.requestId);
    }
  );
}
