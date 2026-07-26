import { auth } from "@/auth";
import { redirect } from "next/navigation";
import Link from "next/link";
import { hasPermission } from "@/server/admin/roles";
import { isDevAdminBypass } from "@/server/security/dev-bypass";
import { getPhase11Sprint3Dashboard } from "@/server/partners/suite";

export default async function PartnerAnalyticsAdminPage() {
  const session = await auth();
  const role = (session?.user as { role?: string } | undefined)?.role;
  const actor = session?.user?.email?.toLowerCase() || "";
  if (!hasPermission(role, "admin.launch.read") && !isDevAdminBypass(actor)) {
    redirect("/portal/admin");
  }
  const dash = await getPhase11Sprint3Dashboard();
  const a = dash.analytics;

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Partner Analytics</h1>
        <p className="page-sub">Phase 11 Sprint 3 · ACTUAL referral & commission metrics</p>
      </header>

      <div className="grid grid-3" style={{ marginBottom: 16 }}>
        <div className="card">
          <h3>Clicks</h3>
          <div className="value">{a.clicks}</div>
        </div>
        <div className="card">
          <h3>Registrations</h3>
          <div className="value">{a.registrations}</div>
        </div>
        <div className="card">
          <h3>Sales</h3>
          <div className="value">{a.sales}</div>
        </div>
        <div className="card">
          <h3>Revenue</h3>
          <div className="value" style={{ fontSize: 16 }}>
            {a.revenue.formatted}
          </div>
        </div>
        <div className="card">
          <h3>Commission</h3>
          <div className="value" style={{ fontSize: 16 }}>
            {a.commission.formatted}
          </div>
        </div>
        <div className="card">
          <h3>Refund Impact</h3>
          <div className="value" style={{ fontSize: 16 }}>
            {a.refundImpact.formatted}
          </div>
        </div>
      </div>

      <h2 style={{ fontSize: 16 }}>Top Performing Partners</h2>
      <div className="table-wrap" style={{ marginBottom: 16 }}>
        <table className="data">
          <thead>
            <tr>
              <th>Partner</th>
              <th>Tier</th>
              <th>Clicks</th>
              <th>Sales</th>
              <th>Revenue</th>
              <th>Commission</th>
            </tr>
          </thead>
          <tbody>
            {a.topPerformingPartners.map((p) => (
              <tr key={p.partnerId}>
                <td>{p.name}</td>
                <td>{p.tier}</td>
                <td>{p.clicks}</td>
                <td>{p.sales}</td>
                <td>{p.revenueFormatted}</td>
                <td>{p.commissionFormatted}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <h2 style={{ fontSize: 16 }}>Regional Performance</h2>
      <ul>
        {a.regionalPerformance.map((r) => (
          <li key={r.region}>
            {r.region}: {r.revenueFormatted} · {r.sales} sales · {r.partners} partners
          </li>
        ))}
      </ul>

      <p style={{ marginTop: 24 }}>
        <Link className="btn" href="/portal/admin/partners">
          Partner Ops
        </Link>
      </p>
    </>
  );
}
