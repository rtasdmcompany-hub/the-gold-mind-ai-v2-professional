import { withPublicApi, apiSuccess } from "@/server/api-platform/public-gateway";
import { commercialInvoices } from "@/server/api-platform/commercial";

/** GET /api/v1/invoices */
export async function GET(req: Request) {
  return withPublicApi(req, { scope: "invoices:read" }, async (ctx) =>
    apiSuccess(commercialInvoices(ctx.email), ctx.requestId)
  );
}
