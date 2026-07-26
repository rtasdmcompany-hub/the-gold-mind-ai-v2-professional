import { withPublicApi, apiSuccess } from "@/server/api-platform/public-gateway";
import { commercialPartner } from "@/server/api-platform/commercial";

/** GET /api/v1/partners */
export async function GET(req: Request) {
  return withPublicApi(req, { scope: "partners:read" }, async (ctx) =>
    apiSuccess(commercialPartner(ctx.email), ctx.requestId)
  );
}
