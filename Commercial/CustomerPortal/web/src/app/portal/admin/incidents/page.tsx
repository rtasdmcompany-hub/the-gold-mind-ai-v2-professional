import { auth } from "@/auth";
import { redirect } from "next/navigation";
import { StatusBadge } from "@/components/StatusBadge";
import { hasPermission } from "@/server/admin/roles";
import {
  SEVERITY_SLA,
  ensureDemoIncidents,
  getIncidentSummary,
  listIncidents,
  type IncidentSeverity,
  type IncidentStatus,
} from "@/server/launch/incident-store";
import { actionCreateIncident, actionUpdateIncident } from "@/server/launch/actions";

export default async function AdminIncidentsPage({
  searchParams,
}: {
  searchParams: Promise<{ severity?: string; status?: string; q?: string }>;
}) {
  const session = await auth();
  const role = (session?.user as { role?: string } | undefined)?.role;
  if (!hasPermission(role, "admin.launch.read")) {
    redirect("/portal/admin");
  }

  ensureDemoIncidents();
  const sp = await searchParams;
  const incidents = listIncidents({
    severity: sp.severity as IncidentSeverity | undefined,
    status: sp.status as IncidentStatus | undefined,
    q: sp.q,
  });
  const summary = getIncidentSummary();
  const canWrite = hasPermission(role, "admin.launch.write");

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Incident Management</h1>
        <p className="page-sub">
          Commercial production incidents only · Core Trading Engine changes forbidden · Open: {summary.open} ·
          Critical open: {summary.criticalOpen}
        </p>
      </header>

      <div className="card" style={{ marginBottom: 16 }}>
        <h3>Severity SLA (ack / update / resolve)</h3>
        <div className="table-wrap" style={{ marginTop: 8 }}>
          <table className="data">
            <thead>
              <tr>
                <th>Severity</th>
                <th>Ack</th>
                <th>Updates</th>
                <th>Target resolve</th>
                <th>Escalate</th>
              </tr>
            </thead>
            <tbody>
              {(Object.keys(SEVERITY_SLA) as IncidentSeverity[]).map((sev) => (
                <tr key={sev}>
                  <td>{sev}</td>
                  <td>{SEVERITY_SLA[sev].ackMinutes}m</td>
                  <td>every {SEVERITY_SLA[sev].updateMinutes}m</td>
                  <td>{SEVERITY_SLA[sev].targetResolveHours}h</td>
                  <td className="meta">{SEVERITY_SLA[sev].escalateTo}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {canWrite && (
        <form action={actionCreateIncident} className="card" style={{ marginBottom: 16 }}>
          <h3>Open incident</h3>
          <div className="stack" style={{ marginTop: 8 }}>
            <div className="field">
              <label htmlFor="title">Title</label>
              <input id="title" name="title" required />
            </div>
            <div className="field">
              <label htmlFor="severity">Severity</label>
              <select id="severity" name="severity" defaultValue="medium">
                <option value="critical">Critical</option>
                <option value="high">High</option>
                <option value="medium">Medium</option>
                <option value="low">Low</option>
              </select>
            </div>
            <div className="field">
              <label htmlFor="summary">Summary</label>
              <textarea id="summary" name="summary" rows={2} required />
            </div>
            <div className="field">
              <label htmlFor="impact">Impact</label>
              <textarea id="impact" name="impact" rows={2} />
            </div>
            <div className="field">
              <label htmlFor="services">Affected services (comma-separated)</label>
              <input id="services" name="services" placeholder="portal, payments, license" />
            </div>
            <label>
              <input type="checkbox" name="hotfix" value="1" /> Emergency hotfix required
            </label>
            <label>
              <input type="checkbox" name="rollback" value="1" /> Rollback required
            </label>
            <button type="submit" className="btn btn-primary">
              Open incident
            </button>
          </div>
        </form>
      )}

      <form className="card" method="get" style={{ marginBottom: 16, display: "flex", flexWrap: "wrap", gap: 12 }}>
        <div className="field">
          <label htmlFor="q">Search</label>
          <input id="q" name="q" defaultValue={sp.q || ""} />
        </div>
        <div className="field">
          <label htmlFor="severityFilter">Severity</label>
          <select id="severityFilter" name="severity" defaultValue={sp.severity || ""}>
            <option value="">All</option>
            <option value="critical">Critical</option>
            <option value="high">High</option>
            <option value="medium">Medium</option>
            <option value="low">Low</option>
          </select>
        </div>
        <div className="field">
          <label htmlFor="status">Status</label>
          <select id="status" name="status" defaultValue={sp.status || ""}>
            <option value="">All</option>
            <option value="open">Open</option>
            <option value="investigating">Investigating</option>
            <option value="mitigated">Mitigated</option>
            <option value="resolved">Resolved</option>
            <option value="closed">Closed</option>
          </select>
        </div>
        <button type="submit" className="btn btn-primary" style={{ alignSelf: "flex-end" }}>
          Filter
        </button>
      </form>

      <div className="stack">
        {incidents.map((inc) => (
          <div className="card" key={inc.id}>
            <div style={{ display: "flex", flexWrap: "wrap", gap: 8, alignItems: "center" }}>
              <strong>{inc.title}</strong>
              <StatusBadge status={inc.severity} />
              <StatusBadge status={inc.status} />
              <span className="meta">{inc.id}</span>
            </div>
            <p className="meta">{inc.summary}</p>
            <p className="meta">
              Impact: {inc.impact} · Services: {inc.affectedServices.join(", ")} · Commander: {inc.commander}
            </p>
            <p className="meta">
              Hotfix: {inc.hotfixRequired ? "yes" : "no"} · Rollback: {inc.rollbackRequired ? "yes" : "no"} ·
              Customer notified: {inc.customerNotified ? "yes" : "no"}
            </p>
            {canWrite && (
              <form action={actionUpdateIncident} style={{ display: "flex", flexWrap: "wrap", gap: 8, marginTop: 8 }}>
                <input type="hidden" name="id" value={inc.id} />
                <select name="status" defaultValue={inc.status}>
                  <option value="open">Open</option>
                  <option value="investigating">Investigating</option>
                  <option value="mitigated">Mitigated</option>
                  <option value="resolved">Resolved</option>
                  <option value="closed">Closed</option>
                </select>
                <label>
                  <input type="checkbox" name="customerNotified" value="1" defaultChecked={inc.customerNotified} />{" "}
                  Customer notified
                </label>
                <input name="note" placeholder="Timeline note" />
                <button type="submit" className="btn">
                  Update
                </button>
              </form>
            )}
          </div>
        ))}
      </div>
    </>
  );
}
