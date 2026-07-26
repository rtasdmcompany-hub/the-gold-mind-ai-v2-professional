import { auth } from "@/auth";
import {
  checkForUpdate,
  listPublished,
  getReportedInstalledVersion,
} from "@/server/releases/release-service";
import { redirect } from "next/navigation";
import Link from "next/link";

export default async function UpdatesPage({
  searchParams,
}: {
  searchParams: Promise<{ version?: string; channel?: string }>;
}) {
  const session = await auth();
  if (!session?.user?.email) redirect("/login");
  const sp = await searchParams;
  const channel = (sp.channel || "stable") as "stable" | "rc" | "development";
  const reported = getReportedInstalledVersion(session.user.email);
  const version = sp.version || reported || "2.0.0";
  const check = checkForUpdate({ channel, version, email: session.user.email });
  const all = listPublished(channel);

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Updates</h1>
        <p className="page-sub">
          Version check · release notes viewer · verified packages. Failed verification cancels install and keeps
          previous version.
        </p>
      </header>

      <div className="meta" style={{ marginBottom: 12 }}>
        Channel:{" "}
        <Link href="/portal/updates?channel=stable">stable</Link>
        {" · "}
        <Link href="/portal/updates?channel=rc">rc</Link>
        {" · "}
        <Link href="/portal/updates?channel=development">development</Link>
      </div>

      <div className="grid grid-2" style={{ marginBottom: 16 }}>
        <div className="card">
          <h3>Installed Version</h3>
          <div className="value" style={{ fontSize: 18 }}>
            {version}
          </div>
          <div className="meta">
            Channel: {channel}
            {reported ? " · from updater telemetry" : " · override with ?version="}
          </div>
        </div>
        <div className="card">
          <h3>Latest on channel</h3>
          <div className="value" style={{ fontSize: 18 }}>
            {check.latest?.version || "—"}
          </div>
          <div className="meta">
            {check.updateAvailable ? "Update available" : "Up to date"} · Build {check.latest?.buildNumber}
          </div>
        </div>
      </div>

      {check.latest && (
        <div className="card" style={{ marginBottom: 16 }}>
          <h3>Release notes</h3>
          <p style={{ margin: "8px 0" }}>{check.latest.releaseNotes}</p>
          <div className="meta mono">SHA-256: {check.latest.sha256}</div>
          <div className="meta">
            Signature: {check.latest.signatureStatus} · {check.latest.signatureSubject}
            {check.latest.signatureRequired ? " · required" : " · optional this channel"}
          </div>
          <div className="meta">
            Size: {(check.latest.packageSizeBytes / 1024).toFixed(1)} KB · HTTPS only · Core frozen:{" "}
            {String(check.latest.compatibility.coreFrozen)}
          </div>
          <div className="meta">
            Compatibility: {check.latest.compatibility.os.join(", ")} · MT5 {check.latest.compatibility.mt5} · Core
            tag {check.latest.compatibility.coreTag}
          </div>
          <p style={{ marginTop: 12 }}>
            <a className="btn btn-primary" href={`/api/releases/download/${check.latest.id}`}>
              Download package
            </a>{" "}
            <Link className="btn" href="/portal/downloads">
              All downloads
            </Link>
          </p>
          <p className="meta" style={{ marginTop: 12 }}>
            Client apply (safe · verified · recoverable):
            <br />
            <code>
              Update-TheGoldMindProfessional.ps1 -Channel {channel} -CurrentVersion {version} -Apply
              -CustomerEmail {session.user.email}
            </code>
          </p>
        </div>
      )}

      <h2 style={{ fontSize: 16 }}>Channel packages</h2>
      <div className="table-wrap">
        <table className="data">
          <thead>
            <tr>
              <th>Version</th>
              <th>Build</th>
              <th>SHA-256</th>
              <th>Notes</th>
            </tr>
          </thead>
          <tbody>
            {all.map((p) => (
              <tr key={p.id}>
                <td>{p.version}</td>
                <td>{p.buildNumber}</td>
                <td className="mono">{p.sha256.slice(0, 16)}…</td>
                <td>{p.releaseNotes}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </>
  );
}
