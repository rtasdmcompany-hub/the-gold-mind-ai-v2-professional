import { auth } from "@/auth";
import { redirect } from "next/navigation";
import Link from "next/link";
import { hasPermission } from "@/server/admin/roles";
import { isDevAdminBypass } from "@/server/security/dev-bypass";
import { getPhase11Sprint9Dashboard } from "@/server/infrastructure/suite";
import { actionRunInfraSuite } from "@/server/infrastructure/actions";

export default async function OpsCenterPage() {
  const session = await auth();
  const role = (session?.user as { role?: string } | undefined)?.role;
  const actor = session?.user?.email?.toLowerCase() || "";
  if (!hasPermission(role, "admin.launch.read") && !isDevAdminBypass(actor)) {
    redirect("/portal/admin");
  }
  const dash = await getPhase11Sprint9Dashboard();
  const canWrite = hasPermission(role, "admin.launch.write") || isDevAdminBypass(actor);
  const ops = dash.ops;

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Enterprise Operations Center</h1>
        <p className="page-sub">Phase 11 Sprint 9 · global health · spend · SLA</p>
      </header>

      <div className="card" style={{ marginBottom: 16, borderLeft: "4px solid #166534" }}>
        {dash.coreIsolation} · SHA {dash.coreMatches ? "MATCH" : "FAIL"}
      </div>

      <div className="grid grid-3" style={{ marginBottom: 16 }}>
        <div className="card">
          <h3>Infrastructure</h3>
          <div className="value">{dash.infrastructureScore}</div>
        </div>
        <div className="card">
          <h3>Scalability</h3>
          <div className="value">{dash.scalabilityScore}</div>
        </div>
        <div className="card">
          <h3>Availability</h3>
          <div className="value">{dash.availabilityScore}</div>
        </div>
        <div className="card">
          <h3>Operational Excellence</h3>
          <div className="value">{dash.operationalExcellenceScore}</div>
        </div>
        <div className="card">
          <h3>Business Continuity</h3>
          <div className="value">{dash.businessContinuityScore}</div>
        </div>
        <div className="card">
          <h3>Phase 11 Progress</h3>
          <div className="value">{dash.overallPhase11Progress}%</div>
        </div>
      </div>

      {canWrite && (
        <form action={actionRunInfraSuite} style={{ marginBottom: 16 }}>
          <button type="submit" className="btn btn-primary">
            Refresh infrastructure suite
          </button>
        </form>
      )}

      <div className="grid grid-3" style={{ marginBottom: 16 }}>
        <div className="card">
          <h3>Global health</h3>
          <div className="value">{ops.globalHealth.status}</div>
          <p className="meta">
            {ops.globalHealth.componentsHealthy}/{ops.globalHealth.componentsTotal} components
          </p>
        </div>
        <div className="card">
          <h3>Cloud spend MTD</h3>
          <div className="value">${ops.cloudSpend.monthlyUsd}</div>
        </div>
        <div className="card">
          <h3>SLA</h3>
          <div className="value">{ops.executiveSla.availabilityActual}%</div>
          <p className="meta">{ops.executiveSla.met ? "targets met" : "review"}</p>
        </div>
      </div>

      <h2 style={{ fontSize: 16 }}>Regional status</h2>
      <div className="table-wrap" style={{ marginBottom: 16 }}>
        <table className="data">
          <thead>
            <tr>
              <th>Region</th>
              <th>Status</th>
              <th>Latency</th>
            </tr>
          </thead>
          <tbody>
            {ops.regionalStatus.map((r) => (
              <tr key={r.region}>
                <td>{r.region}</td>
                <td>{r.status}</td>
                <td>{r.latencyMs} ms</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <h2 style={{ fontSize: 16 }}>Active incidents</h2>
      <div className="card" style={{ marginBottom: 16 }}>
        {ops.activeIncidents.length === 0
          ? "None open"
          : ops.activeIncidents.map((i) => (
              <div key={i.id}>
                {i.severity}: {i.title} ({i.status})
              </div>
            ))}
      </div>

      <p>
        <Link className="btn" href="/portal/admin/infra-capacity">
          Capacity
        </Link>{" "}
        <Link className="btn" href="/portal/admin/sla-executive">
          Executive SLA
        </Link>
      </p>
      <p className="meta" style={{ marginTop: 24 }}>
        STOP — Await Owner approval before Sprint 10.
      </p>
    </>
  );
}
