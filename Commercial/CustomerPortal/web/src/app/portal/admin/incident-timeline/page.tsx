import { auth } from "@/auth";
import { redirect } from "next/navigation";
import { StatusBadge } from "@/components/StatusBadge";
import { hasPermission } from "@/server/admin/roles";
import { ensureDemoIncidents, getIncidentTimeline } from "@/server/launch/incident-store";
import { actionUpdateIncidentTimeline } from "@/server/observability/actions";

export default async function IncidentTimelinePage() {
  const session = await auth();
  const role = (session?.user as { role?: string } | undefined)?.role;
  if (
    !hasPermission(role, "admin.observability.read") &&
    !hasPermission(role, "admin.launch.read")
  ) {
    redirect("/portal/admin");
  }

  ensureDemoIncidents();
  const timeline = getIncidentTimeline();
  const canWrite =
    hasPermission(role, "admin.observability.write") ||
    hasPermission(role, "admin.launch.write");

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Incident Timeline</h1>
        <p className="page-sub">
          Central chronology · Timestamp · Environment · Severity · Service · Impact · Root Cause · Resolution · Owner
        </p>
      </header>

      <div className="stack">
        {timeline.map((item) => (
          <div className="card" key={item.id}>
            <div style={{ display: "flex", flexWrap: "wrap", gap: 8, alignItems: "center" }}>
              <strong>{item.title}</strong>
              <StatusBadge status={item.severity} />
              <StatusBadge status={item.status} />
              <span className="meta">{item.timestamp}</span>
            </div>
            <p className="meta">
              Env: {item.environment} · Service: {item.affectedService} · Owner: {item.owner}
            </p>
            <p>
              <strong>Impact:</strong> {item.impact}
            </p>
            <p>
              <strong>Root cause:</strong> {item.rootCause}
            </p>
            <p>
              <strong>Resolution:</strong> {item.resolution}
            </p>
            <ul className="meta">
              {item.events.map((e, idx) => (
                <li key={`${item.id}-${idx}`}>
                  {e.at} · {e.by}: {e.note}
                </li>
              ))}
            </ul>
            {canWrite && (
              <form action={actionUpdateIncidentTimeline} className="stack" style={{ marginTop: 8 }}>
                <input type="hidden" name="id" value={item.id} />
                <div className="field">
                  <label>Environment</label>
                  <input name="environment" defaultValue={item.environment} />
                </div>
                <div className="field">
                  <label>Root cause</label>
                  <input name="rootCause" defaultValue={item.rootCause === "—" ? "" : item.rootCause} />
                </div>
                <div className="field">
                  <label>Resolution</label>
                  <input name="resolution" defaultValue={item.resolution === "—" ? "" : item.resolution} />
                </div>
                <div className="field">
                  <label>Owner</label>
                  <input name="owner" defaultValue={item.owner} />
                </div>
                <div className="field">
                  <label>Status</label>
                  <select name="status" defaultValue={item.status}>
                    <option value="open">Open</option>
                    <option value="investigating">Investigating</option>
                    <option value="mitigated">Mitigated</option>
                    <option value="resolved">Resolved</option>
                    <option value="closed">Closed</option>
                  </select>
                </div>
                <button type="submit" className="btn">
                  Update timeline
                </button>
              </form>
            )}
          </div>
        ))}
      </div>
    </>
  );
}
