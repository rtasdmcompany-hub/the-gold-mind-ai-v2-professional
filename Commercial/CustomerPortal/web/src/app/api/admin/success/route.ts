import { withApiGateway, apiSuccess } from "@/server/cloud/gateway";
import { getSuccessExecutiveDashboard } from "@/server/success/cs-dashboard";
import { getCustomerHealth, listCustomerHealthDirectory, getCustomerSuccessSummary } from "@/server/success/customer-health";
import { getSupportAnalytics } from "@/server/success/support-analytics";
import { getProductionStabilization } from "@/server/success/production-stabilization";
import { getKbStats, listKbArticles } from "@/server/success/knowledge-base";
import { getIssueSummary, ensureDemoIssues } from "@/server/launch/issue-store";
import { getFeedbackSummary, ensureDemoFeedback } from "@/server/launch/feedback-store";

/** GET /api/admin/success */
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
      ensureDemoIssues();
      ensureDemoFeedback();
      if (view === "customers") {
        return apiSuccess(
          {
            summary: getCustomerSuccessSummary(),
            directory: listCustomerHealthDirectory(url.searchParams.get("q") || undefined),
          },
          ctx.requestId
        );
      }
      if (view === "customer") {
        const email = url.searchParams.get("email") || "";
        return apiSuccess({ profile: email ? getCustomerHealth(email) : null }, ctx.requestId);
      }
      if (view === "support") {
        return apiSuccess({ analytics: getSupportAnalytics() }, ctx.requestId);
      }
      if (view === "stabilization") {
        return apiSuccess({ stabilization: await getProductionStabilization() }, ctx.requestId);
      }
      if (view === "kb") {
        return apiSuccess({ stats: getKbStats(), articles: listKbArticles() }, ctx.requestId);
      }
      if (view === "issues") {
        return apiSuccess({ summary: getIssueSummary() }, ctx.requestId);
      }
      if (view === "feedback") {
        return apiSuccess({ summary: getFeedbackSummary() }, ctx.requestId);
      }
      return apiSuccess({ dashboard: await getSuccessExecutiveDashboard() }, ctx.requestId);
    }
  );
}
