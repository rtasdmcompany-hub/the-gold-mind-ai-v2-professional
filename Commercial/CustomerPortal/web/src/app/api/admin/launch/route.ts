import { withApiGateway, apiSuccess } from "@/server/cloud/gateway";
import { getExecutiveLaunchDashboard } from "@/server/launch/dashboard";
import { getExecutiveBetaDashboard } from "@/server/launch/beta-dashboard";
import { runProductionMonitoring } from "@/server/launch/production-monitoring";
import { LAUNCH_ENVIRONMENTS } from "@/server/launch/environments";
import { getBetaSummary, getEnrollmentFunnel, listBetaParticipants } from "@/server/launch/beta-store";
import { getIncidentSummary, listIncidents } from "@/server/launch/incident-store";
import { getFeedbackSummary, listFeedback } from "@/server/launch/feedback-store";
import { getIssueSummary, listIssues } from "@/server/launch/issue-store";
import { ensureDemoMetrics, getProductionMetrics } from "@/server/launch/metrics-store";

/** GET /api/admin/launch — controlled launch / beta ops API */
export async function GET(req: Request) {
  return withApiGateway(
    req,
    {
      auth: "admin",
      permission: "admin.launch.read",
      rateLimit: { limit: 60, windowSec: 60 },
      auditAction: "admin_action",
    },
    async (ctx) => {
      const url = new URL(req.url);
      const view = url.searchParams.get("view") || "dashboard";
      if (view === "monitoring") {
        return apiSuccess({ monitoring: await runProductionMonitoring(true) }, ctx.requestId);
      }
      if (view === "environments") {
        return apiSuccess({ environments: LAUNCH_ENVIRONMENTS }, ctx.requestId);
      }
      if (view === "beta") {
        return apiSuccess(
          {
            summary: getBetaSummary(),
            participants: listBetaParticipants(),
            funnel: getEnrollmentFunnel(),
          },
          ctx.requestId
        );
      }
      if (view === "beta-dashboard") {
        return apiSuccess({ dashboard: await getExecutiveBetaDashboard() }, ctx.requestId);
      }
      if (view === "issues") {
        return apiSuccess({ summary: getIssueSummary(), issues: listIssues() }, ctx.requestId);
      }
      if (view === "metrics") {
        ensureDemoMetrics();
        return apiSuccess({ metrics: getProductionMetrics() }, ctx.requestId);
      }
      if (view === "incidents") {
        return apiSuccess(
          { summary: getIncidentSummary(), incidents: listIncidents() },
          ctx.requestId
        );
      }
      if (view === "feedback") {
        return apiSuccess({ summary: getFeedbackSummary(), items: listFeedback() }, ctx.requestId);
      }
      const dashboard = await getExecutiveLaunchDashboard();
      return apiSuccess({ dashboard }, ctx.requestId);
    }
  );
}
