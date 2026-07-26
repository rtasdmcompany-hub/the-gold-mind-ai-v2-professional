import { withPublicApi, apiSuccess } from "@/server/api-platform/public-gateway";
import { commercialDownloads } from "@/server/api-platform/commercial";

/** GET /api/v1/downloads */
export async function GET(req: Request) {
  return withPublicApi(req, { scope: "downloads:read" }, async (ctx) =>
    apiSuccess(commercialDownloads(), ctx.requestId)
  );
}
