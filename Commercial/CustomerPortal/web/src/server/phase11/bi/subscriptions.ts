/**
 * Task 2 — Subscription Analytics (ACTUAL).
 */
import { savePhase11Run } from "../store";
import { safeEnsureCommercialData } from "../safe";
import { loadBiLedger } from "./helpers";

export async function buildSubscriptionAnalytics() {
  safeEnsureCommercialData();
  const { payments, subscriptions, licenses } = await loadBiLedger();
  const month = new Date().toISOString().slice(0, 7);

  const renewals = payments.filter((p) => p.note === "renewal" && p.status === "succeeded").length;
  const expiredLicenses = licenses.filter((l) => l.status === "expired").length;
  const cancelledPlans = subscriptions.filter((s) => s.status === "cancelled").length;
  const active = subscriptions.filter((s) => s.status === "active" || s.status === "trialing").length;

  const upgradesMarked = payments.filter((p) => /upgrade/i.test(p.note || "")).length;
  const downgradesMarked = payments.filter((p) => /downgrade/i.test(p.note || "")).length;
  const taggedChanges = upgradesMarked + downgradesMarked;
  const upgradeRate =
    taggedChanges === 0 ? 0 : Math.round((upgradesMarked / taggedChanges) * 1000) / 10;
  const downgradeRate =
    taggedChanges === 0 ? 0 : Math.round((downgradesMarked / taggedChanges) * 1000) / 10;

  const failedRenewals = payments.filter(
    (p) => p.status === "failed" && /renew/i.test(p.note || "")
  ).length;
  const renewalAttempts = renewals + failedRenewals;
  const renewalSuccessRate =
    renewalAttempts === 0 ? 100 : Math.round((renewals / renewalAttempts) * 1000) / 10;

  const ever = Math.max(subscriptions.length, 1);
  const subscriptionRetention = Math.round((active / ever) * 1000) / 10;
  const newThisMonth = subscriptions.filter((s) => s.createdAt?.startsWith(month)).length;

  const payload = {
    kind: "ACTUAL" as const,
    newSubscriptions: newThisMonth,
    renewals,
    expiredLicenses,
    cancelledPlans,
    upgradeRate: {
      value: upgradeRate,
      basis:
        taggedChanges > 0
          ? "payment notes tagged upgrade/downgrade"
          : "no tagged plan-change events — rate = 0 (not estimated)",
      upgradesMarked,
    },
    downgradeRate: {
      value: downgradeRate,
      basis: "payment notes tagged downgrade",
      downgradesMarked,
    },
    renewalSuccessRate,
    subscriptionRetention,
    activeSubscriptions: active,
    totalSubscriptions: subscriptions.length,
    at: new Date().toISOString(),
  };
  savePhase11Run("bi_subscriptions", "Subscription analytics", payload);
  return payload;
}