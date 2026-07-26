import { auth } from "@/auth";
import { StatusBadge } from "@/components/StatusBadge";
import { getBillingSummary, formatMoney, PLAN_CATALOG } from "@/server/billing/billing-service";
import { redirect } from "next/navigation";
import Link from "next/link";

export default async function InvoicesPage() {
  const session = await auth();
  if (!session?.user?.email) redirect("/login");
  const { invoices } = getBillingSummary(session.user.email);

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Invoices</h1>
        <p className="page-sub">
          Website Edition invoices from the billing engine. <Link href="/portal/billing">Open Billing Center</Link>
        </p>
      </header>
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
                <td colSpan={5}>No invoices — complete a checkout in Billing.</td>
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
