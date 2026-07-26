import { withPublicApi, apiSuccess } from "@/server/api-platform/public-gateway";
import { commercialSubscriptions } from "@/server/api-platform/commercial";

/** GET /api/v1/subscriptions */
export async function GET(req: Request) {
  return withPublicApi(req, { scope: "subscriptions:read" }, async (ctx) =>
    apiSuccess(commercialSubscriptions(ctx.email), ctx.requestId)
  );
}
