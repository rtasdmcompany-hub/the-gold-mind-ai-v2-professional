import { auth } from "@/auth";
import { redirect } from "next/navigation";
import Link from "next/link";
import { hasPermission } from "@/server/admin/roles";
import { isDevAdminBypass } from "@/server/security/dev-bypass";
import { getPhase11Sprint4Dashboard } from "@/server/enterprise/suite";
import { readEnterpriseStore } from "@/server/enterprise/store";

export default async function OrganizationsAdminPage() {
  const session = await auth();
  const role = (session?.user as { role?: string } | undefined)?.role;
  const actor = session?.user?.email?.toLowerCase() || "";
  if (!hasPermission(role, "admin.launch.read") && !isDevAdminBypass(actor)) {
    redirect("/portal/admin");
  }
  const dash = await getPhase11Sprint4Dashboard();
  const store = readEnterpriseStore();
  const orgId = dash.orgId;
  const members = orgId ? store.members.filter((m) => m.orgId === orgId) : [];
  const departments = orgId ? store.departments.filter((d) => d.orgId === orgId) : [];
  const pools = orgId ? store.pools.filter((p) => p.orgId === orgId) : [];
  const seats = orgId ? store.seats.filter((s) => s.orgId === orgId) : [];

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Organization Accounts & Team Licensing</h1>
        <p className="page-sub">Phase 11 Sprint 4 · RBAC · seats · billing</p>
      </header>

      <h2 style={{ fontSize: 16 }}>Members</h2>
      <div className="table-wrap" style={{ marginBottom: 16 }}>
        <table className="data">
          <thead>
            <tr>
              <th>Name</th>
              <th>Email</th>
              <th>Role</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
            {members.map((m) => (
              <tr key={m.id}>
                <td>{m.name}</td>
                <td>{m.email}</td>
                <td>{m.roleId}</td>
                <td>{m.status}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <h2 style={{ fontSize: 16 }}>Departments</h2>
      <ul>
        {departments.map((d) => (
          <li key={d.id}>{d.name}</li>
        ))}
      </ul>

      <h2 style={{ fontSize: 16 }}>Roles (RBAC)</h2>
      <ul>
        {dash.roles.map((r) => (
          <li key={r.id}>
            {r.label} ({r.id}) {r.builtin ? "· builtin" : "· custom"}
          </li>
        ))}
      </ul>

      <h2 style={{ fontSize: 16 }}>License Pools</h2>
      <div className="table-wrap" style={{ marginBottom: 16 }}>
        <table className="data">
          <thead>
            <tr>
              <th>Pool</th>
              <th>Plan</th>
              <th>Seats</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
            {pools.map((p) => (
              <tr key={p.id}>
                <td>{p.name}</td>
                <td>{p.planCode}</td>
                <td>{p.totalSeats}</td>
                <td>{p.status}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <h2 style={{ fontSize: 16 }}>Seats</h2>
      <div className="table-wrap" style={{ marginBottom: 16 }}>
        <table className="data">
          <thead>
            <tr>
              <th>Seat</th>
              <th>Status</th>
              <th>Assigned</th>
            </tr>
          </thead>
          <tbody>
            {seats.slice(0, 20).map((s) => (
              <tr key={s.id}>
                <td>#{s.seatIndex}</td>
                <td>{s.status}</td>
                <td>{s.assignedEmail || "—"}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {dash.billing && (
        <>
          <h2 style={{ fontSize: 16 }}>Enterprise Billing</h2>
          <p>
            Subscriptions: {dash.billing.subscriptions.length} · Invoices:{" "}
            {dash.billing.invoices.length} · POs: {dash.billing.purchaseOrders.length}
          </p>
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
