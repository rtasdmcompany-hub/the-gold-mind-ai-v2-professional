import { auth } from "@/auth";
import { redirect } from "next/navigation";
import { hasPermission } from "@/server/admin/roles";
import { ensureDemoMetrics, getProductionMetrics } from "@/server/launch/metrics-store";
import { actionRecordMetric } from "@/server/launch/actions";

export default async function AdminMetricsPage() {
  const session = await auth();
  const role = (session?.user as { role?: string } | undefined)?.role;
  if (!hasPermission(role, "admin.launch.read")) {
    redirect("/portal/admin");
  }

  ensureDemoMetrics();
  const m = getProductionMetrics();
  const canWrite = hasPermission(role, "admin.launch.write");

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Production Metrics</h1>
        <p className="page-sub">
          Beta commercial telemetry · Core crash instrumentation not modified (engine frozen)
        </p>
      </header>

      <div className="grid grid-3" style={{ marginBottom: 16 }}>
        <div className="card">
          <h3>Installation Success Rate</h3>
          <div className="value">{m.installationSuccessRate}%</div>
        </div>
        <div className="card">
          <h3>Activation Success Rate</h3>
          <div className="value">{m.activationSuccessRate}%</div>
        </div>
        <div className="card">
          <h3>Login Success Rate</h3>
          <div className="value">{m.loginSuccessRate}%</div>
        </div>
        <div className="card">
          <h3>License Validation Rate</h3>
          <div className="value">{m.licenseValidationRate}%</div>
        </div>
        <div className="card">
          <h3>Portal Usage</h3>
          <div className="value">{m.portalUsage}</div>
          <div className="meta">page views</div>
        </div>
        <div className="card">
          <h3>Update Success Rate</h3>
          <div className="value">{m.updateSuccessRate}%</div>
        </div>
        <div className="card">
          <h3>Crash Rate</h3>
          <div className="value">{m.crashRate}%</div>
          <div className="meta">portal proxy · Core untouched</div>
        </div>
        <div className="card">
          <h3>Average Session Time</h3>
          <div className="value">{m.averageSessionTimeMin}</div>
          <div className="meta">minutes</div>
        </div>
        <div className="card">
          <h3>Support Requests</h3>
          <div className="value">{m.supportRequests}</div>
        </div>
      </div>

      {canWrite && (
        <form action={actionRecordMetric} className="card">
          <h3>Record metric event</h3>
          <div className="stack" style={{ marginTop: 8 }}>
            <div className="field">
              <label htmlFor="type">Type</label>
              <select id="type" name="type" defaultValue="portal_page_view">
                <option value="install_success">install_success</option>
                <option value="install_fail">install_fail</option>
                <option value="activation_success">activation_success</option>
                <option value="activation_fail">activation_fail</option>
                <option value="login_success">login_success</option>
                <option value="login_fail">login_fail</option>
                <option value="license_validation_ok">license_validation_ok</option>
                <option value="license_validation_fail">license_validation_fail</option>
                <option value="portal_page_view">portal_page_view</option>
                <option value="update_success">update_success</option>
                <option value="update_fail">update_fail</option>
                <option value="crash_report">crash_report</option>
                <option value="session_end">session_end</option>
                <option value="support_request">support_request</option>
              </select>
            </div>
            <div className="field">
              <label htmlFor="email">Email (optional)</label>
              <input id="email" name="email" />
            </div>
            <div className="field">
              <label htmlFor="sessionMinutes">Session minutes (for session_end)</label>
              <input id="sessionMinutes" name="sessionMinutes" type="number" />
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
