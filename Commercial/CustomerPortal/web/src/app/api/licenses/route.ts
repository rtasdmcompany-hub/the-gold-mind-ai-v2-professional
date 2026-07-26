import { withApiGateway, apiSuccess } from "@/server/cloud/gateway";
import { listLicensesForCustomer } from "@/server/licensing/license-service";

/** GET /api/licenses — gateway-wrapped license list */
export async function GET(req: Request) {
  return withApiGateway(
    req,
    { auth: "session", rateLimit: { limit: 120, windowSec: 60 }, auditAction: "api_request" },
    async (ctx) => {
      const licenses = listLicensesForCustomer(ctx.email || "");
      return apiSuccess({ licenses }, ctx.requestId);
    }
  );
}
