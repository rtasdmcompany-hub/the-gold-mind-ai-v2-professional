import { withPublicApi, apiSuccess } from "@/server/api-platform/public-gateway";
import { commercialOrganizations } from "@/server/api-platform/commercial";

/** GET /api/v1/organizations */
export async function GET(req: Request) {
  return withPublicApi(req, { scope: "organizations:read" }, async (ctx) =>
    apiSuccess(commercialOrganizations(ctx.email), ctx.requestId)
  );
}
