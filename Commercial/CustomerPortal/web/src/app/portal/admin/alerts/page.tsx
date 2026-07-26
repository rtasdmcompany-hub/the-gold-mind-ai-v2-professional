import { auth } from "@/auth";
import { redirect } from "next/navigation";
import { StatusBadge } from "@/components/StatusBadge";
import { hasPermission } from "@/server/admin/roles";
import { getAlertSummary, listAlertRules, listAlerts } from "@/server/observability/alert-store";
import {
  actionEvaluateAlerts,
  actionToggleAlertRule,
  actionUpdateAlert,
} from "@/server/observability/actions";

export default async function AlertsPage() {
  const session = await auth();
  const role = (session?.user as { role?: string } | undefined)?.role;
  const actor = session?.user?.email?.toLowerCase() || "";
  if (!hasPermission(role, "admin.observability.read") && actor !== "admin@goldmind.local") {
    redirect("/portal/admin");
  }

  const rules = listAlertRules();
  const alerts = listAlerts();
  const summary = getAlertSummary();
  const canWrite = hasPermission(role, "admin.observability.write") || actor === "admin@goldmind.local";

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Alerting System</h1>
        <p className="page-sub">
          Critical / High / Medium / Low · firing {summary.firing} · critical {summary.criticalFiring}
        </p>
      </header>

      {canWrite && (
        <form action={actionEvaluateAlerts} style={{ marginBottom: 16 }}>
          <button type="submit" className="btn btn-primary">
            Evaluate alerts now
          </button>
        </form>
      )}

      <h2 style={{ fontSize: 16 }}>Rules</h2>
      <div className="table-wrap" style={{ marginBottom: 20 }}>
        <table className="data">
          <thead>
            <tr>
              <th>Rule</th>
              <th>Severity</th>
              <th>Threshold</th>
              <th>Enabled</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            {rules.map((r) => (
              <tr key={r.id}>
                <td>
                  <strong>{r.name}</strong>
                  <div className="meta">{r.description}</div>
                </td>
                <td>
                  <StatusBadge status={r.severity} />
                </td>
                <td>
                  <code>{r.threshold}</code>
                </td>
                <td>{r.enabled ? "yes" : "no"}</td>
                <td>
                  {canWrite && (
                    <form action={actionToggleAlertRule}>
                      <input type="hidden" name="ruleId" value={r.id} />
                      <input type="hidden" name="enabled" value={r.enabled ? "0" : "1"} />
                      <button type="submit" className="btn">
                        {r.enabled ? "Disable" : "Enable"}
                      </button>
                    </form>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <h2 style={{ fontSize: 16 }}>Alert events</h2>
      <div className="stack">
        {alerts.length === 0 && <p className="meta">No alerts fired yet — run evaluation after health changes.</p>}
        {alerts.map((a) => (
          <div className="card" key={a.id}>
            <div style={{ display: "flex", flexWrap: "wrap", gap: 8, alignItems: "center" }}>
              <strong>{a.title}</strong>
              <StatusBadge status={a.severity} />
              <StatusBadge status={a.status} />
              <span className="meta">{a.firedAt}</span>
            </div>
            <p className="meta">{a.detail}</p>
            {canWrite && a.status !== "resolved" && (
              <form action={actionUpdateAlert} style={{ display: "flex", gap: 8, marginTop: 8 }}>
                <input type="hidden" name="id" value={a.id} />
                <select name="status" defaultValue={a.status}>
                  <option value="firing">Firing</option>
                  <option value="acknowledged">Acknowledged</option>
                  <option value="resolved">Resolved</option>
                </select>
                <input name="owner" placeholder="Owner" defaultValue={a.owner || actor} />
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
