import { appendAudit, mutateStore, readStore } from "./store";
import type { SubscriptionPublicDto, SubscriptionRecord, LicenseType } from "./types";

export function toPublicSubscription(s: SubscriptionRecord): SubscriptionPublicDto {
  return {
    id: s.id,
    licenseId: s.licenseId,
    plan: s.plan,
    status: s.status,
    renewalDate: s.renewalDate,
    expirationDate: s.expirationDate,
    graceEndsAt: s.graceEndsAt,
    cancelledAt: s.cancelledAt,
    renewedAt: s.renewedAt,
    pendingPlanChange: s.pendingPlanChange,
  };
}

export function listSubscriptionsForCustomer(email: string): SubscriptionPublicDto[] {
  const e = email.trim().toLowerCase();
  return readStore()
    .subscriptions.filter((s) => s.customerEmail === e)
    .map(toPublicSubscription);
}

export function listAllSubscriptionsAdmin(): SubscriptionRecord[] {
  return readStore().subscriptions;
}

/** Future: upgrade/downgrade — records pending plan only */
export function requestPlanChange(licenseId: string, email: string, newPlan: LicenseType): boolean {
  const e = email.trim().toLowerCase();
  let ok = false;
  mutateStore((store) => {
    const s = store.subscriptions.find((x) => x.licenseId === licenseId && x.customerEmail === e);
    if (!s) return;
    s.pendingPlanChange = newPlan;
    appendAudit(store, {
      actorEmail: e,
      action: "subscription.updated",
      entityType: "subscription",
      entityId: s.id,
      detail: `Pending plan change → ${newPlan} (future)`,
    });
    ok = true;
  });
  return ok;
}
