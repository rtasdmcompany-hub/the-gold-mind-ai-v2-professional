import { auth } from "@/auth";
import {
  listPublished,
  getReportedInstalledVersion,
  getCompatibilityMatrix,
} from "@/server/releases/release-service";
import { readReleaseStore } from "@/server/releases/store";
import { redirect } from "next/navigation";
import Link from "next/link";

export default async function DownloadsPage() {
  const session = await auth();
  if (!session?.user?.email) redirect("/login");
  const packages = listPublished();
  const email = session.user.email.toLowerCase();
  const history = readReleaseStore()
    .downloadEvents.filter((d) => d.email?.toLowerCase() === email)
    .slice(0, 20);
  const updateHistory = readReleaseStore()
    .updateEvents.filter(
      (e) => e.email?.toLowerCase() === email && (e.result === "success" || e.result === "rollback")
    )
    .slice(0, 15);
  const latest = listPublished("stable")[0];
  const installed = getReportedInstalledVersion(email);
  const matrix = getCompatibilityMatrix();

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Downloads</h1>
        <p className="page-sub">
          Installer packages · checksums · digital signatures ·{" "}
          <Link href="/portal/updates">Update center</Link>
        </p>
      </header>

      <div className="grid grid-3" style={{ marginBottom: 16 }}>
        <div className="card">
          <h3>Latest Version</h3>
          <div className="value" style={{ fontSize: 18 }}>
            {latest?.version || "—"}
          </div>
          <div className="meta">Build {latest?.buildNumber} · {latest?.channel}</div>
        </div>
        <div className="card">
          <h3>Installed Version</h3>
          <div className="value" style={{ fontSize: 18 }}>
            {installed || "Not reported"}
          </div>
          <div className="meta">
            {installed
              ? "From updater telemetry"
              : "Run Update-TheGoldMindProfessional.ps1 -Apply after install"}
          </div>
        </div>
        <div className="card">
          <h3>System Requirements</h3>
          <div className="meta">{latest?.compatibility.os.join(", ")}</div>
          <div className="meta">MT5 {latest?.compatibility.mt5}</div>
          <div className="meta">Core tag {latest?.compatibility.coreTag} (frozen)</div>
        </div>
      </div>

      <h2 style={{ fontSize: 16, margin: "0 0 10px" }}>Available installers</h2>
      <div className="table-wrap" style={{ marginBottom: 24 }}>
        <table className="data">
          <thead>
            <tr>
              <th>Version</th>
              <th>Channel</th>
              <th>Released</th>
              <th>Size</th>
              <th>SHA-256</th>
              <th>Signature</th>
              <th>Download</th>
            </tr>
          </thead>
          <tbody>
            {packages.map((p) => (
              <tr key={p.id}>
                <td>{p.version}</td>
                <td>{p.channel}</td>
                <td>{p.releasedAt.slice(0, 10)}</td>
                <td>{(p.packageSizeBytes / 1024).toFixed(1)} KB</td>
                <td className="mono" title={p.sha256}>
                  {p.sha256.slice(0, 16)}…
                </td>
                <td>
                  <div className="meta">{p.signatureStatus}</div>
                  <div className="meta">{p.signatureSubject}</div>
                </td>
                <td>
                  <a className="btn btn-primary" href={`/api/releases/download/${p.id}`}>
                    Download installer
                  </a>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <h2 style={{ fontSize: 16, margin: "0 0 10px" }}>Release notes</h2>
      <div className="grid" style={{ gap: 12, marginBottom: 24 }}>
        {packages.map((p) => (
          <div className="card" key={`notes-${p.id}`}>
            <h3 style={{ textTransform: "none", letterSpacing: 0, color: "var(--gm-ivory-100)" }}>
              {p.version} · {p.channel}
            </h3>
            <p style={{ margin: "8px 0 0" }}>{p.releaseNotes}</p>
            <div className="meta mono" style={{ marginTop: 8 }}>
              SHA-256: {p.sha256}
            </div>
          </div>
        ))}
      </div>

      <h2 style={{ fontSize: 16, margin: "0 0 10px" }}>Compatibility matrix</h2>
      <div className="table-wrap" style={{ marginBottom: 24 }}>
        <table className="data">
          <thead>
            <tr>
              <th>Version</th>
              <th>Channel</th>
              <th>OS</th>
              <th>MT5</th>
              <th>Core tag</th>
              <th>Core frozen</th>
            </tr>
          </thead>
          <tbody>
            {matrix.map((m) => (
              <tr key={`${m.channel}-${m.version}`}>
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

      <h2 style={{ fontSize: 16, margin: "0 0 10px" }}>Update history</h2>
      <div className="table-wrap" style={{ marginBottom: 24 }}>
        <table className="data">
          <thead>
            <tr>
              <th>When</th>
              <th>From → To</th>
              <th>Result</th>
              <th>Detail</th>
            </tr>
          </thead>
          <tbody>
            {updateHistory.length === 0 && (
              <tr>
                <td colSpan={4}>No update events for this account yet.</td>
              </tr>
            )}
            {updateHistory.map((h) => (
              <tr key={h.id}>
                <td>{h.at.slice(0, 19).replace("T", " ")}</td>
                <td>
                  {h.fromVersion} → {h.toVersion}
                </td>
                <td>{h.result}</td>
                <td>{h.detail}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <h2 style={{ fontSize: 16, margin: "0 0 10px" }}>Download history</h2>
      <div className="table-wrap">
        <table className="data">
          <thead>
            <tr>
              <th>Version</th>
              <th>Downloaded</th>
              <th>IP (masked)</th>
            </tr>
          </thead>
          <tbody>
            {history.length === 0 && (
              <tr>
                <td colSpan={3}>No downloads yet for this account.</td>
              </tr>
            )}
            {history.map((h) => (
              <tr key={h.id}>
                <td>{h.version}</td>
                <td>{h.at.slice(0, 19).replace("T", " ")}</td>
                <td className="mono">{h.ipMasked}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </>
  );
}
