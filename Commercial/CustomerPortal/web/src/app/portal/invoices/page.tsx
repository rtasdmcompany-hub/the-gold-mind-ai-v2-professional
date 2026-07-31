import { auth } from "@/auth";
import { StatusBadge } from "@/components/StatusBadge";
import { getBillingSummary, formatMoney, PLAN_CATALOG } from "@/server/billing/billing-service";
import { ensureBillingStoreLoaded, billingStoreDurability } from "@/server/billing/store";
import { redirect } from "next/navigation";
import Link from "next/link";

export default async function InvoicesPage() {
  const session = await auth();
  if (!session?.user?.email) redirect("/login");
  await ensureBillingStoreLoaded();
  const { invoices } = getBillingSummary(session.user.email);
  const durability = billingStoreDurability();

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Invoices</h1>
        <p className="page-sub">
          Website Edition invoices from the billing engine. <Link href="/portal/billing">Open Billing Center</Link>
        </p>
      </header>
      {durability.warning && (
        <p className="meta" style={{ marginBottom: 12, color: "var(--gm-danger, #b91c1c)" }}>
          {durability.warning}
        </p>
      )}
      <div className="table-wrap">
        <table className="data">
          <thead>
            <tr>
              <th>Invoice</th>
              <th>Date</th>
              <th>Description</th>
              <th>Amount</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
            {invoices.length === 0 && (
              <tr>
                <td colSpan={5}>No invoices — complete a checkout in Billing (empty until a verified payment webhook).</td>
              </tr>
            )}
            {invoices.map((inv) => (
              <tr key={inv.id}>
                <td className="mono">{inv.id}</td>
                <td>{inv.createdAt.slice(0, 10)}</td>
                <td>{PLAN_CATALOG[inv.plan]?.label || inv.plan}</td>
                <td>{formatMoney(inv.amountCents, inv.currency)}</td>
                <td>
                  <StatusBadge status={inv.status} />
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </>
  );
}
