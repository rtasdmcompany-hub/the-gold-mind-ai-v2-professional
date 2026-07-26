import { withApiGateway, apiSuccess } from "@/server/cloud/gateway";
import { getMobileArchitecture } from "@/server/mobile/architecture";
import { MOBILE_CORE_ISOLATION, MOBILE_TRADING_PROHIBITED } from "@/server/mobile/types";
import { readMobileStore } from "@/server/mobile/store";

/** GET /api/mobile/health — companion health; never reports trading engine state */
export async function GET(req: Request) {
  return withApiGateway(
    req,
    {
      auth: "public",
      rateLimit: { limit: 120, windowSec: 60, bucket: "mobile_health" },
      auditAction: "api_request",
    },
    async (ctx) => {
      const arch = getMobileArchitecture();
      return apiSuccess(
        {
          status: "healthy",
          tradingProhibited: MOBILE_TRADING_PROHIBITED,
          coreIsolation: MOBILE_CORE_ISOLATION,
          tradingEngineOnMobile: false,
          versions: readMobileStore().appVersions,
          apiBase: arch.responsiveApiLayer.basePath,
          at: new Date().toISOString(),
        },
        ctx.requestId
      );
    }
  );
}
