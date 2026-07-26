import { auth } from "@/auth";
import { redirect } from "next/navigation";
import Link from "next/link";
import { hasPermission } from "@/server/admin/roles";
import { isDevAdminBypass } from "@/server/security/dev-bypass";
import { getPhase11Sprint4Dashboard } from "@/server/enterprise/suite";
import { actionRunEnterpriseSuite } from "@/server/enterprise/actions";

export default async function EnterpriseCrmPage() {
  const session = await auth();
  const role = (session?.user as { role?: string } | undefined)?.role;
  const actor = session?.user?.email?.toLowerCase() || "";
  if (!hasPermission(role, "admin.launch.read") && !isDevAdminBypass(actor)) {
    redirect("/portal/admin");
  }
  const dash = await getPhase11Sprint4Dashboard();
  const canWrite = hasPermission(role, "admin.launch.write") || isDevAdminBypass(actor);

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Enterprise CRM</h1>
        <p className="page-sub">Phase 11 Sprint 4 · multi-tenant commercial CRM</p>
      </header>

      <div className="card" style={{ marginBottom: 16, borderLeft: "4px solid #166534" }}>
        {dash.coreIsolation} · SHA {dash.coreMatches ? "MATCH" : "FAIL"}
      </div>

      <div className="grid grid-3" style={{ marginBottom: 16 }}>
        <div className="card">
          <h3>CRM Score</h3>
          <div className="value">{dash.crmScore}</div>
        </div>
        <div className="card">
          <h3>Enterprise Management</h3>
          <div className="value">{dash.enterpriseManagementScore}</div>
        </div>
        <div className="card">
          <h3>Team Licensing</h3>
          <div className="value">{dash.teamLicensingScore}</div>
        </div>
        <div className="card">
          <h3>RBAC</h3>
          <div className="value">{dash.rbacScore}</div>
        </div>
        <div className="card">
          <h3>Enterprise Readiness</h3>
          <div className="value">{dash.enterpriseReadinessScore}</div>
        </div>
        <div className="card">
          <h3>Phase 11 Progress</h3>
          <div className="value">{dash.overallPhase11Progress}%</div>
        </div>
      </div>

      {canWrite && (
        <form action={actionRunEnterpriseSuite} style={{ marginBottom: 16 }}>
          <button type="submit" className="btn btn-primary">
            Refresh enterprise suite
          </button>
        </form>
      )}

      <div className="grid grid-3" style={{ marginBottom: 16 }}>
        <div className="card">
          <h3>Organizations</h3>
          <div className="value">{dash.crm.totalOrgs}</div>
        </div>
        <div className="card">
          <h3>Leads</h3>
          <div className="value">{dash.crm.totalLeads}</div>
        </div>
        <div className="card">
          <h3>Open Leads</h3>
          <div className="value">{dash.crm.openLeads}</div>
        </div>
      </div>

      <h2 style={{ fontSize: 16 }}>Organizations</h2>
      <div className="table-wrap">
        <table className="data">
          <thead>
            <tr>
              <th>Name</th>
              <th>Status</th>
              <th>Health</th>
              <th>Seats</th>
              <th>Subs</th>
              <th>Invoices</th>
            </tr>
          </thead>
          <tbody>
            {dash.crm.organizations.map((row) => (
              <tr key={row.organization.id}>
                <td>{row.organization.name}</td>
                <td>{row.organization.status}</td>
                <td>{row.customerHealthScore}</td>
                <td>
                  {row.licenses.assigned}/{row.licenses.total}
                </td>
                <td>{row.subscriptions.length}</td>
                <td>{row.invoices.length}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <p style={{ marginTop: 24 }}>
        <Link className="btn" href="/portal/admin/organizations">
          Organizations
        </Link>{" "}
        <Link className="btn" href="/portal/admin/enterprise-success">
          Enterprise Success
        </Link>
      </p>
      <p className="meta" style={{ marginTop: 24 }}>
        STOP — Await Owner approval before Sprint 5.
      </p>
    </>
  );
}
