import { auth } from "@/auth";
import {
  listPublished,
  getReportedInstalledVersion,
} from "@/server/releases/release-service";
import { readReleaseStore } from "@/server/releases/store";
import { redirect } from "next/navigation";
import Link from "next/link";

/**
 * Customer Download Center — LATEST STABLE ONLY.
 * RC / development / nightly are Admin Console exclusives.
 */
export default async function DownloadsPage() {
  const session = await auth();
  if (!session?.user?.email) redirect("/login");

  const email = session.user.email.toLowerCase();
  const stable = listPublished("stable");
  const latest = stable[0];
  const installed = getReportedInstalledVersion(email);
  const history = readReleaseStore()
    .downloadEvents.filter((d) => d.email?.toLowerCase() === email)
    .slice(0, 20);

  return (
    <>
      <header style={{ marginBottom: 24 }}>
        <h1 className="page-title">Download Center</h1>
        <p className="page-sub">
          Latest stable Windows ZIP · unzip and run Setup.exe with your license key · verified checksum
        </p>
      </header>

      {!latest ? (
        <div className="portal-empty">No stable release is published yet.</div>
      ) : (
        <div className="card download-hero" style={{ marginBottom: 20 }}>
          <div className="meta" style={{ color: "var(--gm-gold-500)", letterSpacing: "0.12em", textTransform: "uppercase", fontSize: 11 }}>
            Latest Stable Version
          </div>
          <div className="value" style={{ fontSize: 28, marginTop: 8 }}>
            THE GOLD MIND PROFESSIONAL {latest.version}
          </div>
          <div className="meta" style={{ marginTop: 8 }}>
            Windows (64-bit) · Build {latest.buildNumber} · Released {latest.releasedAt.slice(0, 10)}
          </div>
          <div className="meta" style={{ marginTop: 6 }}>
            OS: {latest.compatibility.os.join(", ")} · MT5 {latest.compatibility.mt5}
          </div>

          <div style={{ marginTop: 20, display: "flex", flexWrap: "wrap", gap: 12, alignItems: "center" }}>
            <a className="btn btn-primary" href={`/api/releases/download/${latest.id}`}>
              Download ZIP ({(latest.packageSizeBytes / (1024 * 1024)).toFixed(1)} MB)
            </a>
            <Link className="btn" href="/portal/updates">
              Check for updates
            </Link>
          </div>
          <p className="meta" style={{ marginTop: 12, lineHeight: 1.5 }}>
            After download: unzip → run <strong>Setup.exe</strong> (or TheGoldMindSetup.exe) → enter your existing
            license key → finish installation. MT5 EA deploy and activation are handled by the installer.
          </p>

          <div className="grid grid-2" style={{ marginTop: 20, gap: 12 }}>
            <div>
              <div className="meta" style={{ textTransform: "uppercase", letterSpacing: "0.08em", fontSize: 11 }}>
                Release Notes
              </div>
              <p style={{ margin: "8px 0 0", lineHeight: 1.6 }}>{latest.releaseNotes}</p>
            </div>
            <div>
              <div className="meta" style={{ textTransform: "uppercase", letterSpacing: "0.08em", fontSize: 11 }}>
                Integrity
              </div>
              <div className="meta mono" style={{ marginTop: 8, wordBreak: "break-all" }}>
                SHA256: {latest.sha256}
              </div>
              <div className="meta" style={{ marginTop: 6 }}>
                Digital Signature: {latest.signatureStatus}
                {latest.signatureSubject ? ` · ${latest.signatureSubject}` : ""}
              </div>
              <div className="meta" style={{ marginTop: 6 }}>
                Package size: {(latest.packageSizeBytes / (1024 * 1024)).toFixed(2)} MB · {latest.packageFile}
              </div>
            </div>
          </div>
        </div>
      )}

      <div className="grid grid-2" style={{ marginBottom: 20 }}>
        <div className="card">
          <h3>Installed Version</h3>
          <div className="value" style={{ fontSize: 18 }}>
            {installed || "Not reported"}
          </div>
          <div className="meta">Reported by the commercial updater after install</div>
        </div>
        <div className="card">
          <h3>Release Channel</h3>
          <div className="value" style={{ fontSize: 18 }}>
            Stable
          </div>
          <div className="meta">Customer releases are stable-only. RC and development builds are admin-restricted.</div>
        </div>
      </div>

      {stable.length > 1 && (
        <>
          <h2 style={{ fontSize: 15, margin: "0 0 10px", letterSpacing: "0.04em" }}>Previous Stable Releases</h2>
          <div className="table-wrap" style={{ marginBottom: 24 }}>
            <table className="data">
              <thead>
                <tr>
                  <th>Version</th>
                  <th>Released</th>
                  <th>SHA-256</th>
                  <th>Signature</th>
                  <th></th>
                </tr>
              </thead>
              <tbody>
                {stable.slice(1).map((p) => (
                  <tr key={p.id}>
                    <td>{p.version}</td>
                    <td>{p.releasedAt.slice(0, 10)}</td>
                    <td className="mono" title={p.sha256}>
                      {p.sha256.slice(0, 16)}…
                    </td>
                    <td>{p.signatureStatus}</td>
                    <td>
                      <a className="btn" href={`/api/releases/download/${p.id}`}>
                        Download
                      </a>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </>
      )}

      <h2 style={{ fontSize: 15, margin: "0 0 10px", letterSpacing: "0.04em" }}>Download History</h2>
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
