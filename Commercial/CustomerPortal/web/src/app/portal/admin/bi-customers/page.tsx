import { auth } from "@/auth";
import { redirect } from "next/navigation";
import Link from "next/link";
import { hasPermission } from "@/server/admin/roles";
import { isDevAdminBypass } from "@/server/security/dev-bypass";
import { getPhase11Sprint2Dashboard } from "@/server/phase11/bi/dashboard";

export default async function BiCustomersPage() {
  const session = await auth();
  const role = (session?.user as { role?: string } | undefined)?.role;
  const actor = session?.user?.email?.toLowerCase() || "";
  if (!hasPermission(role, "admin.launch.read") && !isDevAdminBypass(actor)) {
    redirect("/portal/admin");
  }
  const dash = await getPhase11Sprint2Dashboard();
  const c = dash.customers;
  const f = dash.forecast;

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Customer Analytics & Forecasting</h1>
        <p className="page-sub">Phase 11 Sprint 2 · ACTUAL usage · FORECAST appendix segregated</p>
      </header>

      {c && (
        <div className="grid grid-3" style={{ marginBottom: 16 }}>
          <div className="card">
            <h3>DAU</h3>
            <div className="value">{c.dailyActiveUsers}</div>
          </div>
          <div className="card">
            <h3>WAU</h3>
            <div className="value">{c.weeklyActiveUsers}</div>
          </div>
          <div className="card">
            <h3>MAU</h3>
            <div className="value">{c.monthlyActiveUsers}</div>
          </div>
          <div className="card">
            <h3>Session (min)</h3>
            <div className="value">{c.sessionDuration.minutes}</div>
          </div>
          <div className="card">
            <h3>Retention</h3>
            <div className="value">{c.customerRetention.percent}%</div>
          </div>
          <div className="card">
            <h3>Churn proxy</h3>
            <div className="value">{c.customerChurn.percent}%</div>
          </div>
          <div className="card">
            <h3>CSAT</h3>
            <div className="value">{c.customerSatisfaction}</div>
          </div>
          <div className="card">
            <h3>Support activity</h3>
            <div className="value" style={{ fontSize: 16 }}>
              {c.supportActivity.open} open / {c.supportActivity.total}
            </div>
          </div>
        </div>
      )}

      {c && c.featureAdoption.length > 0 && (
        <>
          <h2 style={{ fontSize: 16 }}>Feature adoption (ACTUAL)</h2>
          <ul>
            {c.featureAdoption.map((f) => (
              <li key={f.feature}>
                {f.feature}: {f.count}
              </li>
            ))}
          </ul>
        </>
      )}

      {f && (
        <div className="card" style={{ marginTop: 16, borderLeft: "4px solid #a16207" }}>
          <h3>FORECAST appendix</h3>
          <p className="meta">{f.disclaimer}</p>
          <div className="table-wrap">
            <table className="data">
              <thead>
                <tr>
                  <th>Month</th>
                  <th>Revenue (F)</th>
                  <th>Subs (F)</th>
                  <th>Growth (F)</th>
                  <th>Renewals (F)</th>
                </tr>
              </thead>
              <tbody>
                {f.horizonMonths.map((m, i) => (
                  <tr key={m}>
                    <td>{m}</td>
                    <td>{f.revenue.formatted[i]}</td>
                    <td>{f.subscriptions.values[i]}</td>
                    <td>{f.customerGrowth.values[i]}</td>
                    <td>{f.renewals.values[i]}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          <p className="meta">
            Forecast accuracy readiness: {f.forecastAccuracyReadiness.score} · revenue confidence{" "}
            {f.revenue.confidence}
          </p>
        </div>
      )}

      <p style={{ marginTop: 24 }}>
        <Link className="btn" href="/portal/admin/bi-executive">
          BI Executive
        </Link>
      </p>
    </>
  );
}
