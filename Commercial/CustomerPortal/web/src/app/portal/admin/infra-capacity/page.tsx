import { auth } from "@/auth";
import { redirect } from "next/navigation";
import Link from "next/link";
import { hasPermission } from "@/server/admin/roles";
import { isDevAdminBypass } from "@/server/security/dev-bypass";
import { getPhase11Sprint9Dashboard } from "@/server/infrastructure/suite";

export default async function InfraCapacityPage() {
  const session = await auth();
  const role = (session?.user as { role?: string } | undefined)?.role;
  const actor = session?.user?.email?.toLowerCase() || "";
  if (!hasPermission(role, "admin.launch.read") && !isDevAdminBypass(actor)) {
    redirect("/portal/admin");
  }
  const dash = await getPhase11Sprint9Dashboard();
  const cap = dash.ops.infrastructureCapacity;

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Infrastructure Capacity</h1>
        <p className="page-sub">Headroom · scale tiers · spend forecast</p>
      </header>

      <div className="grid grid-3" style={{ marginBottom: 16 }}>
        <div className="card">
          <h3>Portal concurrency headroom</h3>
          <div className="value">{cap.portalConcurrencyHeadroomPct}%</div>
        </div>
        <div className="card">
          <h3>DB connections used</h3>
          <div className="value">{cap.dbConnectionsUsedPct}%</div>
        </div>
        <div className="card">
          <h3>Redis memory used</h3>
          <div className="value">{cap.redisMemoryUsedPct}%</div>
        </div>
        <div className="card">
          <h3>Storage used</h3>
          <div className="value">{cap.storageUsedPct}%</div>
        </div>
        <div className="card">
          <h3>API rate-limit headroom</h3>
          <div className="value">{cap.apiRateLimitHeadroomPct}%</div>
        </div>
        <div className="card">
          <h3>Next-quarter forecast</h3>
          <div className="value">${dash.ops.cloudSpend.forecastUsd}</div>
        </div>
      </div>

      <h2 style={{ fontSize: 16 }}>Scale tiers</h2>
      <div className="table-wrap" style={{ marginBottom: 16 }}>
        <table className="data">
          <thead>
            <tr>
              <th>Tier</th>
              <th>Users</th>
              <th>Monthly USD</th>
              <th>Upgrades</th>
            </tr>
          </thead>
          <tbody>
            {dash.scale.plans.map((p) => (
              <tr key={p.tier}>
                <td>{p.tier}</td>
                <td>{p.users.toLocaleString()}</td>
                <td>
                  ${p.estimatedMonthlyUsd.low}–${p.estimatedMonthlyUsd.high}
                </td>
                <td>{p.upgrades.join("; ")}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <h2 style={{ fontSize: 16 }}>Components</h2>
      <div className="table-wrap" style={{ marginBottom: 16 }}>
        <table className="data">
          <thead>
            <tr>
              <th>Name</th>
              <th>Status</th>
              <th>HA</th>
              <th>Role</th>
            </tr>
          </thead>
          <tbody>
            {dash.infra.items.map((i) => (
              <tr key={i.id}>
                <td>{i.name}</td>
                <td>{i.status}</td>
                <td>{i.haEnabled ? "yes" : "no"}</td>
                <td>{i.role}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <h2 style={{ fontSize: 16 }}>Scaling events</h2>
      <div className="table-wrap">
        <table className="data">
          <thead>
            <tr>
              <th>Tier</th>
              <th>Note</th>
              <th>At</th>
            </tr>
          </thead>
          <tbody>
            {dash.ops.scalingEvents.map((e) => (
              <tr key={e.id}>
                <td>{e.tier}</td>
                <td>{e.note}</td>
                <td>{e.at.slice(0, 19)}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <p style={{ marginTop: 24 }}>
        <Link className="btn" href="/portal/admin/ops-center">
          Back to Ops Center
        </Link>
      </p>
    </>
  );
}
