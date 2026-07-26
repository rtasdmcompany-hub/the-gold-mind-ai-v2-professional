import { auth } from "@/auth";
import { StatusBadge } from "@/components/StatusBadge";
import { ensureSeedData } from "@/server/licensing/seed";
import { listLicensesForCustomer } from "@/server/licensing/license-service";

export default async function AccountPage() {
  ensureSeedData();
  const session = await auth();
  const email = session?.user?.email?.toLowerCase() || "";
  const licenses = email ? listLicensesForCustomer(email) : [];

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Account Settings</h1>
        <p className="page-sub">Profile linked to commercial licensing identity.</p>
      </header>
      <div className="grid grid-2">
        <div className="card">
          <h3>Name</h3>
          <div className="value" style={{ fontSize: 16 }}>
            {session?.user?.name || "—"}
          </div>
        </div>
        <div className="card">
          <h3>Email</h3>
          <div className="value" style={{ fontSize: 16 }}>
            {email || "—"}
          </div>
        </div>
        <div className="card">
          <h3>Edition</h3>
          <div className="value" style={{ fontSize: 16 }}>
            THE GOLD MIND PROFESSIONAL
          </div>
        </div>
        <div className="card">
          <h3>License status (live)</h3>
          {licenses.length === 0 && <p className="meta">No licenses</p>}
          <ul className="list-plain">
            {licenses.map((l) => (
              <li key={l.id}>
                <StatusBadge status={l.status} /> <span className="mono">{l.keyMasked}</span>
              </li>
            ))}
          </ul>
        </div>
      </div>
    </>
  );
}
