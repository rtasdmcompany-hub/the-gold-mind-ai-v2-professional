import { auth } from "@/auth";
import { StatusBadge } from "@/components/StatusBadge";
import { CheckoutPanel } from "@/components/CheckoutPanel";
import { getBillingSummary, formatMoney, PLAN_CATALOG } from "@/server/billing/billing-service";
import { listLicensesForCustomer } from "@/server/licensing/license-service";
import { redirect } from "next/navigation";
import Link from "next/link";

export default async function BillingPage() {
  const session = await auth();
  if (!session?.user?.email) redirect("/login");
  const email = session.user.email.toLowerCase();
  const billing = getBillingSummary(email);
  const licenses = listLicensesForCustomer(email);
  const sub = billing.subscriptions[0];
  const lic = licenses.find((l) => l.status === "active" || l.status === "grace") || licenses[0];

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Billing</h1>
        <p className="page-sub">
          THE GOLD MIND PROFESSIONAL · Website Edition billing center. Financial ops never touch the Trading Engine.
        </p>
      </header>

      <CheckoutPanel />

      <div className="grid grid-3" style={{ marginBottom: 16 }}>
        <div className="card">
          <h3>Current Subscription</h3>
          <div className="value" style={{ fontSize: 18 }}>
            {sub ? sub.plan : "—"}
          </div>
          <div className="meta">
            {sub ? <StatusBadge status={sub.status} /> : "No billing subscription"}
          </div>
        </div>
        <div className="card">
          <h3>Renewal / Next Billing</h3>
          <div className="meta">Renewal: {sub?.renewalDate?.slice(0, 10) || "—"}</div>
          <div className="meta">Next billing: {sub?.nextBillingDate?.slice(0, 10) || "—"}</div>
        </div>
        <div className="card">
          <h3>License Status</h3>
          <div className="value" style={{ fontSize: 16 }}>
            {lic ? <StatusBadge status={lic.status} /> : "—"}
          </div>
          <div className="meta">
            <Link href="/portal/licenses">{lic?.keyMasked || "My Licenses"}</Link>
          </div>
        </div>
      </div>

      <h2 style={{ fontSize: 16 }}>Invoices &amp; Receipts</h2>
      <div className="table-wrap" style={{ marginBottom: 20 }}>
        <table className="data">
          <thead>
            <tr>
              <th>Invoice</th>
              <th>Plan</th>
              <th>Amount</th>
              <th>Status</th>
              <th>Paid</th>
              <th>Provider</th>
            </tr>
          </thead>
          <tbody>
            {billing.invoices.length === 0 && (
              <tr>
                <td colSpan={6}>No invoices yet.</td>
              </tr>
            )}
            {billing.invoices.map((inv) => (
              <tr key={inv.id}>
                <td className="mono">{inv.id}</td>
                <td>{PLAN_CATALOG[inv.plan]?.label || inv.plan}</td>
                <td>{formatMoney(inv.amountCents, inv.currency)}</td>
                <td>
                  <StatusBadge status={inv.status} />
                </td>
                <td>{inv.paidAt?.slice(0, 10) || "—"}</td>
                <td>{inv.provider}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <h2 style={{ fontSize: 16 }}>Payment History</h2>
      <div className="table-wrap" style={{ marginBottom: 20 }}>
        <table className="data">
          <thead>
            <tr>
              <th>Payment</th>
              <th>Amount</th>
              <th>Status</th>
              <th>Provider</th>
              <th>When</th>
              <th>Note</th>
            </tr>
          </thead>
          <tbody>
            {billing.payments.length === 0 && (
              <tr>
                <td colSpan={6}>No payments yet.</td>
              </tr>
            )}
            {billing.payments.map((p) => (
              <tr key={p.id}>
                <td className="mono">{p.id}</td>
                <td>{formatMoney(p.amountCents, p.currency)}</td>
                <td>
                  <StatusBadge status={p.status} />
                </td>
                <td>{p.provider}</td>
                <td>{p.createdAt.slice(0, 19).replace("T", " ")}</td>
                <td>{p.note || "—"}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <h2 style={{ fontSize: 16 }}>Email notifications (outbox)</h2>
      <div className="table-wrap">
        <table className="data">
          <thead>
            <tr>
              <th>Template</th>
              <th>Subject</th>
              <th>Status</th>
              <th>When</th>
            </tr>
          </thead>
          <tbody>
            {billing.emails.map((m) => (
              <tr key={m.id}>
                <td className="mono">{m.template}</td>
                <td>{m.subject}</td>
                <td>
                  <StatusBadge status={m.status} />
                </td>
                <td>{m.createdAt.slice(0, 19).replace("T", " ")}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </>
  );
}
