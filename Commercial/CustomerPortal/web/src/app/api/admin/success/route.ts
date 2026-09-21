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
      
      // ✅ FIX: Sabhi ensure functions ke aage await laga diya gaya hai
      await ensureDemoIssues();
      await ensureDemoFeedback();

      if (view === "customers") {
        return apiSuccess(
          {
            // ✅ FIX: Await added to be safe
            summary: await getCustomerSuccessSummary(),
            directory: await listCustomerHealthDirectory(url.searchParams.get("q") || undefined),
          },
          ctx.requestId
        );
      }
      if (view === "customer") {
        const email = url.searchParams.get("email") || "";
        // ✅ FIX: Await added to be safe
        return apiSuccess({ profile: email ? await getCustomerHealth(email) : null }, ctx.requestId);
      }
      if (view === "support") {
        // ✅ FIX: Await added to be safe
        return apiSuccess({ analytics: await getSupportAnalytics() }, ctx.requestId);
      }
      if (view === "stabilization") {
        return apiSuccess({ stabilization: await getProductionStabilization() }, ctx.requestId);
      }
      if (view === "kb") {
        // ✅ FIX: Await added to be safe
        return apiSuccess({ stats: await getKbStats(), articles: await listKbArticles() }, ctx.requestId);
      }
      if (view === "issues") {
        // ✅ FIX: Await added to be safe
        return apiSuccess({ summary: await getIssueSummary() }, ctx.requestId);
      }
      if (view === "feedback") {
        // ✅ FIX: Await added to be safe
        return apiSuccess({ summary: await getFeedbackSummary() }, ctx.requestId);
      }
      return apiSuccess({ dashboard: await getSuccessExecutiveDashboard() }, ctx.requestId);
    }
  );
}
