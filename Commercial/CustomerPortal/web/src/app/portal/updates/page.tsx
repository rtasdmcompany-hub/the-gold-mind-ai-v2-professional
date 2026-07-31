import { auth } from "@/auth";
import {
  checkForUpdate,
  listPublished,
  getReportedInstalledVersion,
} from "@/server/releases/release-service";
import { redirect } from "next/navigation";
import Link from "next/link";
import { product } from "@/lib/product";

/**
 * Customer Updates — stable channel only.
 * RC / development remain Admin Console exclusives.
 */
export default async function UpdatesPage({
  searchParams,
}: {
  searchParams: Promise<{ version?: string }>;
}) {
  const session = await auth();
  if (!session?.user?.email) redirect("/login");
  const sp = await searchParams;
  const channel = "stable" as const;
  const reported = getReportedInstalledVersion(session.user.email);
  const version = sp.version || reported || "1.0.0";
  const check = checkForUpdate({ channel, version, email: session.user.email });
  const all = listPublished(channel);

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Updates</h1>
        <p className="page-sub">
          Stable release channel · verified packages · automatic rollback on checksum failure
        </p>
      </header>

      <div className="grid grid-2" style={{ marginBottom: 16 }}>
        <div className="card">
          <h3>Installed Version</h3>
          <div className="value" style={{ fontSize: 18 }}>
            {version}
          </div>
          <div className="meta">
            Channel: Stable
            {reported ? " · from updater telemetry" : ""}
          </div>
        </div>
        <div className="card">
          <h3>Latest Stable</h3>
          <div className="value" style={{ fontSize: 18 }}>
            {check.latest?.version || "—"}
          </div>
          <div className="meta">
            {check.updateAvailable ? "Update available" : "Up to date"}
            {check.latest ? ` · Build ${check.latest.buildNumber}` : ""}
          </div>
        </div>
      </div>

      {check.latest && (
        <div className="card" style={{ marginBottom: 16 }}>
          <h3>{check.updateAvailable ? "Update available" : "Current stable package"}</h3>
          <p style={{ margin: "8px 0" }}>{check.latest.releaseNotes}</p>
          <div className="meta mono">SHA-256: {check.latest.sha256}</div>
          <div className="meta">
            Signature: {check.latest.signatureStatus}
            {check.latest.signatureSubject ? ` · ${check.latest.signatureSubject}` : ""}
          </div>
          {check.updateAvailable && (
            <p className="meta" style={{ marginTop: 10 }}>
              Download the ZIP, extract it, run {product.installer.name}, and complete mandatory license activation with your existing email and key.
            </p>
          )}
          <p style={{ marginTop: 12 }}>
            <a className="btn btn-primary" href={`/api/releases/download/${check.latest.id}`}>
              Download latest installer ZIP
            </a>{" "}
            <Link className="btn" href="/portal/downloads">
              Download Center
            </Link>
          </p>
        </div>
      )}

      <h2 style={{ fontSize: 15, margin: "0 0 10px" }}>Stable packages</h2>
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
