import { withPublicApi, apiSuccess } from "@/server/api-platform/public-gateway";
import { commercialProfile } from "@/server/api-platform/commercial";

/** GET /api/v1/profile */
export async function GET(req: Request) {
  return withPublicApi(req, { scope: "profile:read" }, async (ctx) =>
    apiSuccess({ profile: commercialProfile(ctx.email) }, ctx.requestId)
  );
}
