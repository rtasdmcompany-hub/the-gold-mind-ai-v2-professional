import { auth } from "@/auth";
import { StatusBadge } from "@/components/StatusBadge";
import { getBillingSummary, formatMoney, PLAN_CATALOG } from "@/server/billing/billing-service";
import { redirect } from "next/navigation";

export default async function OrdersPage() {
  const session = await auth();
  if (!session?.user?.email) redirect("/login");
  const { payments } = getBillingSummary(session.user.email);
  const orders = payments.filter((p) => p.status === "succeeded");

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Orders</h1>
        <p className="page-sub">Successful Website Edition transactions.</p>
      </header>
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
                <td colSpan={5}>No orders yet.</td>
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
