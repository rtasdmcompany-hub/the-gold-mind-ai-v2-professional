import { auth } from "@/auth";
import { redirect } from "next/navigation";
import Link from "next/link";
import { hasPermission } from "@/server/admin/roles";
import { isDevAdminBypass } from "@/server/security/dev-bypass";
import { getPhase11Sprint1Dashboard } from "@/server/phase11/dashboard";
import { actionRunPhase11Sprint1 } from "@/server/phase11/actions";

export default async function GlobalOpsPage() {
  const session = await auth();
  const role = (session?.user as { role?: string } | undefined)?.role;
  const actor = session?.user?.email?.toLowerCase() || "";
  if (!hasPermission(role, "admin.launch.read") && !isDevAdminBypass(actor)) {
    redirect("/portal/admin");
  }
  const dash = await getPhase11Sprint1Dashboard();
  const ops = dash.ops;
  const canWrite = hasPermission(role, "admin.launch.write") || isDevAdminBypass(actor);

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Global Operations Center</h1>
        <p className="page-sub">Phase 11 Sprint 1 · Website Professional commercial SaaS operations</p>
      </header>

      <div className="card" style={{ marginBottom: 16, borderLeft: "4px solid #166534" }}>
        {dash.coreIsolation} · SHA {dash.coreMatches ? "MATCH" : "FAIL"}
      </div>

      {canWrite && (
        <form action={actionRunPhase11Sprint1} style={{ marginBottom: 16 }}>
          <button type="submit" className="btn btn-primary">
            Refresh Phase 11 Sprint 1 suite
          </button>
        </form>
      )}

      <div className="grid grid-3" style={{ marginBottom: 16 }}>
        <div className="card">
          <h3>Business Operations</h3>
          <div className="value">{dash.businessOperationsScore}</div>
        </div>
        <div className="card">
          <h3>Commercial Operations</h3>
          <div className="value">{dash.commercialOperationsScore}</div>
        </div>
        <div className="card">
          <h3>Customer Success</h3>
          <div className="value">{dash.customerSuccessScore}</div>
        </div>
        <div className="card">
          <h3>Operational Health</h3>
          <div className="value">{dash.operationalHealthScore}</div>
        </div>
        <div className="card">
          <h3>Executive Readiness</h3>
          <div className="value">{dash.executiveReadinessScore}</div>
        </div>
        <div className="card">
          <h3>Phase 11 Progress</h3>
          <div className="value">{dash.overallPhase11Progress}%</div>
        </div>
      </div>

      {ops && (
        <div className="grid grid-3" style={{ marginBottom: 16 }}>
          <div className="card">
            <h3>Active Customers</h3>
            <div className="value">{ops.activeCustomers}</div>
          </div>
          <div className="card">
            <h3>Active Licenses</h3>
            <div className="value">{ops.activeLicenses}</div>
          </div>
          <div className="card">
            <h3>New Registrations</h3>
            <div className="value">{ops.newRegistrations}</div>
          </div>
          <div className="card">
            <h3>Revenue</h3>
            <div className="value" style={{ fontSize: 18 }}>
              {ops.revenue}
            </div>
          </div>
          <div className="card">
            <h3>Subscriptions</h3>
            <div className="value">{ops.subscriptionStatus.active}</div>
          </div>
          <div className="card">
            <h3>Website Health</h3>
            <div className="value" style={{ fontSize: 16 }}>
              {ops.websiteHealth}
            </div>
          </div>
          <div className="card">
            <h3>API Health</h3>
            <div className="value" style={{ fontSize: 16 }}>
              {ops.apiHealth}
            </div>
          </div>
          <div className="card">
            <h3>System Health</h3>
            <div className="value" style={{ fontSize: 16 }}>
              {ops.systemHealth}
            </div>
          </div>
          <div className="card">
            <h3>Support Queue</h3>
            <div className="value">{ops.supportQueue.open}</div>
          </div>
          <div className="card">
            <h3>Security Alerts</h3>
            <div className="value">{ops.securityAlerts.firing}</div>
          </div>
          <div className="card">
            <h3>Global Uptime</h3>
            <div className="value" style={{ fontSize: 16 }}>
              {ops.globalUptime.percentProxy}%
            </div>
          </div>
          <div className="card">
            <h3>Portal Status</h3>
            <div className="value" style={{ fontSize: 16 }}>
              {ops.customerPortalStatus}
            </div>
          </div>
        </div>
      )}

      <p>
        <Link className="btn" href="/portal/admin/business-kpis">
          Business KPIs
        </Link>{" "}
        <Link className="btn" href="/portal/admin/commercial-ops">
          Commercial Ops
        </Link>{" "}
        <Link className="btn" href="/portal/admin/cs-operations">
          Customer Success
        </Link>
      </p>
      <p className="meta" style={{ marginTop: 24 }}>
        STOP — Await Owner approval before Sprint 2.
      </p>
    </>
  );
}
