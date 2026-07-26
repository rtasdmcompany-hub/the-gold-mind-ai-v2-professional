import { withPublicApi, apiSuccess } from "@/server/api-platform/public-gateway";
import { commercialNotifications } from "@/server/api-platform/commercial";

/** GET /api/v1/notifications */
export async function GET(req: Request) {
  return withPublicApi(req, { scope: "notifications:read" }, async (ctx) =>
    apiSuccess(commercialNotifications(ctx.email), ctx.requestId)
  );
}
