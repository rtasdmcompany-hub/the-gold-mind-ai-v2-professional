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
  const session = await auth();
  if (!session?.user?.email) redirect("/login");

  let licenses: Awaited<ReturnType<typeof listLicensesForCustomer>> = [];
  let loadError: string | null = null;
  try {
    await ensureSeedData();
    licenses = await listLicensesForCustomer(session.user.email);
  } catch (e) {
    loadError = e instanceof Error ? e.message : "LICENSE_PAGE_LOAD_FAILED";
    console.error("[portal/licenses] load failed", loadError);
  }
  
  const allowPaidSelfServe = isSelfServePaidLicenseAllowed();

  // ✅ 1. Check if user has an active/pending/grace license
  const hasValidLicense = licenses.some(
    (lic) => lic.status === "active" || lic.status === "pending" || lic.status === "grace"
  );

  // ✅ 2. Check if user has EVER used a trial (to hide trial button permanently)
  const hasUsedTrial = licenses.some((lic) => lic.type === "trial");

  // ✅ 3. Check for 3-Day Renewal Reminder
  const now = new Date();
  const threeDaysFromNow = new Date(now.getTime() + 3 * 24 * 60 * 60 * 1000);
  
  const expiringSoonLicense = licenses.find((lic) => {
    if (lic.status !== "active" && lic.status !== "grace") return false;
    if (!lic.expiresAt) return false; // Lifetime doesn't expire
    const expDate = new Date(lic.expiresAt);
    return expDate > now && expDate <= threeDaysFromNow;
  });

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

      {loadError ? (
        <div className="card" style={{ marginBottom: 16, borderColor: "#a44" }}>
          <h3 style={{ marginBottom: 6 }}>Could not load licenses</h3>
          <p className="meta">
            The license list is temporarily unavailable. You can still try generating a trial key below, or
            refresh in a moment.
          </p>
        </div>
      ) : null}

      <LicenseStoreBanner />

      {/* ✅ NEW: 3-Day Renewal Reminder Banner */}
      {expiringSoonLicense && (
        <div 
          className="card" 
          style={{ 
            marginBottom: 16, 
            borderColor: "var(--gm-warning, #ffc107)", 
            backgroundColor: "rgba(255, 193, 7, 0.1)" 
          }}
        >
          <h3 style={{ marginBottom: 6, color: "var(--gm-warning, #d39e00)" }}>
            ⚠️ Your {expiringSoonLicense.type} plan is expiring soon!
          </h3>
          <p className="meta" style={{ marginTop: 8, lineHeight: 1.5, marginBottom: 12 }}>
            Your current plan will expire on <strong>{new Date(expiringSoonLicense.expiresAt!).toLocaleDateString()}</strong>. 
            To avoid any interruption in your service, please renew your plan now.
          </p>
          <Link 
            href="/portal/billing" 
            className="btn btn-primary"
            style={{ textDecoration: "none", display: "inline-block" }}
          >
            Renew Now
          </Link>
        </div>
      )}
      
      {/* ✅ UPDATED: Pass hasUsedTrial to LicenseActionsPanel */}
      {!hasValidLicense ? (
        <LicenseActionsPanel 
          allowPaidSelfServe={allowPaidSelfServe} 
          hasUsedTrial={hasUsedTrial} 
        />
      ) : (
        <div className="card" style={{ marginBottom: 16, borderColor: "var(--gm-success, #28a745)" }}>
          <h3 style={{ marginBottom: 6, color: "var(--gm-success, #28a745)" }}>License Already Active</h3>
          <p className="meta" style={{ marginTop: 8, lineHeight: 1.5 }}>
            You already have an active or pending license. For security and anti-abuse purposes, new trial keys cannot be generated. 
            Please use your existing key in the installer. If you need to upgrade or change your MT5 account, please visit{" "}
            <Link href="/portal/billing" style={{ textDecoration: "underline" }}>Billing</Link> or contact support.
          </p>
        </div>
      )}

      <div className="table-wrap">
        <table className="data">
          <thead>
            <tr>
              <th>License</th>
              <th>MT5 Account</th>
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
                <td colSpan={9}>
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
                  {lic.mt5AccountNumber ? (
                    <div className="mono" style={{ color: "var(--gm-primary, #d4af37)" }}>
                      {lic.mt5AccountNumber}
                    </div>
                  ) : (
                    <span className="meta">Not bound</span>
                  )}
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