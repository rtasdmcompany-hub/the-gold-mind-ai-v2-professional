import { auth } from "@/auth";
import { StatusBadge } from "@/components/StatusBadge";
import { AccountProfileForm } from "@/components/AccountSecurityForms";
import { ensureSeedData } from "@/server/licensing/seed";
import { listLicensesForCustomer } from "@/server/licensing/license-service";
import { getAccountByEmail } from "@/server/accounts/store";
import { isTradeAlertsEnabled } from "@/server/accounts/service";
import { actionUpdateNotificationPrefs } from "@/server/accounts/actions";
import { redirect } from "next/navigation";
import Link from "next/link";
import { brand } from "@/lib/brand";

export default async function AccountPage() {
  await ensureSeedData();
  const session = await auth();
  if (!session?.user?.email) redirect("/login");
  const email = session.user.email.toLowerCase();
  
  // ✅ FIX: Yahan 'await' add kiya gaya hai
  const licenses = await listLicensesForCustomer(email);
  
  const account = await getAccountByEmail(email);
  const tradeAlerts = isTradeAlertsEnabled(account);

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Account Settings</h1>
        <p className="page-sub">
          Profile linked to commercial licensing identity. Email verification remains mandatory for credentials
          sign-in. <Link href="/portal/security">Security</Link>
        </p>
      </header>
      <div className="grid grid-2">
        <div className="card">
          <h3>Profile</h3>
          <div className="meta" style={{ marginBottom: 8 }}>{email}</div>
          <AccountProfileForm defaultName={account?.name || session?.user?.name || ""} />
          <div className="meta" style={{ marginTop: 8 }}>
            {account?.emailVerifiedAt
              ? `Verified ${account.emailVerifiedAt.slice(0, 10)}`
              : account
                ? "Verification pending"
                : "Session account — save name after first signup/OAuth"}
          </div>
        </div>
        <div className="card">
          <h3>Edition</h3>
          <div className="value" style={{ fontSize: 16 }}>
            {brand.productName}
          </div>
          <div className="meta">Provider: {account?.provider || "session"}</div>
        </div>
        <div className="card" style={{ gridColumn: "1 / -1" }}>
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

      <div className="card" style={{ marginTop: 20 }}>
        <h3>Notification preferences</h3>
        <p className="meta" style={{ marginBottom: 12 }}>
          Trade-close email alerts use the commercial mailer when configured (Resend). Default is ON.
        </p>
        <form action={actionUpdateNotificationPrefs} className="stack">
          <label style={{ display: "flex", gap: 10, alignItems: "center" }}>
            <input type="checkbox" name="tradeAlertsEnabled" defaultChecked={tradeAlerts} />
            Email me when trades close (profit or loss)
          </label>
          <button type="submit" className="btn btn-primary" style={{ alignSelf: "flex-start" }}>
            Save preferences
          </button>
        </form>
      </div>
    </>
  );
}
