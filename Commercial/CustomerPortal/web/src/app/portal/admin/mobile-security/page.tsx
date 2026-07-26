import { auth } from "@/auth";
import { redirect } from "next/navigation";
import Link from "next/link";
import { hasPermission } from "@/server/admin/roles";
import { isDevAdminBypass } from "@/server/security/dev-bypass";
import { getPhase11Sprint6Dashboard } from "@/server/mobile/suite";

export default async function MobileSecurityPage() {
  const session = await auth();
  const role = (session?.user as { role?: string } | undefined)?.role;
  const actor = session?.user?.email?.toLowerCase() || "";
  if (!hasPermission(role, "admin.launch.read") && !isDevAdminBypass(actor)) {
    redirect("/portal/admin");
  }
  const dash = await getPhase11Sprint6Dashboard();
  const s = dash.security;

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Mobile Security</h1>
        <p className="page-sub">Biometrics · TLS · tokens · integrity · revocation</p>
      </header>

      <div className="grid grid-3" style={{ marginBottom: 16 }}>
        <div className="card">
          <h3>Active sessions</h3>
          <div className="value">{s.activeSessions}</div>
        </div>
        <div className="card">
          <h3>Trusted devices</h3>
          <div className="value">{s.trustedDevices}</div>
        </div>
        <div className="card">
          <h3>Biometric devices</h3>
          <div className="value">{s.biometricEnabled}</div>
        </div>
        <div className="card">
          <h3>Integrity fails</h3>
          <div className="value">{s.integrityFails}</div>
        </div>
        <div className="card">
          <h3>Trading prohibited</h3>
          <div className="value">{s.tradingProhibited ? "YES" : "NO"}</div>
        </div>
        <div className="card">
          <h3>Remote revoke</h3>
          <div className="value">{s.remoteRevocation ? "ON" : "OFF"}</div>
        </div>
      </div>

      <div className="card" style={{ marginBottom: 16 }}>
        <h3>Certificate policy</h3>
        <p>
          TLS ≥ {s.certificatePolicy.tlsMinVersion} · hostname validation:{" "}
          {String(s.certificatePolicy.validateHostname)} · pin mode:{" "}
          {s.certificatePolicy.pinMode}
        </p>
        <h3 style={{ marginTop: 12 }}>Local storage</h3>
        <p>
          Android: {s.localStorage.android}
          <br />
          iOS: {s.localStorage.ios}
          <br />
          Never store: {s.localStorage.neverStored.join(", ")}
        </p>
        <p className="meta" style={{ marginTop: 12 }}>
          {s.tokenRefresh}
        </p>
      </div>

      <p>
        <Link className="btn" href="/portal/admin/mobile">
          Back to Mobile Ops
        </Link>
      </p>
    </>
  );
}
