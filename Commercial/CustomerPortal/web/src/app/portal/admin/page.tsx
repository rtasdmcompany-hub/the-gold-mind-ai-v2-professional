import { auth } from "@/auth";
import { StatusBadge } from "@/components/StatusBadge";
import { redirect } from "next/navigation";
import Link from "next/link";
import { canAccessAdminConsole, hasPermission } from "@/server/admin/roles";
import { getEnterpriseDashboardWithHealth } from "@/server/admin/ops";
import { ensureDemoTickets } from "@/server/admin/support-store";
import { ensureSeedData } from "@/server/licensing/seed";

export default async function AdminOperationsHub() {
  ensureSeedData();
  ensureDemoTickets();
  const session = await auth();
  const email = session?.user?.email?.toLowerCase() || "";
  const role = (session?.user as { role?: string } | undefined)?.role;
  if (!canAccessAdminConsole(role) && email !== "admin@goldmind.local") redirect("/portal");

  const dash = await getEnterpriseDashboardWithHealth();

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Enterprise Operations Hub</h1>
        <p className="page-sub">
          RTAS commercial operations center — customers · licenses · revenue · support · health. Never touches Trading
          Engine.
        </p>
      </header>

      <div className="grid grid-3" style={{ marginBottom: 16 }}>
        <div className="card">
          <h3>Active Customers</h3>
          <div className="value">{dash.activeCustomers}</div>
        </div>
        <div className="card">
          <h3>Active Licenses</h3>
          <div className="value">{dash.activeLicenses}</div>
        </div>
        <div className="card">
          <h3>Subscriptions</h3>
          <div className="value">{dash.subscriptions}</div>
        </div>
        <div className="card">
          <h3>Revenue Overview</h3>
          <div className="value" style={{ fontSize: 18 }}>
            {dash.revenueOverview}
          </div>
        </div>
        <div className="card">
          <h3>Daily Activations</h3>
          <div className="value">{dash.dailyActivations}</div>
        </div>
        <div className="card">
          <h3>New Registrations</h3>
          <div className="value">{dash.newRegistrations}</div>
        </div>
        <div className="card">
          <h3>Support Tickets</h3>
          <div className="value">{dash.supportTicketsOpen}</div>
          <div className="meta">Open / pending · {dash.supportTicketsTotal} total</div>
        </div>
        <div className="card">
          <h3>Latest Release</h3>
          <div className="value" style={{ fontSize: 18 }}>
            {dash.latestRelease?.version || "—"}
          </div>
          <div className="meta">
            {dash.latestRelease ? `${dash.latestRelease.channel} · build ${dash.latestRelease.build}` : "—"}
          </div>
        </div>
        <div className="card">
          <h3>System Health</h3>
          <div className="value" style={{ fontSize: 18 }}>
            <StatusBadge status={dash.systemHealth} />
          </div>
          <div className="meta">Platform: {dash.platformStatus}</div>
        </div>
      </div>

      <h2 style={{ fontSize: 16 }}>Platform status</h2>
      <div className="table-wrap" style={{ marginBottom: 20 }}>
        <table className="data">
          <thead>
            <tr>
              <th>Service</th>
              <th>Status</th>
              <th>Latency</th>
            </tr>
          </thead>
          <tbody>
            {dash.healthServices.map((s) => (
              <tr key={s.id}>
                <td>{s.name}</td>
                <td>
                  <StatusBadge status={s.status} />
                </td>
                <td>{s.latencyMs} ms</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <div style={{ display: "flex", flexWrap: "wrap", gap: 8 }}>
        {hasPermission(role, "admin.customers.read") && (
          <Link className="btn btn-primary" href="/portal/admin/customers">
            Customer Management
          </Link>
        )}
        {hasPermission(role, "admin.bi.read") && (
          <Link className="btn" href="/portal/admin/bi">
            Business Intelligence
          </Link>
        )}
        {hasPermission(role, "admin.audit.read") && (
          <Link className="btn" href="/portal/admin/audit">
            Audit Center
          </Link>
        )}
      </div>
    </>
  );
}
