import { auth } from "@/auth";
import { redirect } from "next/navigation";
import Link from "next/link";
import { hasPermission } from "@/server/admin/roles";
import { isDevAdminBypass } from "@/server/security/dev-bypass";
import { getPhase11Sprint10Dashboard } from "@/server/phase11-closure/suite";
import { actionRunPhase11Closure } from "@/server/phase11-closure/actions";

export default async function Phase11CertificationPage() {
  const session = await auth();
  const role = (session?.user as { role?: string } | undefined)?.role;
  const actor = session?.user?.email?.toLowerCase() || "";
  if (!hasPermission(role, "admin.launch.read") && !isDevAdminBypass(actor)) {
    redirect("/portal/admin");
  }
  const dash = await getPhase11Sprint10Dashboard();
  const canWrite = hasPermission(role, "admin.launch.write") || isDevAdminBypass(actor);

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Phase 11 Certification</h1>
        <p className="page-sub">Sprint 10 · global enterprise certification</p>
      </header>

      <div
        className="card"
        style={{
          marginBottom: 16,
          borderLeft: `4px solid ${dash.coreMatches ? "#166534" : "#b91c1c"}`,
        }}
      >
        {dash.coreIsolation}
        <br />
        Core SHA {dash.coreMatches ? "MATCH" : "FAIL"} · Decision: <strong>{dash.decision}</strong>
      </div>

      <div className="grid grid-3" style={{ marginBottom: 16 }}>
        <div className="card">
          <h3>Engineering</h3>
          <div className="value">{dash.engineeringScore}</div>
        </div>
        <div className="card">
          <h3>Commercial</h3>
          <div className="value">{dash.commercialScore}</div>
        </div>
        <div className="card">
          <h3>Operations</h3>
          <div className="value">{dash.operationsScore}</div>
        </div>
        <div className="card">
          <h3>Security</h3>
          <div className="value">{dash.securityScore}</div>
        </div>
        <div className="card">
          <h3>Infrastructure</h3>
          <div className="value">{dash.infrastructureScore}</div>
        </div>
        <div className="card">
          <h3>Enterprise</h3>
          <div className="value">{dash.enterpriseScore}</div>
        </div>
        <div className="card">
          <h3>Customer Success</h3>
          <div className="value">{dash.customerSuccessScore}</div>
        </div>
        <div className="card">
          <h3>Global Readiness</h3>
          <div className="value">{dash.globalReadinessScore}</div>
        </div>
        <div className="card">
          <h3>Overall Product</h3>
          <div className="value">{dash.overallProductScore}</div>
        </div>
        <div className="card">
          <h3>Phase 11 Progress</h3>
          <div className="value">{dash.phase11Progress}%</div>
        </div>
      </div>

      {canWrite && (
        <form action={actionRunPhase11Closure} style={{ marginBottom: 16 }}>
          <button type="submit" className="btn btn-primary">
            Run Phase 11 certification suite
          </button>
        </form>
      )}

      <h2 style={{ fontSize: 16 }}>Enterprise certification</h2>
      <div className="table-wrap" style={{ marginBottom: 16 }}>
        <table className="data">
          <thead>
            <tr>
              <th>Item</th>
              <th>Status</th>
              <th>Detail</th>
            </tr>
          </thead>
          <tbody>
            {dash.enterprise.map((i) => (
              <tr key={i.id}>
                <td>{i.label}</td>
                <td>{i.status}</td>
                <td>{i.detail}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <h2 style={{ fontSize: 16 }}>Project statistics</h2>
      <div className="grid grid-3" style={{ marginBottom: 16 }}>
        <div className="card">
          <h3>Modules</h3>
          <div className="value">{dash.stats.architectureModules}</div>
        </div>
        <div className="card">
          <h3>Docs</h3>
          <div className="value">{dash.stats.documentationFiles}</div>
        </div>
        <div className="card">
          <h3>APIs</h3>
          <div className="value">{dash.stats.apis}</div>
        </div>
        <div className="card">
          <h3>Dashboards</h3>
          <div className="value">{dash.stats.dashboards}</div>
        </div>
        <div className="card">
          <h3>Project completion</h3>
          <div className="value">{dash.stats.overallProjectCompletionPct}%</div>
        </div>
      </div>

      <p>
        <Link className="btn" href="/portal/admin/phase11-decision">
          Executive Decision
        </Link>
      </p>
      <p className="meta" style={{ marginTop: 24 }}>
        STOP — Await Owner approval before beginning Phase 12.
      </p>
    </>
  );
}
