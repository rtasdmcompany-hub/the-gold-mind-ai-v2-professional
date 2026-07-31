import { auth } from "@/auth";
import { StatusBadge } from "@/components/StatusBadge";
import { LicenseActionsPanel } from "@/components/LicenseActionsPanel";
import { LicenseStoreBanner } from "@/components/LicenseStoreBanner";
import { ensureSeedData } from "@/server/licensing/seed";
import { listLicensesForCustomer } from "@/server/licensing/license-service";
import { isSelfServePaidLicenseAllowed } from "@/server/billing/config";
import { redirect } from "next/navigation";
import Link from "next/link";

export default async function LicensesPage() {
  await ensureSeedData();
  const session = await auth();
  if (!session?.user?.email) redirect("/login");
  const licenses = listLicensesForCustomer(session.user.email);
  const allowPaidSelfServe = isSelfServePaidLicenseAllowed();

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">My Licenses</h1>
        <p className="page-sub">
          {allowPaidSelfServe
            ? "Generate a key, then paste it into Setup.exe. Installation finishes only after portal activation succeeds."
            : "Start a free trial key here, or purchase via Billing for paid keys. Paste the key into Setup.exe — installation finishes only after portal activation succeeds."}{" "}
          <Link href="/portal/billing">Billing</Link>
        </p>
      </header>

      <LicenseStoreBanner />
      <LicenseActionsPanel allowPaidSelfServe={allowPaidSelfServe} />

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
                <td colSpan={7}>
                  No licenses yet — {allowPaidSelfServe ? "generate one above" : "start a trial above or checkout in Billing"}, then
                  paste the key into Setup.exe.
                </td>
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
