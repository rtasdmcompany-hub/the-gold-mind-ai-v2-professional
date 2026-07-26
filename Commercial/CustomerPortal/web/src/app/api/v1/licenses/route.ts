import { withPublicApi, apiSuccess } from "@/server/api-platform/public-gateway";
import { commercialLicenses } from "@/server/api-platform/commercial";

/** GET /api/v1/licenses */
export async function GET(req: Request) {
  return withPublicApi(req, { scope: "licenses:read" }, async (ctx) =>
    apiSuccess(commercialLicenses(ctx.email), ctx.requestId)
  );
}
