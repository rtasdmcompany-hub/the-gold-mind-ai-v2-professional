import { auth } from "@/auth";
import { redirect } from "next/navigation";
import Link from "next/link";
import { hasPermission } from "@/server/admin/roles";
import { isDevAdminBypass } from "@/server/security/dev-bypass";
import { getPhase11Sprint9Dashboard } from "@/server/infrastructure/suite";

export default async function SlaExecutivePage() {
  const session = await auth();
  const role = (session?.user as { role?: string } | undefined)?.role;
  const actor = session?.user?.email?.toLowerCase() || "";
  if (!hasPermission(role, "admin.launch.read") && !isDevAdminBypass(actor)) {
    redirect("/portal/admin");
  }
  const dash = await getPhase11Sprint9Dashboard();
  const sla = dash.ops.executiveSla;

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Executive SLA Dashboard</h1>
        <p className="page-sub">Availability · API success · continuity targets</p>
      </header>

      <div className="grid grid-3" style={{ marginBottom: 16 }}>
        <div className="card">
          <h3>Availability</h3>
          <div className="value">
            {sla.availabilityActual}% / {sla.availabilityTarget}%
          </div>
        </div>
        <div className="card">
          <h3>API success</h3>
          <div className="value">
            {sla.apiSuccessRateActual}% / {sla.apiSuccessRateTarget}%
          </div>
        </div>
        <div className="card">
          <h3>SLA overall</h3>
          <div className="value">{sla.met ? "MET" : "REVIEW"}</div>
        </div>
      </div>

      <h2 style={{ fontSize: 16 }}>Observability</h2>
      <div className="table-wrap" style={{ marginBottom: 16 }}>
        <table className="data">
          <thead>
            <tr>
              <th>Metric</th>
              <th>Value</th>
              <th>SLA</th>
            </tr>
          </thead>
          <tbody>
            {dash.obs.metrics.map((m) => (
              <tr key={m.id}>
                <td>{m.label}</td>
                <td>
                  {m.value} {m.unit}
                </td>
                <td>
                  {m.slaTarget !== undefined
                    ? `${m.slaMet ? "met" : "miss"} (target ${m.slaTarget})`
                    : "—"}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <h2 style={{ fontSize: 16 }}>HA checks</h2>
      <div className="table-wrap" style={{ marginBottom: 16 }}>
        <table className="data">
          <thead>
            <tr>
              <th>Check</th>
              <th>Status</th>
              <th>Detail</th>
            </tr>
          </thead>
          <tbody>
            {dash.ha.checks.map((c) => (
              <tr key={c.id}>
                <td>{c.label}</td>
                <td>{c.status}</td>
                <td>{c.detail}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <h2 style={{ fontSize: 16 }}>Continuity (RTO/RPO)</h2>
      <div className="table-wrap" style={{ marginBottom: 16 }}>
        <table className="data">
          <thead>
            <tr>
              <th>Control</th>
              <th>RTO</th>
              <th>RPO</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
            {dash.bc.controls.map((c) => (
              <tr key={c.id}>
                <td>{c.label}</td>
                <td>{c.rtoMinutes}m</td>
                <td>{c.rpoMinutes}m</td>
                <td>{c.status}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <h2 style={{ fontSize: 16 }}>Performance trends</h2>
      {dash.ops.performanceTrends.map((t) => (
        <div key={t.label} className="card" style={{ marginBottom: 8 }}>
          <strong>{t.label}</strong>
          <p className="mono">{t.values.join(" → ")}</p>
        </div>
      ))}

      <p style={{ marginTop: 24 }}>
        <Link className="btn" href="/portal/admin/ops-center">
          Back to Ops Center
        </Link>
      </p>
    </>
  );
}
