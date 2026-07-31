import { auth } from "@/auth";
import { StatusBadge } from "@/components/StatusBadge";
import { getAdminBillingDashboard, formatMoney } from "@/server/billing/billing-service";
import { actionRunExpiryNotices, actionRunRenewalReminders } from "@/server/billing/actions";
import { redirect } from "next/navigation";
import { hasPermission } from "@/server/admin/roles";

export default async function AdminBillingPage() {
  const session = await auth();
  const role = (session?.user as { role?: string } | undefined)?.role;
  if (!hasPermission(role, "admin.billing.read")) redirect("/portal");
  const canWrite = hasPermission(role, "admin.billing.write");

  const dash = getAdminBillingDashboard();

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Admin · Billing Dashboard</h1>
        <p className="page-sub">Read-only financial overview · Website Edition · no Trading Engine coupling</p>
      </header>

      <div className="grid grid-3" style={{ marginBottom: 16 }}>
        <div className="card">
          <h3>Revenue Summary</h3>
          <div className="value">{dash.revenueFormatted}</div>
        </div>
        <div className="card">
          <h3>Active Subscriptions</h3>
          <div className="value">{dash.subscriptionCount}</div>
        </div>
        <div className="card">
          <h3>Failed Payments</h3>
          <div className="value">{dash.failedPayments.length}</div>
        </div>
      </div>

      {canWrite && (
        <div style={{ display: "flex", flexWrap: "wrap", gap: 8, marginBottom: 16 }}>
          <form action={actionRunRenewalReminders}>
            <button type="submit" className="btn">
              Queue renewal reminder emails
            </button>
          </form>
          <form action={actionRunExpiryNotices}>
            <button type="submit" className="btn">
              Queue expiry notice emails
            </button>
          </form>
        </div>
      )}

      <h2 style={{ fontSize: 16 }}>Recent Transactions</h2>
      <div className="table-wrap" style={{ marginBottom: 20 }}>
        <table className="data">
          <thead>
            <tr>
              <th>ID</th>
              <th>Customer</th>
              <th>Amount</th>
              <th>Status</th>
              <th>Provider</th>
              <th>When</th>
            </tr>
          </thead>
          <tbody>
            {dash.recentTransactions.map((t) => (
              <tr key={t.id}>
                <td className="mono">{t.id}</td>
                <td>{t.customerEmail}</td>
                <td>{formatMoney(t.amountCents, t.currency)}</td>
                <td>
                  <StatusBadge status={t.status} />
                </td>
                <td>{t.provider}</td>
                <td>{t.createdAt.slice(0, 19).replace("T", " ")}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <h2 style={{ fontSize: 16 }}>Refunds</h2>
      <div className="table-wrap" style={{ marginBottom: 20 }}>
        <table className="data">
          <thead>
            <tr>
              <th>ID</th>
              <th>Customer</th>
              <th>Amount</th>
              <th>When</th>
            </tr>
          </thead>
          <tbody>
            {dash.refunds.length === 0 && (
              <tr>
                <td colSpan={4}>No refunds</td>
              </tr>
            )}
            {dash.refunds.map((r) => (
              <tr key={r.id}>
                <td className="mono">{r.id}</td>
                <td>{r.customerEmail}</td>
                <td>{formatMoney(r.amountCents, r.currency)}</td>
                <td>{r.createdAt.slice(0, 10)}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <h2 style={{ fontSize: 16 }}>Renewals</h2>
      <div className="table-wrap" style={{ marginBottom: 20 }}>
        <table className="data">
          <thead>
            <tr>
              <th>ID</th>
              <th>Customer</th>
              <th>Amount</th>
              <th>When</th>
            </tr>
          </thead>
          <tbody>
            {dash.renewals.length === 0 && (
              <tr>
                <td colSpan={4}>No renewals yet</td>
              </tr>
            )}
            {dash.renewals.map((r) => (
              <tr key={r.id}>
                <td className="mono">{r.id}</td>
                <td>{r.customerEmail}</td>
                <td>{formatMoney(r.amountCents, r.currency)}</td>
                <td>{r.createdAt.slice(0, 10)}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <h2 style={{ fontSize: 16 }}>Subscriptions</h2>
      <div className="table-wrap" style={{ marginBottom: 20 }}>
        <table className="data">
          <thead>
            <tr>
              <th>Customer</th>
              <th>Plan</th>
              <th>Status</th>
              <th>Next billing</th>
              <th>Provider</th>
            </tr>
          </thead>
          <tbody>
            {dash.subscriptions.map((s) => (
              <tr key={s.id}>
                <td>{s.customerEmail}</td>
                <td>{s.plan}</td>
                <td>
                  <StatusBadge status={s.status} />
                </td>
                <td>{s.nextBillingDate?.slice(0, 10) || "—"}</td>
                <td>{s.provider}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <h2 style={{ fontSize: 16 }}>Webhook Audit (security log)</h2>
      <div className="table-wrap">
        <table className="data">
          <thead>
            <tr>
              <th>When</th>
              <th>Provider</th>
              <th>Auth</th>
              <th>Type</th>
              <th>Status</th>
              <th>Detail</th>
            </tr>
          </thead>
          <tbody>
            {dash.webhookAudits.length === 0 && (
              <tr>
                <td colSpan={6}>No webhook attempts logged yet.</td>
              </tr>
            )}
            {dash.webhookAudits.map((a) => (
              <tr key={a.id}>
                <td>{a.at.slice(0, 19).replace("T", " ")}</td>
                <td>{a.provider}</td>
                <td>{a.authenticated ? "ok" : "fail"}</td>
                <td className="mono">{a.eventType || "—"}</td>
                <td>
                  {a.httpStatus}
                  {a.duplicate ? " · dup" : ""}
                </td>
                <td>{a.detail}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </>
  );
}
