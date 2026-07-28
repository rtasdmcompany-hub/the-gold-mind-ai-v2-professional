import { auth } from "@/auth";
import { StatusBadge } from "@/components/StatusBadge";
import { LicenseActionsPanel } from "@/components/LicenseActionsPanel";
import { LicenseStoreBanner } from "@/components/LicenseStoreBanner";
import { ensureSeedData } from "@/server/licensing/seed";
import { listLicensesForCustomer } from "@/server/licensing/license-service";
import { redirect } from "next/navigation";

export default async function LicensesPage() {
  await ensureSeedData();
  const session = await auth();
  if (!session?.user?.email) redirect("/login");
  const licenses = listLicensesForCustomer(session.user.email);

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">My Licenses</h1>
        <p className="page-sub">
          Step 1: generate a key here. Step 2: paste it into Setup.exe. Installation finishes only after
          portal activation succeeds — no second trip, no skipped licenses.
        </p>
      </header>

      <LicenseStoreBanner />
      <LicenseActionsPanel />

      <div className="table-wrap">
        <table className="data">
          <thead>
            <tr>
              <th>License</th>
              <th>Type</th>
              <th>Status</th>
              <th>Activated</th>
              <th>Expires</th>
              <th>Renewal</th>
              <th>Seats</th>
            </tr>
          </thead>
          <tbody>
            {licenses.length === 0 && (
              <tr>
                <td colSpan={7}>No licenses yet — generate one above, then paste the key into Setup.exe.</td>
              </tr>
            )}
            {licenses.map((lic) => (
              <tr key={lic.id}>
                <td>
                  <div className="mono">{lic.keyMasked}</div>
                  <div className="meta">{lic.id}</div>
                </td>
                <td>
                  {lic.edition}
                  <div className="meta">{lic.type}</div>
                </td>
                <td>
                  <StatusBadge status={lic.status} />
                </td>
                <td>{lic.activatedAt?.slice(0, 10) || "—"}</td>
                <td>{lic.expiresAt?.slice(0, 10) || "Lifetime"}</td>
                <td>{lic.renewalStatus}</td>
                <td>
                  {lic.seatsUsed}/{lic.seatsMax}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </>
  );
}
