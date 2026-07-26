import { auth } from "@/auth";
import { redirect } from "next/navigation";
import Link from "next/link";
import { hasPermission } from "@/server/admin/roles";
import { isDevAdminBypass } from "@/server/security/dev-bypass";
import { getPhase11Sprint2Dashboard } from "@/server/phase11/bi/dashboard";
import { actionRunPhase11Sprint2 } from "@/server/phase11/bi/actions";

export default async function BiExecutivePage() {
  const session = await auth();
  const role = (session?.user as { role?: string } | undefined)?.role;
  const actor = session?.user?.email?.toLowerCase() || "";
  if (!hasPermission(role, "admin.launch.read") && !isDevAdminBypass(actor)) {
    redirect("/portal/admin");
  }
  const dash = await getPhase11Sprint2Dashboard();
  const e = dash.executive;
  const canWrite = hasPermission(role, "admin.launch.write") || isDevAdminBypass(actor);

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Executive Business Intelligence</h1>
        <p className="page-sub">Phase 11 Sprint 2 · ACTUAL commercial KPIs only on tiles</p>
      </header>

      <div className="card" style={{ marginBottom: 16, borderLeft: "4px solid #166534" }}>
        {dash.coreIsolation} · SHA {dash.coreMatches ? "MATCH" : "FAIL"}
      </div>

      {canWrite && (
        <form action={actionRunPhase11Sprint2} style={{ marginBottom: 16 }}>
          <button type="submit" className="btn btn-primary">
            Refresh BI suite
          </button>
        </form>
      )}

      <div className="grid grid-3" style={{ marginBottom: 16 }}>
        <div className="card">
          <h3>Business Intelligence</h3>
          <div className="value">{dash.businessIntelligenceScore}</div>
        </div>
        <div className="card">
          <h3>Revenue Readiness</h3>
          <div className="value">{dash.revenueReadinessScore}</div>
        </div>
        <div className="card">
          <h3>Commercial Intelligence</h3>
          <div className="value">{dash.commercialIntelligenceScore}</div>
        </div>
        <div className="card">
          <h3>Executive Reporting</h3>
          <div className="value">{dash.executiveReportingScore}</div>
        </div>
        <div className="card">
          <h3>Growth Readiness</h3>
          <div className="value">{dash.growthReadinessScore}</div>
        </div>
        <div className="card">
          <h3>Phase 11 Progress</h3>
          <div className="value">{dash.overallPhase11Progress}%</div>
        </div>
      </div>

      {e && (
        <div className="grid grid-3" style={{ marginBottom: 16 }}>
          <div className="card">
            <h3>Total Customers</h3>
            <div className="value">{e.totalCustomers}</div>
            <p className="meta">ACTUAL</p>
          </div>
          <div className="card">
            <h3>Active Customers</h3>
            <div className="value">{e.activeCustomers}</div>
          </div>
          <div className="card">
            <h3>Trial / Paid</h3>
            <div className="value" style={{ fontSize: 18 }}>
              {e.trialCustomers} / {e.paidCustomers}
            </div>
          </div>
          <div className="card">
            <h3>Monthly Revenue</h3>
            <div className="value" style={{ fontSize: 16 }}>
              {e.monthlyRevenue.formatted}
            </div>
          </div>
          <div className="card">
            <h3>Annual Revenue</h3>
            <div className="value" style={{ fontSize: 16 }}>
              {e.annualRevenue.formatted}
            </div>
          </div>
          <div className="card">
            <h3>MRR</h3>
            <div className="value" style={{ fontSize: 16 }}>
              {e.mrr.formatted}
            </div>
          </div>
          <div className="card">
            <h3>ARR</h3>
            <div className="value" style={{ fontSize: 16 }}>
              {e.arr.formatted}
            </div>
          </div>
          <div className="card">
            <h3>ARPU</h3>
            <div className="value" style={{ fontSize: 16 }}>
              {e.arpu.formatted}
            </div>
          </div>
          <div className="card">
            <h3>Observed historical value</h3>
            <div className="value" style={{ fontSize: 16 }}>
              {e.clv.formatted}
            </div>
            <p className="meta">{e.clv.label} — not projected LTV</p>
          </div>
        </div>
      )}

      {dash.forecast && (
        <div className="card" style={{ marginBottom: 16, borderLeft: "4px solid #a16207" }}>
          <h3>FORECAST (not ACTUAL)</h3>
          <p className="meta">{dash.forecast.disclaimer}</p>
          <p>
            Revenue horizon confidence: <strong>{dash.forecast.revenue.confidence}</strong> · Readiness{" "}
            {dash.forecastAccuracyReadiness}
          </p>
        </div>
      )}

      <p>
        <Link className="btn" href="/portal/admin/bi-revenue">
          Revenue
        </Link>{" "}
        <Link className="btn" href="/portal/admin/bi-subscriptions">
          Subscriptions
        </Link>{" "}
        <Link className="btn" href="/portal/admin/bi-customers">
          Customers
        </Link>{" "}
        <Link className="btn" href="/portal/admin/global-ops">
          Global Ops
        </Link>
      </p>
      <p className="meta" style={{ marginTop: 24 }}>
        STOP — Await Owner approval before Sprint 3.
      </p>
    </>
  );
}
