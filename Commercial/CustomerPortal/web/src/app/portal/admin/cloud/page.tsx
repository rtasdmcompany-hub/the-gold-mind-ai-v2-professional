import { auth } from "@/auth";
import { redirect } from "next/navigation";
import { StatusBadge } from "@/components/StatusBadge";
import { runHealthChecks } from "@/server/cloud/monitoring";
import { listCloudServices } from "@/server/cloud/services";
import { listAudit } from "@/server/cloud/audit";
import { getCacheBackend } from "@/server/cloud/cache";
import { getBackupPolicy, getMigrationPolicy } from "@/server/cloud/database";
import { hasPermission } from "@/server/admin/roles";

export default async function AdminCloudPage() {
  const session = await auth();
  const email = session?.user?.email?.toLowerCase() || "";
  const role = (session?.user as { role?: string } | undefined)?.role;
  if (!hasPermission(role, "admin.cloud.read") && email !== "admin@goldmind.local") redirect("/portal");

  const health = await runHealthChecks(true);
  const services = listCloudServices();
  const audits = listAudit(30);
  const backup = getBackupPolicy();
  const migration = getMigrationPolicy();

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Admin · Cloud Platform</h1>
        <p className="page-sub">
          API Gateway · services · health · cache · audit — commercial layer only. Trading Engine remains isolated.
        </p>
      </header>

      <div className="grid grid-3" style={{ marginBottom: 16 }}>
        <div className="card">
          <h3>System Health</h3>
          <div className="value" style={{ fontSize: 18 }}>
            <StatusBadge status={health.status} />
          </div>
          <div className="meta">Uptime {health.metrics.uptimeSec}s</div>
        </div>
        <div className="card">
          <h3>Cache Backend</h3>
          <div className="value" style={{ fontSize: 18 }}>
            {getCacheBackend()}
          </div>
          <div className="meta">Rate limit: {health.metrics.rateLimitBackend}</div>
        </div>
        <div className="card">
          <h3>Audit Entries</h3>
          <div className="value">{health.metrics.auditEntries}</div>
          <div className="meta">Encrypted audit store</div>
        </div>
      </div>

      <h2 style={{ fontSize: 16 }}>Service health</h2>
      <div className="table-wrap" style={{ marginBottom: 20 }}>
        <table className="data">
          <thead>
            <tr>
              <th>Service</th>
              <th>Status</th>
              <th>Latency</th>
              <th>Detail</th>
            </tr>
          </thead>
          <tbody>
            {health.services.map((s) => (
              <tr key={s.id}>
                <td>{s.name}</td>
                <td>
                  <StatusBadge status={s.status} />
                </td>
                <td>{s.latencyMs} ms</td>
                <td className="meta">{s.detail || "—"}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <h2 style={{ fontSize: 16 }}>Independently deployable services</h2>
      <div className="table-wrap" style={{ marginBottom: 20 }}>
        <table className="data">
          <thead>
            <tr>
              <th>Service</th>
              <th>Base path</th>
              <th>Depends on</th>
              <th>TE coupled</th>
            </tr>
          </thead>
          <tbody>
            {services.map((s) => (
              <tr key={s.id}>
                <td>{s.name}</td>
                <td className="mono">{s.basePath}</td>
                <td>{s.dependsOn.join(", ") || "—"}</td>
                <td>{s.tradingEngineCoupled ? "yes" : "no"}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <h2 style={{ fontSize: 16 }}>Database / persistence policy</h2>
      <div className="card" style={{ marginBottom: 20 }}>
        <div className="meta">Backup: {backup.frequency} · retention {backup.retentionDays}d · {backup.encryption}</div>
        <div className="meta">Targets: {backup.targets.join(", ")}</div>
        <div className="meta">
          Migration: {migration.strategy} · backup required · TE freeze: {String(migration.freezeTradingEngine)}
        </div>
        <div className="meta">{migration.note}</div>
      </div>

      <h2 style={{ fontSize: 16 }}>Recent audit log</h2>
      <div className="table-wrap">
        <table className="data">
          <thead>
            <tr>
              <th>When</th>
              <th>User</th>
              <th>Action</th>
              <th>IP</th>
              <th>Result</th>
              <th>Detail</th>
            </tr>
          </thead>
          <tbody>
            {audits.length === 0 && (
              <tr>
                <td colSpan={6}>No audit entries yet.</td>
              </tr>
            )}
            {audits.map((a) => (
              <tr key={a.id}>
                <td>{a.at.slice(0, 19).replace("T", " ")}</td>
                <td>{a.user}</td>
                <td className="mono">{a.action}</td>
                <td className="mono">{a.ip}</td>
                <td>
                  <StatusBadge status={a.result} />
                </td>
                <td>{a.detail || "—"}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <p className="meta" style={{ marginTop: 16 }}>
        Public health: <a href="/api/health">/api/health</a> · detailed{" "}
        <a href="/api/health?detailed=1">/api/health?detailed=1</a>
      </p>
    </>
  );
}
