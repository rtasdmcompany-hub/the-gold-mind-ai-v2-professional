import { auth } from "@/auth";
import { StatusBadge } from "@/components/StatusBadge";
import { ensureSeedData } from "@/server/licensing/seed";
import { listSubscriptionsForCustomer } from "@/server/licensing/subscription-service";
import { actionCancelSubscription, actionRenewLicense } from "@/server/licensing/actions";
import { getBillingSummary, PLAN_CATALOG } from "@/server/billing/billing-service";
import { redirect } from "next/navigation";
import Link from "next/link";

/**
 * Portal subscriptions — entitlement (licensing) + commercial billing ledger.
 * Website Edition only; independent of MQL5 Market billing.
 */
export default async function SubscriptionsPage() {
  ensureSeedData();
  const session = await auth();
  if (!session?.user?.email) redirect("/login");
  const email = session.user.email;
  const subs = listSubscriptionsForCustomer(email);
  const billing = getBillingSummary(email);

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Subscriptions</h1>
        <p className="page-sub">
          License entitlement + Website Edition billing status · renewal · expiration · grace.{" "}
          <Link href="/portal/billing">Billing Center</Link>
        </p>
      </header>

      <h2 style={{ fontSize: 16, marginBottom: 12 }}>Billing subscriptions</h2>
      {billing.subscriptions.length === 0 ? (
        <p className="meta" style={{ marginBottom: 20 }}>
          No commercial billing subscriptions — start checkout in Billing.
        </p>
      ) : (
        <div className="table-wrap" style={{ marginBottom: 24 }}>
          <table className="data">
            <thead>
              <tr>
                <th>Plan</th>
                <th>Status</th>
                <th>Provider</th>
                <th>Renewal</th>
                <th>Next billing</th>
                <th>License</th>
              </tr>
            </thead>
            <tbody>
              {billing.subscriptions.map((s) => (
                <tr key={s.id}>
                  <td>{PLAN_CATALOG[s.plan]?.label || s.plan}</td>
                  <td>
                    <StatusBadge status={s.status} />
                  </td>
                  <td>{s.provider}</td>
                  <td>{s.renewalDate?.slice(0, 10) || "—"}</td>
                  <td>{s.nextBillingDate?.slice(0, 10) || "—"}</td>
                  <td className="mono">{s.licenseId || "—"}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      <h2 style={{ fontSize: 16, marginBottom: 12 }}>License entitlements</h2>
      {subs.length === 0 && <p className="meta">No license subscriptions linked to this account.</p>}

      <div className="grid" style={{ gap: 16 }}>
        {subs.map((sub) => (
          <div className="card" key={sub.id}>
            <div className="grid grid-3">
              <div>
                <h3>Plan</h3>
                <div className="value" style={{ fontSize: 18 }}>
                  {sub.plan}
                </div>
              </div>
              <div>
                <h3>Status</h3>
                <StatusBadge status={sub.status} />
              </div>
              <div>
                <h3>Renewal / Expiration</h3>
                <div className="meta">Renewal: {sub.renewalDate?.slice(0, 10) || "—"}</div>
                <div className="meta">Expires: {sub.expirationDate?.slice(0, 10) || "Lifetime"}</div>
                <div className="meta">Grace ends: {sub.graceEndsAt?.slice(0, 10) || "—"}</div>
              </div>
            </div>
            <div className="meta" style={{ marginTop: 12 }}>
              Cancelled: {sub.cancelledAt?.slice(0, 10) || "—"} · Renewed: {sub.renewedAt?.slice(0, 10) || "—"} ·
              Pending change: {sub.pendingPlanChange || "—"}
            </div>
            <div style={{ display: "flex", gap: 8, marginTop: 12 }}>
              <form action={actionRenewLicense}>
                <input type="hidden" name="licenseId" value={sub.licenseId} />
                <button type="submit" className="btn btn-primary">
                  Renew
                </button>
              </form>
              <form action={actionCancelSubscription}>
                <input type="hidden" name="licenseId" value={sub.licenseId} />
                <button type="submit" className="btn">
                  Cancel
                </button>
              </form>
            </div>
          </div>
        ))}
      </div>
    </>
  );
}
