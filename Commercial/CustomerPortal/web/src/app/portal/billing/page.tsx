import { auth } from "@/auth";
import { StatusBadge } from "@/components/StatusBadge";
import { CheckoutPanel } from "@/components/CheckoutPanel";
import { getBillingSummary, formatMoney, PLAN_CATALOG } from "@/server/billing/billing-service";
import { ensureBillingStoreLoaded, billingStoreDurability } from "@/server/billing/store";
import { getProviderConfigStatus, isSandboxCheckoutAllowed } from "@/server/billing/config";
import { listLicensesForCustomer } from "@/server/licensing/license-service";
import { redirect } from "next/navigation";
import Link from "next/link";
import { brand } from "@/lib/brand";

export default async function BillingPage() {
  const session = await auth();
  if (!session?.user?.email) redirect("/login");
  await ensureBillingStoreLoaded();
  const email = session.user.email.toLowerCase();
  const billing = getBillingSummary(email);
  
  const licenses = await listLicensesForCustomer(email);
  
  const sub = billing.subscriptions[0];
  const lic = licenses.find((l) => l.status === "active" || l.status === "grace") || licenses[0];
  const durability = billingStoreDurability();
  
  const paypalConfigured = getProviderConfigStatus("paypal").configured;
  const sandboxAllowed = isSandboxCheckoutAllowed();

  // ✅ NEW: Check trial and active plan status
  const hasUsedTrial = licenses.some((l) => l.type === "trial");
  
  const now = new Date();
  const threeDaysFromNow = new Date(now.getTime() + 3 * 24 * 60 * 60 * 1000);
  
  const activePaidLicense = licenses.find((l) => 
    (l.status === "active" || l.status === "pending" || l.status === "grace") && 
    l.type !== "trial"
  );

  const expiringSoonLicense = licenses.find((l) => {
    if (l.status !== "active" && l.status !== "grace") return false;
    if (!l.expiresAt) return false;
    const expDate = new Date(l.expiresAt);
    return expDate > now && expDate <= threeDaysFromNow;
  });

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Billing</h1>
        <p className="page-sub">
          {brand.productName} · Website Edition billing center. Financial ops never touch the Trading Engine.
        </p>
      </header>

      {/* ✅ NEW: 3-Day Renewal Reminder Banner */}
      {expiringSoonLicense && (
        <div 
          className="card" 
          style={{ 
            marginBottom: 16, 
            borderColor: "var(--gm-warning, #ffc107)", 
            backgroundColor: "rgba(255, 193, 7, 0.1)" 
          }}
        >
          <h3 style={{ marginBottom: 6, color: "var(--gm-warning, #d39e00)" }}>
            ⚠️ Your {expiringSoonLicense.type} plan is expiring soon!
          </h3>
          <p className="meta" style={{ marginTop: 8, lineHeight: 1.5, marginBottom: 12 }}>
            Your current plan will expire on <strong>{new Date(expiringSoonLicense.expiresAt!).toLocaleDateString()}</strong>. 
            To avoid any interruption in your service, please renew your plan now.
          </p>
          <Link 
            href="#checkout" 
            className="btn btn-primary"
            style={{ textDecoration: "none", display: "inline-block" }}
          >
            Renew Now
          </Link>
        </div>
      )}

      {durability.warning && (
        <p className="meta" style={{ marginBottom: 12, color: "var(--gm-danger, #b91c1c)" }}>
          {durability.warning}
        </p>
      )}

      {/* ✅ UPDATED: Pass new props to CheckoutPanel */}
      <CheckoutPanel 
        sandboxAllowed={sandboxAllowed} 
        paypalConfigured={paypalConfigured}
        hasUsedTrial={hasUsedTrial}
        hasActivePaidPlan={!!activePaidLicense}
        activePlanExpiry={activePaidLicense?.expiresAt || null}
      />

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
      <p className="meta" style={{ marginBottom: 8 }}>
        Status <strong>sent</strong> means Resend accepted delivery. <strong>queued</strong> /{" "}
        <strong>failed</strong> means the message was not delivered to an inbox (check Resend config).
      </p>
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