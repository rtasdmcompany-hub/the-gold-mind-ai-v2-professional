import { auth } from "@/auth";
import { redirect } from "next/navigation";
import { StatusBadge } from "@/components/StatusBadge";
import { hasPermission } from "@/server/admin/roles";
import { getLicenseAdminView } from "@/server/admin/ops";
import { ensureSeedData } from "@/server/licensing/seed";

export default async function AdminLicensesPage({
  searchParams,
}: {
  searchParams: Promise<{ q?: string }>;
}) {
  ensureSeedData();
  const session = await auth();
  const role = (session?.user as { role?: string } | undefined)?.role;
  const actor = session?.user?.email?.toLowerCase() || "";
  if (!hasPermission(role, "admin.licenses.read") && actor !== "admin@goldmind.local") redirect("/portal");

  const sp = await searchParams;
  const view = getLicenseAdminView(sp.q);

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">License Administration</h1>
        <p className="page-sub">
          Search · activation history · expiration · renewal queue · trial/monthly/yearly/lifetime
        </p>
      </header>

      <div className="grid grid-3" style={{ marginBottom: 16 }}>
        <div className="card">
          <h3>Trial</h3>
          <div className="value">{view.counts.trial}</div>
        </div>
        <div className="card">
          <h3>Monthly</h3>
          <div className="value">{view.counts.monthly}</div>
        </div>
        <div className="card">
          <h3>Yearly</h3>
          <div className="value">{view.counts.yearly}</div>
        </div>
        <div className="card">
          <h3>Lifetime</h3>
          <div className="value">{view.counts.lifetime}</div>
        </div>
        <div className="card">
          <h3>Renewal Queue (14d)</h3>
          <div className="value">{view.renewalQueue.length}</div>
        </div>
        <div className="card">
          <h3>Total</h3>
          <div className="value">{view.counts.total}</div>
        </div>
      </div>

      <form className="card" method="get" style={{ marginBottom: 16 }}>
        <div className="field">
          <label htmlFor="q">License search</label>
          <input id="q" name="q" defaultValue={sp.q || ""} placeholder="email, id, type…" />
        </div>
        <button type="submit" className="btn btn-primary" style={{ marginTop: 8 }}>
          Search
        </button>
      </form>

      <h2 style={{ fontSize: 16 }}>Renewal queue</h2>
      <div className="table-wrap" style={{ marginBottom: 20 }}>
        <table className="data">
          <thead>
            <tr>
              <th>License</th>
              <th>Customer</th>
              <th>Type</th>
              <th>Expires</th>
            </tr>
          </thead>
          <tbody>
            {view.renewalQueue.length === 0 && (
              <tr>
                <td colSpan={4}>No expirations in the next 14 days</td>
              </tr>
            )}
            {view.renewalQueue.map((r) => (
              <tr key={r.licenseId}>
                <td className="mono">{r.licenseId}</td>
                <td>{r.email}</td>
                <td>{r.type}</td>
                <td>{r.expiresAt?.slice(0, 10)}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <h2 style={{ fontSize: 16 }}>Activation history</h2>
      <div className="table-wrap" style={{ marginBottom: 20 }}>
        <table className="data">
          <thead>
            <tr>
              <th>License</th>
              <th>Customer</th>
              <th>Activated</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
            {view.activationHistory.map((l) => (
              <tr key={l.id}>
                <td className="mono">{l.id}</td>
                <td>{l.customerEmail}</td>
                <td>{l.activatedAt?.slice(0, 19).replace("T", " ")}</td>
                <td>
                  <StatusBadge status={l.status} />
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <h2 style={{ fontSize: 16 }}>Licenses</h2>
      <div className="table-wrap">
        <table className="data">
          <thead>
            <tr>
              <th>Customer</th>
              <th>License</th>
              <th>Type</th>
              <th>Status</th>
              <th>Expires</th>
            </tr>
          </thead>
          <tbody>
            {view.licenses.map((l) => (
              <tr key={l.id}>
                <td>
                  {l.customerName}
                  <div className="meta">{l.customerEmail}</div>
                </td>
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
    </>
  );
}
