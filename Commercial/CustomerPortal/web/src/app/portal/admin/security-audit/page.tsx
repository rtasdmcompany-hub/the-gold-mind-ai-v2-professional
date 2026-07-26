import { auth } from "@/auth";
import { redirect } from "next/navigation";
import Link from "next/link";
import { StatusBadge } from "@/components/StatusBadge";
import { hasPermission } from "@/server/admin/roles";
import { isDevAdminBypass } from "@/server/security/dev-bypass";
import { getExecutiveSecurityDashboard } from "@/server/security/dashboard";
import { actionRunFullSecuritySuite } from "@/server/security/actions";

export default async function SecurityAuditPage() {
  const session = await auth();
  const role = (session?.user as { role?: string } | undefined)?.role;
  const actor = session?.user?.email?.toLowerCase() || "";
  if (!hasPermission(role, "admin.security.manage") && !isDevAdminBypass(actor)) {
    redirect("/portal/admin");
  }

  const dash = await getExecutiveSecurityDashboard();
  const canWrite = hasPermission(role, "admin.security.manage") || isDevAdminBypass(actor);

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Executive Security Audit</h1>
        <p className="page-sub">
          Phase 10 Sprint 6 · readiness <StatusBadge status={dash.productionSecurityReadiness} /> · Core isolated
        </p>
      </header>

      <div className="card" style={{ marginBottom: 16, borderLeft: "4px solid #166534" }}>
        {dash.coreIsolation}
      </div>

      {canWrite && (
        <form action={actionRunFullSecuritySuite} style={{ marginBottom: 16 }}>
          <button type="submit" className="btn btn-primary">
            Run full Sprint 6 security suite
          </button>
        </form>
      )}

      <div className="grid grid-3" style={{ marginBottom: 16 }}>
        <div className="card">
          <h3>Overall Security</h3>
          <div className="value">{dash.overallSecurityScore}</div>
        </div>
        <div className="card">
          <h3>Penetration Testing</h3>
          <div className="value">{dash.penetrationTestingScore}</div>
        </div>
        <div className="card">
          <h3>Compliance</h3>
          <div className="value">{dash.complianceScore}</div>
        </div>
        <div className="card">
          <h3>Disaster Recovery</h3>
          <div className="value">{dash.disasterRecoveryScore}</div>
        </div>
        <div className="card">
          <h3>Operational Security</h3>
          <div className="value">{dash.operationalSecurityScore}</div>
        </div>
        <div className="card">
          <h3>Commercial Security</h3>
          <div className="value">{dash.commercialSecurityScore}</div>
        </div>
        <div className="card">
          <h3>Open Critical</h3>
          <div className="value">{dash.openCritical}</div>
        </div>
        <div className="card">
          <h3>Open High</h3>
          <div className="value">{dash.openHigh}</div>
        </div>
        <div className="card">
          <h3>Open Medium</h3>
          <div className="value">{dash.openMedium}</div>
        </div>
      </div>

      <h2 style={{ fontSize: 16 }}>Remaining risks</h2>
      <div className="table-wrap" style={{ marginBottom: 16 }}>
        <table className="data">
          <thead>
            <tr>
              <th>Severity</th>
              <th>Area</th>
              <th>Title</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
            {dash.remainingRisks.map((r, i) => (
              <tr key={`${r.title}-${i}`}>
                <td>{r.severity}</td>
                <td>{r.area}</td>
                <td>{r.title}</td>
                <td>
                  <StatusBadge status={r.status} />
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <div style={{ display: "flex", flexWrap: "wrap", gap: 8 }}>
        <Link className="btn" href="/portal/admin/pentest">
          Pentest
        </Link>
        <Link className="btn" href="/portal/admin/owasp">
          OWASP
        </Link>
        <Link className="btn" href="/portal/admin/secret-management">
          Secrets
        </Link>
        <Link className="btn" href="/portal/admin/data-protection">
          Data Protection
        </Link>
        <Link className="btn" href="/portal/admin/disaster-recovery">
          DR
        </Link>
        <Link className="btn" href="/portal/admin/compliance">
          Compliance
        </Link>
        <Link className="btn" href="/portal/admin/security">
          Admin Security
        </Link>
      </div>
      <p className="meta" style={{ marginTop: 12 }}>
        Generated {dash.generatedAt}
      </p>
    </>
  );
}
