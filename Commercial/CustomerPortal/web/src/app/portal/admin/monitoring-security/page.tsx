import { auth } from "@/auth";
import { redirect } from "next/navigation";
import { hasPermission } from "@/server/admin/roles";
import { getMonitoringSecurityReview } from "@/server/observability/monitoring-security";

export default async function MonitoringSecurityPage() {
  const session = await auth();
  const role = (session?.user as { role?: string } | undefined)?.role;
  if (
    !hasPermission(role, "admin.observability.read") &&
    !hasPermission(role, "admin.security.manage")
  ) {
    redirect("/portal/admin");
  }

  const rev = getMonitoringSecurityReview();

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Monitoring Security</h1>
        <p className="page-sub">Access · audit · privacy · retention · sensitive data filtering · Core isolation</p>
      </header>

      <div className="card" style={{ marginBottom: 16 }}>
        <h3>Access permissions</h3>
        <pre style={{ whiteSpace: "pre-wrap", fontSize: 13 }}>{JSON.stringify(rev.accessPermissions, null, 2)}</pre>
      </div>
      <div className="card" style={{ marginBottom: 16 }}>
        <h3>Audit logs</h3>
        <pre style={{ whiteSpace: "pre-wrap", fontSize: 13 }}>{JSON.stringify(rev.auditLogs, null, 2)}</pre>
      </div>
      <div className="card" style={{ marginBottom: 16 }}>
        <h3>Dashboard permissions</h3>
        <pre style={{ whiteSpace: "pre-wrap", fontSize: 13 }}>{JSON.stringify(rev.dashboardPermissions, null, 2)}</pre>
      </div>
      <div className="card" style={{ marginBottom: 16 }}>
        <h3>Data privacy</h3>
        <pre style={{ whiteSpace: "pre-wrap", fontSize: 13 }}>{JSON.stringify(rev.dataPrivacy, null, 2)}</pre>
      </div>
      <div className="card" style={{ marginBottom: 16 }}>
        <h3>Telemetry retention</h3>
        <pre style={{ whiteSpace: "pre-wrap", fontSize: 13 }}>{JSON.stringify(rev.telemetryRetention, null, 2)}</pre>
      </div>
      <div className="card" style={{ marginBottom: 16 }}>
        <h3>Sensitive data filtering</h3>
        <pre style={{ whiteSpace: "pre-wrap", fontSize: 13 }}>
          {JSON.stringify(rev.sensitiveDataFiltering, null, 2)}
        </pre>
      </div>
      <div className="card">
        <h3>Isolation</h3>
        <pre style={{ whiteSpace: "pre-wrap", fontSize: 13 }}>{JSON.stringify(rev.isolation, null, 2)}</pre>
      </div>
    </>
  );
}
