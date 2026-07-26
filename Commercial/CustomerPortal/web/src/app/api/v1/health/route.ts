import { withApiGateway, apiSuccess } from "@/server/cloud/gateway";
import { platformHealth } from "@/server/api-platform/usage";
import { publicApiMeta } from "@/server/api-platform/public-gateway";
import { isForbiddenPath } from "@/server/api-platform/security";

/** GET /api/v1/health */
export async function GET(req: Request) {
  return withApiGateway(
    req,
    {
      auth: "public",
      rateLimit: { limit: 120, windowSec: 60, bucket: "api_v1_health" },
      auditAction: "api_request",
    },
    async (ctx) => {
      const tradingBlocked = isForbiddenPath("/api/v1/trading/orders");
      return apiSuccess(
        {
          ...platformHealth(),
          meta: publicApiMeta(),
          tradingPathBlocked: tradingBlocked,
        },
        ctx.requestId
      );
    }
  );
}
