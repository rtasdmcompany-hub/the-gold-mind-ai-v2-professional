import { withApiGateway, apiSuccess } from "@/server/cloud/gateway";
import { getProductionHealthDashboard } from "@/server/observability/health-dashboard";
import { getTelemetrySummary, ensureDemoTelemetry } from "@/server/observability/telemetry-store";
import { getUsageAnalytics, ensureDemoUsage } from "@/server/observability/usage-analytics";
import { getAlertSummary, listAlertRules, listAlerts } from "@/server/observability/alert-store";
import { evaluateAlerts } from "@/server/observability/alert-engine";
import { getOpsIntelligenceDashboard } from "@/server/observability/ops-intelligence";
import { getMonitoringSecurityReview } from "@/server/observability/monitoring-security";
import { getIncidentTimeline, ensureDemoIncidents } from "@/server/launch/incident-store";

/** GET /api/admin/observability */
export async function GET(req: Request) {
  return withApiGateway(
    req,
    {
      auth: "admin",
      permission: "admin.observability.read",
      rateLimit: { limit: 60, windowSec: 60 },
      auditAction: "admin_action",
    },
    async (ctx) => {
      const view = new URL(req.url).searchParams.get("view") || "health";
      if (view === "telemetry") {
        ensureDemoTelemetry();
        return apiSuccess({ telemetry: getTelemetrySummary() }, ctx.requestId);
      }
      if (view === "usage") {
        ensureDemoUsage();
        return apiSuccess({ usage: getUsageAnalytics() }, ctx.requestId);
      }
      if (view === "alerts") {
        return apiSuccess(
          { summary: getAlertSummary(), rules: listAlertRules(), events: listAlerts() },
          ctx.requestId
        );
      }
      if (view === "evaluate") {
        const result = await evaluateAlerts();
        return apiSuccess({ result, summary: getAlertSummary() }, ctx.requestId);
      }
      if (view === "ops") {
        return apiSuccess({ ops: await getOpsIntelligenceDashboard() }, ctx.requestId);
      }
      if (view === "security") {
        return apiSuccess({ security: getMonitoringSecurityReview() }, ctx.requestId);
      }
      if (view === "timeline") {
        ensureDemoIncidents();
        return apiSuccess({ timeline: getIncidentTimeline() }, ctx.requestId);
      }
      return apiSuccess({ health: await getProductionHealthDashboard() }, ctx.requestId);
    }
  );
}
