import { auth } from "@/auth";
import { redirect } from "next/navigation";
import Link from "next/link";
import { StatusBadge } from "@/components/StatusBadge";
import { hasPermission } from "@/server/admin/roles";
import { searchCustomers, getCustomerProfile } from "@/server/admin/ops";
import { ensureSeedData } from "@/server/licensing/seed";

export default async function AdminCustomersPage({
  searchParams,
}: {
  searchParams: Promise<{ q?: string; email?: string }>;
}) {
  ensureSeedData();
  const session = await auth();
  const role = (session?.user as { role?: string } | undefined)?.role;
  if (!hasPermission(role, "admin.customers.read")) redirect("/portal");

  const sp = await searchParams;
  if (sp.email) {
    const profile = getCustomerProfile(sp.email);
    return (
      <>
        <header style={{ marginBottom: 20 }}>
          <h1 className="page-title">Customer Profile</h1>
          <p className="page-sub">
            <Link href="/portal/admin/customers">← Back to search</Link> · read-only commercial profile
          </p>
        </header>
        <div className="grid grid-3" style={{ marginBottom: 16 }}>
          <div className="card">
            <h3>Customer</h3>
            <div className="value" style={{ fontSize: 16 }}>
              {profile.name}
            </div>
            <div className="meta">{profile.email}</div>
          </div>
          <div className="card">
            <h3>Account Status</h3>
            <StatusBadge status={profile.accountStatus} />
          </div>
          <div className="card">
            <h3>Subscription Status</h3>
            <div className="meta">
              {profile.subscriptions[0]?.status || profile.entitlements[0]?.status || "—"}
            </div>
          </div>
        </div>

        <h2 style={{ fontSize: 16 }}>Licenses</h2>
        <div className="table-wrap" style={{ marginBottom: 16 }}>
          <table className="data">
            <thead>
              <tr>
                <th>ID</th>
                <th>Type</th>
                <th>Status</th>
                <th>Expires</th>
              </tr>
            </thead>
            <tbody>
              {profile.licenses.map((l) => (
                <tr key={l.id}>
                  <td className="mono">{l.id}</td>
                  <td>{l.type}</td>
                  <td>
                    <StatusBadge status={l.status} />
                  </td>
                  <td>{l.expiresAt?.slice(0, 10) || "Lifetime"}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        <h2 style={{ fontSize: 16 }}>Devices</h2>
        <div className="table-wrap" style={{ marginBottom: 16 }}>
          <table className="data">
            <thead>
              <tr>
                <th>Name</th>
                <th>Status</th>
                <th>Last active</th>
              </tr>
            </thead>
            <tbody>
              {profile.devices.length === 0 && (
                <tr>
                  <td colSpan={3}>No devices</td>
                </tr>
              )}
              {profile.devices.map((d) => (
                <tr key={d.id}>
                  <td>{d.name}</td>
                  <td>
                    <StatusBadge status={d.status} />
                  </td>
                  <td>{d.lastActiveAt.slice(0, 10)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        <h2 style={{ fontSize: 16 }}>Order History</h2>
        <div className="table-wrap" style={{ marginBottom: 16 }}>
          <table className="data">
            <thead>
              <tr>
                <th>Payment</th>
                <th>Amount</th>
                <th>Status</th>
                <th>When</th>
              </tr>
            </thead>
            <tbody>
              {profile.orders.slice(0, 20).map((o) => (
                <tr key={o.id}>
                  <td className="mono">{o.id}</td>
                  <td>
                    {o.currency} {(o.amountCents / 100).toFixed(2)}
                  </td>
                  <td>
                    <StatusBadge status={o.status} />
                  </td>
                  <td>{o.createdAt.slice(0, 10)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        <h2 style={{ fontSize: 16 }}>Support History</h2>
        <div className="table-wrap">
          <table className="data">
            <thead>
              <tr>
                <th>Ticket</th>
                <th>Subject</th>
                <th>Status</th>
                <th>Priority</th>
              </tr>
            </thead>
            <tbody>
              {profile.supportHistory.length === 0 && (
                <tr>
                  <td colSpan={4}>No tickets</td>
                </tr>
              )}
              {profile.supportHistory.map((t) => (
                <tr key={t.id}>
                  <td className="mono">{t.id}</td>
                  <td>{t.subject}</td>
                  <td>
                    <StatusBadge status={t.status} />
                  </td>
                  <td>{t.priority}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </>
    );
  }

  const customers = searchCustomers(sp.q || "");
  const suspended = customers.filter((c) => c.accountStatus === "suspended");

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Customer Management</h1>
        <p className="page-sub">Search · profile · licenses · devices · orders · support · suspended accounts</p>
      </header>

      <form className="card" method="get" style={{ marginBottom: 16 }}>
        <div className="field">
          <label htmlFor="q">Customer search</label>
          <input id="q" name="q" defaultValue={sp.q || ""} placeholder="email or name" />
        </div>
        <button type="submit" className="btn btn-primary" style={{ marginTop: 8 }}>
          Search
        </button>
      </form>

      <div className="meta" style={{ marginBottom: 12 }}>
        Suspended accounts: {suspended.length}
      </div>

      <div className="table-wrap">
        <table className="data">
          <thead>
            <tr>
              <th>Customer</th>
              <th>Licenses</th>
              <th>Devices</th>
              <th>Status</th>
              <th>Last order</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            {customers.map((c) => (
              <tr key={c.email}>
                <td>
                  {c.name}
                  <div className="meta">{c.email}</div>
                </td>
                <td>{c.licenseCount}</td>
                <td>{c.deviceCount}</td>
                <td>
                  <StatusBadge status={c.accountStatus} />
                </td>
                <td>{c.lastOrderAt?.slice(0, 10) || "—"}</td>
                <td>
                  <Link className="btn" href={`/portal/admin/customers?email=${encodeURIComponent(c.email)}`}>
                    Profile
                  </Link>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </>
  );
}
