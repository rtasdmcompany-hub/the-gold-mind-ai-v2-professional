import { withApiGateway, apiSuccess } from "@/server/cloud/gateway";
import { readReleaseStore } from "@/server/releases/store";
import { readBillingStore } from "@/server/billing/store";
import { auditCount } from "@/server/cloud/audit";

/** GET /api/cloud/analytics — commercial funnel metrics (admin) */
export async function GET(req: Request) {
  return withApiGateway(req, { auth: "admin", rateLimit: { limit: 60, windowSec: 60 } }, async () => {
    const releases = readReleaseStore();
    const billing = readBillingStore();
    const downloads = releases.downloadEvents.length;
    const updateSuccess = releases.updateEvents.filter((e) => e.result === "success").length;
    const updateFail = releases.updateEvents.filter((e) => e.result === "fail" || e.result === "rollback").length;
    const revenueCents = billing.payments
      .filter((p) => p.status === "succeeded")
      .reduce((a, p) => a + p.amountCents, 0);
    return apiSuccess({
      downloads,
      updateSuccess,
      updateFail,
      revenueCents,
      activeSubscriptions: billing.subscriptions.filter((s) => s.status === "active" || s.status === "trialing")
        .length,
      auditEntries: auditCount(),
      note: "Commercial analytics only — no Trading Engine metrics.",
    });
  });
}
