import { auth } from "@/auth";
import { redirect } from "next/navigation";
import { hasPermission } from "@/server/admin/roles";
import { ensureDemoTelemetry, getTelemetrySummary } from "@/server/observability/telemetry-store";
import { actionRecordTelemetry } from "@/server/observability/actions";

export default async function TelemetryPage() {
  const session = await auth();
  const role = (session?.user as { role?: string } | undefined)?.role;
  const actor = session?.user?.email?.toLowerCase() || "";
  if (
    !hasPermission(role, "admin.observability.read") &&
    actor !== "admin@goldmind.local"
  ) {
    redirect("/portal/admin");
  }

  ensureDemoTelemetry();
  const t = getTelemetrySummary();
  const canWrite = hasPermission(role, "admin.observability.write") || actor === "admin@goldmind.local";

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Telemetry</h1>
        <p className="page-sub">
          Commercial performance samples · retention {t.retentionDays}d · PII sanitized · Core not instrumented
        </p>
      </header>

      <div className="grid grid-3" style={{ marginBottom: 16 }}>
        <div className="card">
          <h3>Application Startup Time</h3>
          <div className="value">{t.applicationStartupMs} ms</div>
        </div>
        <div className="card">
          <h3>Portal Load Time</h3>
          <div className="value">{t.portalLoadMs} ms</div>
        </div>
        <div className="card">
          <h3>API Response Time</h3>
          <div className="value">{t.apiResponseMs} ms</div>
        </div>
        <div className="card">
          <h3>Database Query Time</h3>
          <div className="value">{t.databaseQueryMs} ms</div>
        </div>
        <div className="card">
          <h3>Authentication Success Rate</h3>
          <div className="value">{t.authenticationSuccessRate}%</div>
        </div>
        <div className="card">
          <h3>License Validation Rate</h3>
          <div className="value">{t.licenseValidationRate}%</div>
        </div>
        <div className="card">
          <h3>Payment Success Rate</h3>
          <div className="value">{t.paymentSuccessRate}%</div>
        </div>
        <div className="card">
          <h3>Installer Success Rate</h3>
          <div className="value">{t.installerSuccessRate}%</div>
        </div>
        <div className="card">
          <h3>Update Success Rate</h3>
          <div className="value">{t.updateSuccessRate}%</div>
        </div>
      </div>

      {canWrite && (
        <form action={actionRecordTelemetry} className="card">
          <h3>Record sample</h3>
          <div className="stack" style={{ marginTop: 8 }}>
            <div className="field">
              <label htmlFor="kind">Kind</label>
              <select id="kind" name="kind" defaultValue="api_response_ms">
                <option value="app_startup_ms">app_startup_ms</option>
                <option value="portal_load_ms">portal_load_ms</option>
                <option value="api_response_ms">api_response_ms</option>
                <option value="db_query_ms">db_query_ms</option>
                <option value="auth_success">auth_success</option>
                <option value="auth_fail">auth_fail</option>
                <option value="license_ok">license_ok</option>
                <option value="license_fail">license_fail</option>
                <option value="payment_ok">payment_ok</option>
                <option value="payment_fail">payment_fail</option>
                <option value="installer_ok">installer_ok</option>
                <option value="installer_fail">installer_fail</option>
                <option value="update_ok">update_ok</option>
                <option value="update_fail">update_fail</option>
              </select>
            </div>
            <div className="field">
              <label htmlFor="valueMs">Value (ms)</label>
              <input id="valueMs" name="valueMs" type="number" />
            </div>
            <div className="field">
              <label htmlFor="detail">Detail</label>
              <input id="detail" name="detail" />
            </div>
            <button type="submit" className="btn btn-primary">
              Record
            </button>
          </div>
        </form>
      )}
    </>
  );
}
