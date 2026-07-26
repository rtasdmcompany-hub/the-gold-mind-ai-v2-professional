import { auth } from "@/auth";
import { redirect } from "next/navigation";
import { hasPermission } from "@/server/admin/roles";
import { getBusinessIntelligence } from "@/server/admin/ops";
import { ensureSeedData } from "@/server/licensing/seed";
import { ensureDemoTickets } from "@/server/admin/support-store";

export default async function AdminBiPage() {
  ensureSeedData();
  ensureDemoTickets();
  const session = await auth();
  const role = (session?.user as { role?: string } | undefined)?.role;
  const actor = session?.user?.email?.toLowerCase() || "";
  if (!hasPermission(role, "admin.bi.read") && actor !== "admin@goldmind.local") redirect("/portal");

  const bi = getBusinessIntelligence();

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Business Intelligence</h1>
        <p className="page-sub">
          Revenue · growth · retention · activation · renewal · refunds · support · adoption — commercial metrics only
        </p>
      </header>

      <div className="grid grid-3" style={{ marginBottom: 16 }}>
        <div className="card">
          <h3>Customer Retention</h3>
          <div className="value">{bi.customerRetention}%</div>
        </div>
        <div className="card">
          <h3>Activation Rate</h3>
          <div className="value">{bi.activationRate}%</div>
        </div>
        <div className="card">
          <h3>Renewal Rate</h3>
          <div className="value">{bi.renewalRate}%</div>
        </div>
        <div className="card">
          <h3>Active Subscriptions</h3>
          <div className="value">{bi.subscriptionGrowth.active}</div>
        </div>
        <div className="card">
          <h3>Refunds</h3>
          <div className="value">{bi.refundStatistics.count}</div>
          <div className="meta">USD {(bi.refundStatistics.cents / 100).toFixed(2)}</div>
        </div>
        <div className="card">
          <h3>Support Performance</h3>
          <div className="value">{bi.supportPerformance.resolvedRate}%</div>
          <div className="meta">
            Open {bi.supportPerformance.open} · Total {bi.supportPerformance.total}
          </div>
        </div>
      </div>

      <h2 style={{ fontSize: 16 }}>Revenue trends</h2>
      <div className="table-wrap" style={{ marginBottom: 20 }}>
        <table className="data">
          <thead>
            <tr>
              <th>Month</th>
              <th>Revenue</th>
            </tr>
          </thead>
          <tbody>
            {bi.revenueTrends.length === 0 && (
              <tr>
                <td colSpan={2}>No succeeded payments yet</td>
              </tr>
            )}
            {bi.revenueTrends.map((r) => (
              <tr key={r.month}>
                <td>{r.month}</td>
                <td>{r.formatted}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <h2 style={{ fontSize: 16 }}>Product adoption</h2>
      <div className="grid grid-3">
        <div className="card">
          <h3>Downloads</h3>
          <div className="value">{bi.productAdoption.downloads}</div>
        </div>
        <div className="card">
          <h3>Update Success Rate</h3>
          <div className="value">{bi.productAdoption.updateSuccessRate}%</div>
        </div>
        <div className="card">
          <h3>Licenses by type</h3>
          <div className="meta">Trial {bi.productAdoption.licensesByType.trial}</div>
          <div className="meta">Monthly {bi.productAdoption.licensesByType.monthly}</div>
          <div className="meta">Yearly {bi.productAdoption.licensesByType.yearly}</div>
          <div className="meta">Lifetime {bi.productAdoption.licensesByType.lifetime}</div>
        </div>
      </div>
    </>
  );
}
