import { auth } from "@/auth";
import { redirect } from "next/navigation";
import Link from "next/link";
import { hasPermission } from "@/server/admin/roles";
import { isDevAdminBypass } from "@/server/security/dev-bypass";
import { getPhase11Sprint1Dashboard } from "@/server/phase11/dashboard";

export default async function CsOperationsPage() {
  const session = await auth();
  const role = (session?.user as { role?: string } | undefined)?.role;
  const actor = session?.user?.email?.toLowerCase() || "";
  if (!hasPermission(role, "admin.launch.read") && !isDevAdminBypass(actor)) {
    redirect("/portal/admin");
  }
  const dash = await getPhase11Sprint1Dashboard();
  const s = dash.success;

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Customer Success Operations</h1>
        <p className="page-sub">Phase 11 Sprint 1 · segments · churn risk · support history</p>
      </header>

      {s && (
        <>
          <div className="grid grid-3" style={{ marginBottom: 16 }}>
            <div className="card">
              <h3>New Customers</h3>
              <div className="value">{s.newCustomers.count}</div>
            </div>
            <div className="card">
              <h3>Trial</h3>
              <div className="value">{s.trialCustomers.count}</div>
            </div>
            <div className="card">
              <h3>Paid</h3>
              <div className="value">{s.paidCustomers.count}</div>
            </div>
            <div className="card">
              <h3>Renewals</h3>
              <div className="value">{s.renewals.count}</div>
            </div>
            <div className="card">
              <h3>Churn Risk</h3>
              <div className="value">{s.churnRisk.count}</div>
            </div>
            <div className="card">
              <h3>CSAT</h3>
              <div className="value">{s.customerSatisfaction}</div>
            </div>
          </div>

          <h2 style={{ fontSize: 16 }}>Churn Risk</h2>
          <div className="table-wrap" style={{ marginBottom: 16 }}>
            <table className="data">
              <thead>
                <tr>
                  <th>Customer</th>
                  <th>Health</th>
                  <th>Open tickets</th>
                  <th>License</th>
                </tr>
              </thead>
              <tbody>
                {s.churnRisk.customers.length === 0 ? (
                  <tr>
                    <td colSpan={4} className="meta">
                      No high-risk customers
                    </td>
                  </tr>
                ) : (
                  s.churnRisk.customers.map((c) => (
                    <tr key={c.email}>
                      <td>{c.email}</td>
                      <td>{c.healthScore}</td>
                      <td>{c.openTickets}</td>
                      <td>{c.licenseStatus}</td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>

          <h2 style={{ fontSize: 16 }}>Support History</h2>
          <div className="table-wrap">
            <table className="data">
              <thead>
                <tr>
                  <th>Subject</th>
                  <th>Customer</th>
                  <th>Status</th>
                  <th>Priority</th>
                </tr>
              </thead>
              <tbody>
                {s.supportHistory.map((t) => (
                  <tr key={t.id}>
                    <td>{t.subject}</td>
                    <td className="meta">{t.email}</td>
                    <td>{t.status}</td>
                    <td>{t.priority}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </>
      )}

      <p style={{ marginTop: 24 }}>
        <Link className="btn" href="/portal/admin/global-ops">
          Global Ops
        </Link>
      </p>
    </>
  );
}
