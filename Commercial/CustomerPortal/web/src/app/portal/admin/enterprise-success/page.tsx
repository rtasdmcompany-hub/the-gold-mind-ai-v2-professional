import { auth } from "@/auth";
import { redirect } from "next/navigation";
import Link from "next/link";
import { hasPermission } from "@/server/admin/roles";
import { isDevAdminBypass } from "@/server/security/dev-bypass";
import { getPhase11Sprint4Dashboard } from "@/server/enterprise/suite";

export default async function EnterpriseSuccessPage() {
  const session = await auth();
  const role = (session?.user as { role?: string } | undefined)?.role;
  const actor = session?.user?.email?.toLowerCase() || "";
  if (!hasPermission(role, "admin.launch.read") && !isDevAdminBypass(actor)) {
    redirect("/portal/admin");
  }
  const dash = await getPhase11Sprint4Dashboard();
  const s = dash.success;
  const a = dash.audit;

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Enterprise Success & Audit</h1>
        <p className="page-sub">Phase 11 Sprint 4 · health · renewals · immutable audit</p>
      </header>

      {s && (
        <div className="grid grid-3" style={{ marginBottom: 16 }}>
          <div className="card">
            <h3>Organization Health</h3>
            <div className="value">{s.organizationHealth.score}</div>
          </div>
          <div className="card">
            <h3>Active Seats</h3>
            <div className="value">{s.activeSeats}</div>
          </div>
          <div className="card">
            <h3>CSAT proxy</h3>
            <div className="value">{s.customerSatisfaction}</div>
          </div>
          <div className="card">
            <h3>Support</h3>
            <div className="value" style={{ fontSize: 16 }}>
              {s.supportActivity.open} open / {s.supportActivity.total}
            </div>
          </div>
          <div className="card">
            <h3>Members</h3>
            <div className="value">{s.accountGrowth.members}</div>
          </div>
          <div className="card">
            <h3>Renewal Risk</h3>
            <div className="value">{s.renewalRisk.length}</div>
          </div>
        </div>
      )}

      {s && (
        <>
          <h2 style={{ fontSize: 16 }}>License Utilization</h2>
          <ul>
            {s.licenseUtilization.map((u) => (
              <li key={u.poolId}>
                {u.name}: {u.assigned}/{u.total} ({u.utilizationPct}%)
              </li>
            ))}
          </ul>
        </>
      )}

      {a && (
        <>
          <h2 style={{ fontSize: 16 }}>Audit & Compliance</h2>
          <p className="meta">{a.isolationNote} · immutable={String(a.immutable)}</p>
          <div className="grid grid-3" style={{ marginBottom: 16 }}>
            <div className="card">
              <h3>Audit entries</h3>
              <div className="value">{a.totals.auditEntries}</div>
            </div>
            <div className="card">
              <h3>License audit</h3>
              <div className="value">{a.totals.licenseAuditEntries}</div>
            </div>
            <div className="card">
              <h3>Logins</h3>
              <div className="value">{a.totals.logins}</div>
            </div>
          </div>
          <div className="table-wrap">
            <table className="data">
              <thead>
                <tr>
                  <th>At</th>
                  <th>Actor</th>
                  <th>Action</th>
                  <th>Detail</th>
                </tr>
              </thead>
              <tbody>
                {a.organizationActivity.slice(0, 15).map((e) => (
                  <tr key={e.id}>
                    <td className="meta">{e.at.slice(0, 19)}</td>
                    <td>{e.actor}</td>
                    <td>{e.action}</td>
                    <td className="meta">{e.detail}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </>
      )}

      <p style={{ marginTop: 24 }}>
        <Link className="btn" href="/portal/admin/enterprise-crm">
          Enterprise CRM
        </Link>
      </p>
    </>
  );
}
