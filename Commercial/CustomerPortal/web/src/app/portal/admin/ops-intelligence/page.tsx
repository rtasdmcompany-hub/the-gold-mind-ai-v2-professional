import { auth } from "@/auth";
import { redirect } from "next/navigation";
import { StatusBadge } from "@/components/StatusBadge";
import { hasPermission } from "@/server/admin/roles";
import { getOpsIntelligenceDashboard } from "@/server/observability/ops-intelligence";

export default async function OpsIntelligencePage() {
  const session = await auth();
  const role = (session?.user as { role?: string } | undefined)?.role;
  if (!hasPermission(role, "admin.observability.read")) {
    redirect("/portal/admin");
  }

  const dash = await getOpsIntelligenceDashboard();

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Operational Intelligence</h1>
        <p className="page-sub">
          Executive commercial KPIs · Core {dash.corePolicy} · launch {dash.deploymentStatus.launchMode}
        </p>
      </header>

      <div className="grid grid-3" style={{ marginBottom: 16 }}>
        <div className="card">
          <h3>System Uptime</h3>
          <div className="value">{dash.systemUptime.percentProxy}%</div>
          <div className="meta">
            process {dash.systemUptime.seconds}s · <StatusBadge status={dash.systemUptime.health} />
          </div>
        </div>
        <div className="card">
          <h3>Customer Growth</h3>
          <div className="value">{dash.customerGrowth.activeCustomers}</div>
          <div className="meta">
            DAU {dash.customerGrowth.dau} · WAU {dash.customerGrowth.wau} · MAU {dash.customerGrowth.mau} · ret{" "}
            {dash.customerGrowth.retention}%
          </div>
        </div>
        <div className="card">
          <h3>License Growth</h3>
          <div className="value">{dash.licenseGrowth.activeLicenses}</div>
          <div className="meta">
            activation {dash.licenseGrowth.activationRate}% · today {dash.licenseGrowth.activationsToday}
          </div>
        </div>
        <div className="card">
          <h3>Subscription Growth</h3>
          <div className="value">{dash.subscriptionGrowth.active}</div>
          <div className="meta">renewal {dash.subscriptionGrowth.renewalRate}%</div>
        </div>
        <div className="card">
          <h3>Support Ticket Trend</h3>
          <div className="value">{dash.supportTicketTrend.find((x) => x.label === "open")?.value ?? 0}</div>
          <div className="meta">
            total {dash.supportTicketTrend.find((x) => x.label === "total")?.value ?? 0}
          </div>
        </div>
        <div className="card">
          <h3>Crash Trend</h3>
          <div className="value">{dash.crashTrend[0]?.value ?? 0}%</div>
          <div className="meta">portal proxy</div>
        </div>
        <div className="card">
          <h3>Alerts Firing</h3>
          <div className="value">{dash.alertsFiring}</div>
        </div>
        <div className="card">
          <h3>Deployment Status</h3>
          <div className="value" style={{ fontSize: 16 }}>
            {dash.deploymentStatus.latest?.version || "—"}
          </div>
          <div className="meta">
            {dash.deploymentStatus.channel} · rollbacks {dash.deploymentStatus.rollbackEvents}
          </div>
        </div>
      </div>

      <h2 style={{ fontSize: 16 }}>Revenue trend</h2>
      <div className="table-wrap" style={{ marginBottom: 16 }}>
        <table className="data">
          <thead>
            <tr>
              <th>Month</th>
              <th>Revenue</th>
            </tr>
          </thead>
          <tbody>
            {dash.revenueTrend.length === 0 && (
              <tr>
                <td colSpan={2}>No revenue data yet</td>
              </tr>
            )}
            {dash.revenueTrend.map((r) => (
              <tr key={r.month}>
                <td>{r.month}</td>
                <td>{r.formatted}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <h2 style={{ fontSize: 16 }}>Performance trend</h2>
      <div className="table-wrap">
        <table className="data">
          <thead>
            <tr>
              <th>Metric</th>
              <th>Value</th>
            </tr>
          </thead>
          <tbody>
            {dash.performanceTrend.map((p) => (
              <tr key={p.label}>
                <td>{p.label}</td>
                <td>{p.value}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <p className="meta" style={{ marginTop: 12 }}>
        Generated {dash.generatedAt}
      </p>
    </>
  );
}
