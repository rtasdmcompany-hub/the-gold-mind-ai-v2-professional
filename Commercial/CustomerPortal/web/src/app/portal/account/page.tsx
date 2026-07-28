import { auth } from "@/auth";
import { StatusBadge } from "@/components/StatusBadge";
import { ensureSeedData } from "@/server/licensing/seed";
import { listLicensesForCustomer } from "@/server/licensing/license-service";
import { getAccountByEmail } from "@/server/accounts/store";
import { isTradeAlertsEnabled } from "@/server/accounts/service";
import { actionUpdateNotificationPrefs } from "@/server/accounts/actions";
import { redirect } from "next/navigation";

export default async function AccountPage() {
  await ensureSeedData();
  const session = await auth();
  if (!session?.user?.email) redirect("/login");
  const email = session.user.email.toLowerCase();
  const licenses = listLicensesForCustomer(email);
  const account = await getAccountByEmail(email);
  const tradeAlerts = isTradeAlertsEnabled(account);

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
            {account?.name || session?.user?.name || "—"}
          </div>
        </div>
        <div className="card">
          <h3>Email</h3>
          <div className="value" style={{ fontSize: 16 }}>
            {email || "—"}
          </div>
          <div className="meta">
            {account?.emailVerifiedAt
              ? `Verified ${account.emailVerifiedAt.slice(0, 10)}`
              : account
                ? "Verification pending"
                : "Session account"}
          </div>
        </div>
        <div className="card">
          <h3>Edition</h3>
          <div className="value" style={{ fontSize: 16 }}>
            THE GOLD MIND PROFESSIONAL
          </div>
          <div className="meta">Provider: {account?.provider || "session"}</div>
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
