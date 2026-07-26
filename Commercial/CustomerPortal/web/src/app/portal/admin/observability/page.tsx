import { auth } from "@/auth";
import { redirect } from "next/navigation";
import Link from "next/link";
import { StatusBadge } from "@/components/StatusBadge";
import { hasPermission } from "@/server/admin/roles";
import { getProductionHealthDashboard } from "@/server/observability/health-dashboard";

export default async function ObservabilityHealthPage() {
  const session = await auth();
  const role = (session?.user as { role?: string } | undefined)?.role;
  const actor = session?.user?.email?.toLowerCase() || "";
  if (
    !hasPermission(role, "admin.observability.read") &&
    !hasPermission(role, "admin.cloud.read") &&
    actor !== "admin@goldmind.local"
  ) {
    redirect("/portal/admin");
  }

  const dash = await getProductionHealthDashboard();

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Production Health Dashboard</h1>
        <p className="page-sub">
          Enterprise observability · overall <StatusBadge status={dash.overall} /> · uptime {dash.uptimeSec}s · Core{" "}
          {dash.isolation.coreTradingEngine}
        </p>
      </header>

      <div className="card" style={{ marginBottom: 16, borderLeft: "4px solid #166534" }}>
        {dash.isolation.statement}
      </div>

      <div className="grid grid-3" style={{ marginBottom: 16 }}>
        {dash.cards.map((c) => (
          <div className="card" key={c.id}>
            <h3>{c.label}</h3>
            <div className="value" style={{ fontSize: 18 }}>
              <StatusBadge status={c.status} />
            </div>
            <div className="meta">
              {c.latencyMs} ms · {c.detail || "—"}
            </div>
          </div>
        ))}
      </div>

      <div className="grid grid-3" style={{ marginBottom: 16 }}>
        <div className="card">
          <h3>Alerts firing</h3>
          <div className="value">{dash.alerts.firing}</div>
          <div className="meta">Critical: {dash.alerts.criticalFiring}</div>
        </div>
        <div className="card">
          <h3>Last alert eval</h3>
          <div className="value" style={{ fontSize: 16 }}>
            {dash.alertEval.evaluated} rules
          </div>
          <div className="meta">Fired: {dash.alertEval.fired.join(", ") || "none"}</div>
        </div>
        <div className="card">
          <h3>API response (avg)</h3>
          <div className="value">{dash.telemetry.apiResponseMs} ms</div>
        </div>
      </div>

      <div style={{ display: "flex", flexWrap: "wrap", gap: 8 }}>
        <Link className="btn btn-primary" href="/portal/admin/telemetry">
          Telemetry
        </Link>
        <Link className="btn" href="/portal/admin/usage">
          Usage Analytics
        </Link>
        <Link className="btn" href="/portal/admin/alerts">
          Alerts
        </Link>
        <Link className="btn" href="/portal/admin/ops-intelligence">
          Ops Intelligence
        </Link>
        <Link className="btn" href="/portal/admin/incident-timeline">
          Incident Timeline
        </Link>
      </div>
      <p className="meta" style={{ marginTop: 12 }}>
        Checked {dash.checkedAt}
      </p>
    </>
  );
}
