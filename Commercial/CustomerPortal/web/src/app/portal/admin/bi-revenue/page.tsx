import { auth } from "@/auth";
import { redirect } from "next/navigation";
import Link from "next/link";
import { hasPermission } from "@/server/admin/roles";
import { isDevAdminBypass } from "@/server/security/dev-bypass";
import { getPhase11Sprint2Dashboard } from "@/server/phase11/bi/dashboard";

export default async function BiRevenuePage() {
  const session = await auth();
  const role = (session?.user as { role?: string } | undefined)?.role;
  const actor = session?.user?.email?.toLowerCase() || "";
  if (!hasPermission(role, "admin.launch.read") && !isDevAdminBypass(actor)) {
    redirect("/portal/admin");
  }
  const dash = await getPhase11Sprint2Dashboard();
  const r = dash.revenue;

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Revenue Analytics</h1>
        <p className="page-sub">Phase 11 Sprint 2 · ACTUAL ledger · country UNATTRIBUTED when untagged</p>
      </header>

      <div className="grid grid-3" style={{ marginBottom: 16 }}>
        <div className="card">
          <h3>Revenue Analytics Score</h3>
          <div className="value">{dash.revenueAnalyticsScore}</div>
        </div>
        <div className="card">
          <h3>AOV</h3>
          <div className="value" style={{ fontSize: 16 }}>
            {r?.averageOrderValue.formatted ?? "—"}
          </div>
        </div>
        <div className="card">
          <h3>MoM Growth</h3>
          <div className="value">{r?.revenueGrowth.monthOverMonthPct ?? 0}%</div>
        </div>
        <div className="card">
          <h3>Refund Rate</h3>
          <div className="value">{r?.refundRate.value ?? 0}%</div>
        </div>
        <div className="card">
          <h3>Chargeback Rate</h3>
          <div className="value">{r?.chargebackRate.value ?? 0}%</div>
        </div>
        <div className="card">
          <h3>Total Succeeded</h3>
          <div className="value" style={{ fontSize: 16 }}>
            {r?.totalSucceeded.formatted ?? "—"}
          </div>
        </div>
      </div>

      {r && (
        <>
          <h2 style={{ fontSize: 16 }}>By plan</h2>
          <ul>
            {r.revenueByPlan.map((row) => (
              <li key={row.plan}>
                {row.plan}: {row.formatted}
              </li>
            ))}
          </ul>
          <h2 style={{ fontSize: 16 }}>By provider</h2>
          <ul>
            {r.revenueByPaymentProvider.map((row) => (
              <li key={row.provider}>
                {row.provider}: {row.formatted}
              </li>
            ))}
          </ul>
          <h2 style={{ fontSize: 16 }}>By country ({r.revenueByCountry.kind})</h2>
          <p className="meta">{r.revenueByCountry.note}</p>
          <ul>
            {r.revenueByCountry.rows.map((row) => (
              <li key={row.country}>
                {row.country}: {row.formatted}
              </li>
            ))}
          </ul>
          <h2 style={{ fontSize: 16 }}>Monthly trend (ACTUAL)</h2>
          <div className="table-wrap">
            <table className="data">
              <thead>
                <tr>
                  <th>Month</th>
                  <th>Revenue</th>
                </tr>
              </thead>
              <tbody>
                {r.monthlyRevenueTrend.map((t) => (
                  <tr key={t.month}>
                    <td>{t.month}</td>
                    <td>{t.formatted}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </>
      )}

      <p style={{ marginTop: 24 }}>
        <Link className="btn" href="/portal/admin/bi-executive">
          BI Executive
        </Link>
      </p>
    </>
  );
}
