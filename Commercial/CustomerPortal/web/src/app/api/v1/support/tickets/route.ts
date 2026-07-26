import { withPublicApi, apiSuccess } from "@/server/api-platform/public-gateway";
import { commercialSupportTickets } from "@/server/api-platform/commercial";

/** GET /api/v1/support/tickets */
export async function GET(req: Request) {
  return withPublicApi(req, { scope: "support:read" }, async (ctx) =>
    apiSuccess(commercialSupportTickets(ctx.email), ctx.requestId)
  );
}
