import { withApiGateway, apiSuccess } from "@/server/cloud/gateway";
import { listCloudServices } from "@/server/cloud/services";
import { runHealthChecks } from "@/server/cloud/monitoring";
import { getCacheBackend } from "@/server/cloud/cache";
import { getBackupPolicy, getMigrationPolicy, getSecretRotationStrategy } from "@/server/cloud/database";

/** GET /api/cloud/services — service registry (admin) */
export async function GET(req: Request) {
  return withApiGateway(req, { auth: "admin", rateLimit: { limit: 60, windowSec: 60 } }, async () => {
    const health = await runHealthChecks(true);
    return apiSuccess({
      services: listCloudServices(),
      health,
      cacheBackend: getCacheBackend(),
      database: {
        backup: getBackupPolicy(),
        migration: getMigrationPolicy(),
        secretRotation: getSecretRotationStrategy(),
      },
      isolation: {
        tradingEngineCoupled: false,
        cloudFailureStopsTrading: false,
      },
    });
  });
}
