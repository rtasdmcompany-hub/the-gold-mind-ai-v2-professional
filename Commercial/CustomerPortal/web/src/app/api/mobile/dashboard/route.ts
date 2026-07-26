import { withApiGateway, apiSuccess, apiError } from "@/server/cloud/gateway";
import { buildMobileCustomerDashboard } from "@/server/mobile/dashboard";
import { requireMobileSession } from "@/server/mobile/http";

/** GET /api/mobile/dashboard */
export async function GET(req: Request) {
  return withApiGateway(
    req,
    {
      auth: "public",
      rateLimit: { limit: 60, windowSec: 60, bucket: "mobile_dash" },
      auditAction: "api_request",
    },
    async (ctx) => {
      try {
        const session = requireMobileSession(req);
        const dashboard = buildMobileCustomerDashboard(session.customerEmail);
        return apiSuccess({ dashboard }, ctx.requestId);
      } catch (e) {
        const msg = e instanceof Error ? e.message : "UNAUTHORIZED";
        return apiError(msg, msg, 401, ctx.requestId);
      }
    }
  );
}
