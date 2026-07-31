import { auth } from "@/auth";
import { redirect } from "next/navigation";
import Link from "next/link";
import { StatusBadge } from "@/components/StatusBadge";
import { hasPermission } from "@/server/admin/roles";
import { getExecutiveLaunchDashboard } from "@/server/launch/dashboard";
import { LAUNCH_ENVIRONMENTS } from "@/server/launch/environments";

export default async function ExecutiveLaunchDashboardPage() {
  const session = await auth();
  const role = (session?.user as { role?: string } | undefined)?.role;
  if (!hasPermission(role, "admin.launch.read")) {
    redirect("/portal/admin");
  }

  const dash = await getExecutiveLaunchDashboard();

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Executive Launch Dashboard</h1>
        <p className="page-sub">
          Controlled Public Launch · mode <strong>{dash.environmentName}</strong> · access{" "}
          {dash.customerAccess} · Core {dash.corePolicy}
        </p>
      </header>

      {!dash.publicStableGate.ok && (
        <div className="card" style={{ marginBottom: 16, borderLeft: "4px solid #b45309" }}>
          Public Stable is blocked. {dash.publicStableGate.reason}
        </div>
      )}

      <div className="grid grid-3" style={{ marginBottom: 16 }}>
        <div className="card">
          <h3>Beta Users (active)</h3>
          <div className="value">
            {dash.betaUsers} / {dash.betaTotal}
          </div>
          <div className="meta">Cap {dash.betaCap}</div>
        </div>
        <div className="card">
          <h3>Active Licenses</h3>
          <div className="value">{dash.activeLicenses}</div>
        </div>
        <div className="card">
          <h3>Install Success Rate</h3>
          <div className="value">{dash.installSuccessRate}%</div>
        </div>
        <div className="card">
          <h3>Activation Success Rate</h3>
          <div className="value">{dash.activationSuccessRate}%</div>
        </div>
        <div className="card">
          <h3>Crash Rate (portal proxy)</h3>
          <div className="value">{dash.crashRate}%</div>
          <div className="meta">Core crash telemetry not modified (frozen)</div>
        </div>
        <div className="card">
          <h3>Update Success Rate</h3>
          <div className="value">{dash.updateSuccessRate}%</div>
        </div>
        <div className="card">
          <h3>Support Tickets</h3>
          <div className="value">{dash.supportTicketsOpen}</div>
          <div className="meta">{dash.supportTicketsTotal} total</div>
        </div>
        <div className="card">
          <h3>Open Incidents</h3>
          <div className="value">{dash.openIncidents}</div>
          <div className="meta">Critical: {dash.criticalIncidents}</div>
        </div>
        <div className="card">
          <h3>System Health</h3>
          <div className="value" style={{ fontSize: 18 }}>
            <StatusBadge status={dash.systemHealth} />
          </div>
          <div className="meta">
            CSAT avg: {dash.feedbackAvgSatisfaction ?? "—"} · new feedback {dash.feedbackNew}
          </div>
        </div>
      </div>

      <h2 style={{ fontSize: 16 }}>Production monitoring domains</h2>
      <div className="table-wrap" style={{ marginBottom: 20 }}>
        <table className="data">
          <thead>
            <tr>
              <th>Domain</th>
              <th>Status</th>
              <th>Latency</th>
              <th>Detail</th>
            </tr>
          </thead>
          <tbody>
            {dash.domains.map((d) => (
              <tr key={d.domain}>
                <td>{d.label}</td>
                <td>
                  <StatusBadge status={d.status} />
                </td>
                <td>{d.latencyMs} ms</td>
                <td className="meta">{d.detail || "—"}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <h2 style={{ fontSize: 16 }}>Environments</h2>
      <div className="table-wrap" style={{ marginBottom: 20 }}>
        <table className="data">
          <thead>
            <tr>
              <th>Environment</th>
              <th>Access</th>
              <th>Payments</th>
              <th>Channel</th>
              <th>Active</th>
            </tr>
          </thead>
          <tbody>
            {LAUNCH_ENVIRONMENTS.map((e) => (
              <tr key={e.id}>
                <td>{e.name}</td>
                <td>{e.customerAccess}</td>
                <td>{e.paymentMode}</td>
                <td>{e.releaseChannel}</td>
                <td>{e.id === dash.launchMode ? "● current" : "—"}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <div style={{ display: "flex", flexWrap: "wrap", gap: 8 }}>
        <Link className="btn btn-primary" href="/portal/admin/beta">
          Beta Program
        </Link>
        <Link className="btn" href="/portal/admin/incidents">
          Incidents
        </Link>
        <Link className="btn" href="/portal/admin/feedback">
          Feedback
        </Link>
        <Link className="btn" href="/portal/admin/cloud">
          Cloud Health
        </Link>
      </div>
      <p className="meta" style={{ marginTop: 12 }}>
        Generated {dash.generatedAt}
      </p>
    </>
  );
}
