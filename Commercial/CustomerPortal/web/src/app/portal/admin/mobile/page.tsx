import { auth } from "@/auth";
import { redirect } from "next/navigation";
import Link from "next/link";
import { hasPermission } from "@/server/admin/roles";
import { isDevAdminBypass } from "@/server/security/dev-bypass";
import { getPhase11Sprint6Dashboard } from "@/server/mobile/suite";
import { actionRunMobileSuite } from "@/server/mobile/actions";

export default async function MobileAdminPage() {
  const session = await auth();
  const role = (session?.user as { role?: string } | undefined)?.role;
  const actor = session?.user?.email?.toLowerCase() || "";
  if (!hasPermission(role, "admin.launch.read") && !isDevAdminBypass(actor)) {
    redirect("/portal/admin");
  }
  const dash = await getPhase11Sprint6Dashboard();
  const canWrite = hasPermission(role, "admin.launch.write") || isDevAdminBypass(actor);

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Mobile Companion</h1>
        <p className="page-sub">Phase 11 Sprint 6 · commercial management only (no trading)</p>
      </header>

      <div className="card" style={{ marginBottom: 16, borderLeft: "4px solid #166534" }}>
        {dash.coreIsolation} · SHA {dash.coreMatches ? "MATCH" : "FAIL"} · Trading prohibited:{" "}
        {dash.tradingProhibited ? "YES" : "NO"}
      </div>

      <div className="grid grid-3" style={{ marginBottom: 16 }}>
        <div className="card">
          <h3>Mobile Platform</h3>
          <div className="value">{dash.mobilePlatformScore}</div>
        </div>
        <div className="card">
          <h3>Security</h3>
          <div className="value">{dash.securityScore}</div>
        </div>
        <div className="card">
          <h3>Customer Experience</h3>
          <div className="value">{dash.customerExperienceScore}</div>
        </div>
        <div className="card">
          <h3>API Integration</h3>
          <div className="value">{dash.apiIntegrationScore}</div>
        </div>
        <div className="card">
          <h3>Enterprise Mobility</h3>
          <div className="value">{dash.enterpriseMobilityScore}</div>
        </div>
        <div className="card">
          <h3>Phase 11 Progress</h3>
          <div className="value">{dash.overallPhase11Progress}%</div>
        </div>
      </div>

      {canWrite && (
        <form action={actionRunMobileSuite} style={{ marginBottom: 16 }}>
          <button type="submit" className="btn btn-primary">
            Refresh mobile suite
          </button>
        </form>
      )}

      <h2 style={{ fontSize: 16 }}>Registered devices</h2>
      <div className="table-wrap" style={{ marginBottom: 16 }}>
        <table className="data">
          <thead>
            <tr>
              <th>Name</th>
              <th>Platform</th>
              <th>Trusted</th>
              <th>Biometric</th>
              <th>App</th>
              <th>Integrity</th>
            </tr>
          </thead>
          <tbody>
            {dash.devices.map((d) => (
              <tr key={d.id}>
                <td>{d.deviceName}</td>
                <td>{d.platform}</td>
                <td>{d.trusted ? "yes" : "no"}</td>
                <td>{d.biometricEnabled ? "yes" : "no"}</td>
                <td>{d.appVersion}</td>
                <td>{d.integrityOk ? "ok" : "fail"}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <h2 style={{ fontSize: 16 }}>Push overview</h2>
      <div className="card" style={{ marginBottom: 16 }}>
        Messages: {dash.push.totalMessages} · Devices with tokens: {dash.push.devicesWithTokens} ·
        Marketing default: {String(dash.push.marketingDefault)} · Delivered in suite:{" "}
        {dash.pushDelivered}
      </div>

      <p style={{ marginTop: 24 }}>
        <Link className="btn" href="/portal/admin/mobile-security">
          Mobile Security
        </Link>
      </p>
      <p className="meta" style={{ marginTop: 24 }}>
        STOP — Await Owner approval before Sprint 7.
      </p>
    </>
  );
}
