import { auth } from "@/auth";
import { StatusBadge } from "@/components/StatusBadge";
import { getBillingSummary, formatMoney, PLAN_CATALOG } from "@/server/billing/billing-service";
import { ensureBillingStoreLoaded, billingStoreDurability } from "@/server/billing/store";
import { redirect } from "next/navigation";
import Link from "next/link";

export default async function OrdersPage() {
  const session = await auth();
  if (!session?.user?.email) redirect("/login");
  await ensureBillingStoreLoaded();
  const { payments } = getBillingSummary(session.user.email);
  const orders = payments.filter((p) => p.status === "succeeded");
  const durability = billingStoreDurability();

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Orders</h1>
        <p className="page-sub">
          Successful Website Edition payments (order ledger = paid transactions).{" "}
          <Link href="/portal/billing">Billing</Link>
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
              <th>Order / Payment</th>
              <th>Date</th>
              <th>Product</th>
              <th>Amount</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
            {orders.length === 0 && (
              <tr>
                <td colSpan={5}>No orders yet — empty until a verified payment succeeds.</td>
              </tr>
            )}
            {orders.map((o) => (
              <tr key={o.id}>
                <td className="mono">{o.id}</td>
                <td>{o.createdAt.slice(0, 10)}</td>
                <td>{o.plan ? PLAN_CATALOG[o.plan]?.label : "Professional"}</td>
                <td>{formatMoney(o.amountCents, o.currency)}</td>
                <td>
                  <StatusBadge status={o.status} />
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </>
  );
}
