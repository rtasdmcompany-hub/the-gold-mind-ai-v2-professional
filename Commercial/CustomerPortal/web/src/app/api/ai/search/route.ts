import { withApiGateway, apiSuccess } from "@/server/cloud/gateway";
import { gatewayKnowledgeCatalog, gatewaySearch } from "@/server/ai-assistant/gateway";

/** GET /api/ai/search?q= */
export async function GET(req: Request) {
  return withApiGateway(
    req,
    {
      auth: "public",
      rateLimit: { limit: 60, windowSec: 60, bucket: "ai_search" },
      auditAction: "api_request",
    },
    async (ctx) => {
      const url = new URL(req.url);
      const q = url.searchParams.get("q") || "";
      const view = url.searchParams.get("view") || "search";
      if (view === "catalog") {
        return apiSuccess({ catalog: gatewayKnowledgeCatalog() }, ctx.requestId);
      }
      const hits = gatewaySearch(q, Number(url.searchParams.get("limit") || 5));
      return apiSuccess({ query: q, hits }, ctx.requestId);
    }
  );
}
