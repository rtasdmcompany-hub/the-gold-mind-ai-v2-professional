import { auth } from "@/auth";
import { redirect } from "next/navigation";
import Link from "next/link";
import { hasPermission } from "@/server/admin/roles";
import { isDevAdminBypass } from "@/server/security/dev-bypass";
import { getPhase11Sprint8Dashboard } from "@/server/api-platform/suite";
import { readApiStore } from "@/server/api-platform/store";

export default async function ApiWebhooksAdminPage() {
  const session = await auth();
  const role = (session?.user as { role?: string } | undefined)?.role;
  const actor = session?.user?.email?.toLowerCase() || "";
  if (!hasPermission(role, "admin.launch.read") && !isDevAdminBypass(actor)) {
    redirect("/portal/admin");
  }
  const dash = await getPhase11Sprint8Dashboard();
  const store = readApiStore();
  const hooks = store.webhooks.slice(0, 50);
  const deliveries = store.deliveries.slice(0, 30);

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">API Webhooks</h1>
        <p className="page-sub">Signing · retries · commercial events only</p>
      </header>

      <div className="card" style={{ marginBottom: 16 }}>
        Events: {dash.webhooks.events.join(", ")}
        <br />
        Retry max: {dash.webhooks.retryPolicy.maxAttempts} · Suite deliveries: {dash.deliveries}
      </div>

      <h2 style={{ fontSize: 16 }}>Endpoints</h2>
      <div className="table-wrap" style={{ marginBottom: 16 }}>
        <table className="data">
          <thead>
            <tr>
              <th>URL</th>
              <th>Events</th>
              <th>Active</th>
              <th>Failures</th>
            </tr>
          </thead>
          <tbody>
            {hooks.map((h) => (
              <tr key={h.id}>
                <td className="mono">{h.url}</td>
                <td>{h.events.join(", ")}</td>
                <td>{h.active ? "yes" : "no"}</td>
                <td>{h.failureCount}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <h2 style={{ fontSize: 16 }}>Recent deliveries</h2>
      <div className="table-wrap">
        <table className="data">
          <thead>
            <tr>
              <th>Event</th>
              <th>Status</th>
              <th>Attempts</th>
              <th>At</th>
            </tr>
          </thead>
          <tbody>
            {deliveries.map((d) => (
              <tr key={d.id}>
                <td>{d.event}</td>
                <td>{d.status}</td>
                <td>{d.attempts}</td>
                <td>{d.createdAt.slice(0, 19)}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <p style={{ marginTop: 24 }}>
        <Link className="btn" href="/portal/admin/api-platform">
          Back to API Platform
        </Link>
      </p>
    </>
  );
}
