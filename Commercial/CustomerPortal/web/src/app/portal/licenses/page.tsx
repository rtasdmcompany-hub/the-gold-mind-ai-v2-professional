import { auth } from "@/auth";
import { StatusBadge } from "@/components/StatusBadge";
import { LicenseActionsPanel } from "@/components/LicenseActionsPanel";
import { LicenseStoreBanner } from "@/components/LicenseStoreBanner";
import { ensureSeedData } from "@/server/licensing/seed";
import { listLicensesForCustomer } from "@/server/licensing/license-service";
import { isSelfServePaidLicenseAllowed } from "@/server/billing/config";
import { redirect } from "next/navigation";
import Link from "next/link";
import { product } from "@/lib/product";

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
            ? `Generate a key, then paste it into ${product.installer.name}. Installation finishes only after portal activation succeeds.`
            : `One free trial per email (and per IP). Regenerating shows the same key and original dates. Paid keys come from Billing. Paste into ${product.installer.name} — install finishes only after portal activation succeeds.`}{" "}
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
              <th>Created</th>
              <th>Activated</th>
              <th>Expires</th>
              <th>Renewal</th>
              <th>Seats</th>
            </tr>
          </thead>
          <tbody>
            {licenses.length === 0 && (
              <tr>
                <td colSpan={8}>
                  No licenses yet — {allowPaidSelfServe ? "generate one above" : "get your trial key above or checkout in Billing"}, then
                  paste the key into {product.installer.name}.
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
                <td>{lic.createdAt?.slice(0, 10) || "—"}</td>
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
