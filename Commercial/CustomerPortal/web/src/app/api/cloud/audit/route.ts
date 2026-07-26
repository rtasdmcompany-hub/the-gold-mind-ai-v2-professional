import { withApiGateway, apiSuccess } from "@/server/cloud/gateway";
import { listAudit } from "@/server/cloud/audit";
import type { AuditAction } from "@/server/cloud/types";

/** GET /api/cloud/audit — centralized audit (admin / support) */
export async function GET(req: Request) {
  return withApiGateway(
    req,
    { auth: "support", rateLimit: { limit: 120, windowSec: 60 }, auditAction: "admin_action" },
    async () => {
      const url = new URL(req.url);
      const limit = Math.min(Number(url.searchParams.get("limit") || 50), 200);
      const action = url.searchParams.get("action") as AuditAction | null;
      const user = url.searchParams.get("user") || undefined;
      return apiSuccess({
        entries: listAudit(limit, {
          action: action || undefined,
          user,
        }),
      });
    }
  );
}
