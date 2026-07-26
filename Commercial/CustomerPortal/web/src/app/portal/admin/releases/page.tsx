import { auth } from "@/auth";
import { getAdminReleaseDashboard, formatBytes } from "@/server/releases/admin-view";
import { redirect } from "next/navigation";
import { StatusBadge } from "@/components/StatusBadge";
import { hasPermission } from "@/server/admin/roles";

export default async function AdminReleasesPage() {
  const session = await auth();
  const email = session?.user?.email?.toLowerCase() || "";
  const role = (session?.user as { role?: string } | undefined)?.role;
  if (!hasPermission(role, "admin.releases.read") && email !== "admin@goldmind.local") redirect("/portal");

  const dash = getAdminReleaseDashboard();

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Admin · Release Management</h1>
        <p className="page-sub">
          Stable / RC / Development · package size · build · downloads · success rate · rollback events
        </p>
      </header>

      <div className="grid grid-3" style={{ marginBottom: 16 }}>
        <div className="card">
          <h3>Latest Release</h3>
          <div className="value" style={{ fontSize: 18 }}>
            {dash.latestRelease?.version || "—"}
          </div>
          <div className="meta">Build {dash.latestRelease?.buildNumber}</div>
          <div className="meta">{dash.latestRelease?.releasedAt.slice(0, 10)}</div>
          <div className="meta">Status: {dash.latestRelease?.status}</div>
        </div>
        <div className="card">
          <h3>Download Count</h3>
          <div className="value">{dash.totalDownloads}</div>
          <div className="meta">
            Latest size: {dash.latestRelease ? formatBytes(dash.latestRelease.packageSizeBytes) : "—"}
          </div>
        </div>
        <div className="card">
          <h3>Update Success Rate</h3>
          <div className="value">{dash.updateSuccessRate}%</div>
          <div className="meta">Rollback events: {dash.rollbackEvents}</div>
        </div>
      </div>

      <h2 style={{ fontSize: 16 }}>Packages</h2>
      <div className="table-wrap" style={{ marginBottom: 20 }}>
        <table className="data">
          <thead>
            <tr>
              <th>Version</th>
              <th>Channel</th>
              <th>Build</th>
              <th>Released</th>
              <th>Size</th>
              <th>Status</th>
              <th>Downloads</th>
              <th>Success</th>
              <th>Fail</th>
              <th>Rollbacks</th>
            </tr>
          </thead>
          <tbody>
            {dash.packages.map((p) => (
              <tr key={p.id}>
                <td>{p.version}</td>
                <td>{p.channel}</td>
                <td>{p.buildNumber}</td>
                <td>{p.releasedAt.slice(0, 10)}</td>
                <td>{formatBytes(p.packageSizeBytes)}</td>
                <td>
                  <StatusBadge status={p.status} />
                </td>
                <td>{p.downloadCount}</td>
                <td>{p.updateSuccessCount}</td>
                <td>{p.updateFailCount}</td>
                <td>{p.rollbackEvents}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <h2 style={{ fontSize: 16 }}>Compatibility matrix</h2>
      <div className="table-wrap" style={{ marginBottom: 20 }}>
        <table className="data">
          <thead>
            <tr>
              <th>Version</th>
              <th>Channel</th>
              <th>OS</th>
              <th>MT5</th>
              <th>Core tag</th>
              <th>Frozen</th>
            </tr>
          </thead>
          <tbody>
            {dash.compatibilityMatrix.map((m) => (
              <tr key={`m-${m.channel}-${m.version}`}>
                <td>{m.version}</td>
                <td>{m.channel}</td>
                <td>{m.os.join(", ")}</td>
                <td>{m.mt5}</td>
                <td>{m.coreTag}</td>
                <td>{m.coreFrozen ? "yes" : "no"}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <h2 style={{ fontSize: 16 }}>Previous releases</h2>
      <div className="table-wrap" style={{ marginBottom: 20 }}>
        <table className="data">
          <thead>
            <tr>
              <th>Version</th>
              <th>Channel</th>
              <th>Released</th>
              <th>Notes</th>
            </tr>
          </thead>
          <tbody>
            {dash.previousReleases.map((p) => (
              <tr key={p.id}>
                <td>{p.version}</td>
                <td>{p.channel}</td>
                <td>{p.releasedAt.slice(0, 10)}</td>
                <td>{p.releaseNotes}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <h2 style={{ fontSize: 16 }}>Rollback / update events</h2>
      <div className="table-wrap">
        <table className="data">
          <thead>
            <tr>
              <th>When</th>
              <th>From → To</th>
              <th>Channel</th>
              <th>Result</th>
              <th>Detail</th>
            </tr>
          </thead>
          <tbody>
            {dash.recentUpdateEvents.length === 0 && (
              <tr>
                <td colSpan={5}>No events yet — run the updater with -Apply to populate.</td>
              </tr>
            )}
            {dash.recentUpdateEvents.map((e) => (
              <tr key={e.id}>
                <td>{e.at.slice(0, 19).replace("T", " ")}</td>
                <td>
                  {e.fromVersion} → {e.toVersion}
                </td>
                <td>{e.channel}</td>
                <td>
                  <StatusBadge status={e.result} />
                </td>
                <td>{e.detail}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </>
  );
}
