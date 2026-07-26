import { auth } from "@/auth";
import { redirect } from "next/navigation";
import Link from "next/link";
import { hasPermission } from "@/server/admin/roles";
import { isDevAdminBypass } from "@/server/security/dev-bypass";
import { getPhase11Sprint1Dashboard } from "@/server/phase11/dashboard";

export default async function CommercialOpsPage() {
  const session = await auth();
  const role = (session?.user as { role?: string } | undefined)?.role;
  const actor = session?.user?.email?.toLowerCase() || "";
  if (!hasPermission(role, "admin.launch.read") && !isDevAdminBypass(actor)) {
    redirect("/portal/admin");
  }
  const dash = await getPhase11Sprint1Dashboard();
  const c = dash.commercial;
  const h = dash.health;

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Commercial Operations</h1>
        <p className="page-sub">Phase 11 Sprint 1 · auditable workflows · operational health</p>
      </header>

      <div className="grid grid-3" style={{ marginBottom: 16 }}>
        <div className="card">
          <h3>Commercial Score</h3>
          <div className="value">{dash.commercialOperationsScore}</div>
        </div>
        <div className="card">
          <h3>Health Score</h3>
          <div className="value">{dash.operationalHealthScore}</div>
        </div>
        <div className="card">
          <h3>Reports Generated</h3>
          <div className="value">{dash.reports.length}</div>
        </div>
      </div>

      {c && (
        <>
          <h2 style={{ fontSize: 16 }}>Workflows</h2>
          <div className="table-wrap" style={{ marginBottom: 16 }}>
            <table className="data">
              <thead>
                <tr>
                  <th>Workflow</th>
                  <th>Status</th>
                  <th>Auditable</th>
                  <th>Evidence</th>
                </tr>
              </thead>
              <tbody>
                {c.workflows.map((w) => (
                  <tr key={w.id}>
                    <td>{w.label}</td>
                    <td>{w.status}</td>
                    <td>{w.auditable ? "yes" : "no"}</td>
                    <td className="meta">{w.evidence}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </>
      )}

      {h && (
        <>
          <h2 style={{ fontSize: 16 }}>Operational Health</h2>
          <div className="table-wrap">
            <table className="data">
              <thead>
                <tr>
                  <th>Service</th>
                  <th>Status</th>
                  <th>Latency</th>
                </tr>
              </thead>
              <tbody>
                {h.services.map((s) => (
                  <tr key={s.id}>
                    <td>{s.label}</td>
                    <td>{s.status}</td>
                    <td>{s.latencyMs} ms</td>
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
