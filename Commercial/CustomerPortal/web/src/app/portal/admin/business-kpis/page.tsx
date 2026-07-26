import { auth } from "@/auth";
import { redirect } from "next/navigation";
import Link from "next/link";
import { hasPermission } from "@/server/admin/roles";
import { isDevAdminBypass } from "@/server/security/dev-bypass";
import { getPhase11Sprint1Dashboard } from "@/server/phase11/dashboard";

export default async function BusinessKpisPage() {
  const session = await auth();
  const role = (session?.user as { role?: string } | undefined)?.role;
  const actor = session?.user?.email?.toLowerCase() || "";
  if (!hasPermission(role, "admin.launch.read") && !isDevAdminBypass(actor)) {
    redirect("/portal/admin");
  }
  const dash = await getPhase11Sprint1Dashboard();
  const k = dash.kpis;

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Business KPI Dashboard</h1>
        <p className="page-sub">Phase 11 Sprint 1 · measurable commercial KPIs</p>
      </header>

      {k && (
        <div className="grid grid-3" style={{ marginBottom: 16 }}>
          <div className="card">
            <h3>DAU</h3>
            <div className="value">{k.dailyActiveUsers}</div>
          </div>
          <div className="card">
            <h3>WAU</h3>
            <div className="value">{k.weeklyActiveUsers}</div>
          </div>
          <div className="card">
            <h3>MAU</h3>
            <div className="value">{k.monthlyActiveUsers}</div>
          </div>
          <div className="card">
            <h3>Customer Growth</h3>
            <div className="value" style={{ fontSize: 16 }}>
              {k.customerGrowth.active} active · +{k.customerGrowth.newToday} today
            </div>
          </div>
          <div className="card">
            <h3>License Growth</h3>
            <div className="value" style={{ fontSize: 16 }}>
              {k.licenseGrowth.active} · act {k.licenseGrowth.activationsToday}
            </div>
          </div>
          <div className="card">
            <h3>Subscription Growth</h3>
            <div className="value" style={{ fontSize: 16 }}>
              {k.subscriptionGrowth.active} / {k.subscriptionGrowth.total}
            </div>
          </div>
          <div className="card">
            <h3>Renewal Rate</h3>
            <div className="value">{k.renewalRate}%</div>
          </div>
          <div className="card">
            <h3>Cancellation Rate</h3>
            <div className="value">{k.cancellationRate}%</div>
          </div>
          <div className="card">
            <h3>Trial Conversion</h3>
            <div className="value">{k.trialConversionRate}%</div>
          </div>
          <div className="card">
            <h3>Customer Satisfaction</h3>
            <div className="value">{k.customerSatisfaction}</div>
          </div>
        </div>
      )}

      {k && k.revenueTrend.length > 0 && (
        <>
          <h2 style={{ fontSize: 16 }}>Revenue Trend</h2>
          <div className="table-wrap">
            <table className="data">
              <thead>
                <tr>
                  <th>Month</th>
                  <th>Revenue</th>
                </tr>
              </thead>
              <tbody>
                {k.revenueTrend.map((r) => (
                  <tr key={r.month}>
                    <td>{r.month}</td>
                    <td>{r.formatted}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </>
      )}

      <p style={{ marginTop: 24 }}>
        <Link className="btn" href="/portal/admin/global-ops">
          Global Ops
        </Link>
      </p>
    </>
  );
}
