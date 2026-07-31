import Link from "next/link";
import { auth } from "@/auth";
import { SignOutButton } from "@/components/SignOutButton";
import { ChangePasswordForm } from "@/components/AccountSecurityForms";
import { getAccountByEmail } from "@/server/accounts/store";
import { redirect } from "next/navigation";

export default async function SecurityPage() {
  const session = await auth();
  if (!session?.user?.email) redirect("/login");
  const email = session.user.email.toLowerCase();
  const account = await getAccountByEmail(email);
  const googleConfigured = !!(process.env.GOOGLE_CLIENT_ID && process.env.GOOGLE_CLIENT_SECRET);
  const role = (session?.user as { role?: string } | undefined)?.role || "customer";

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Security</h1>
        <p className="page-sub">Session, password, OAuth status, and secure logout.</p>
      </header>

      <div className="grid grid-2">
        <div className="card">
          <h3>Authentication</h3>
          <p style={{ margin: "8px 0 0" }}>
            Signed in as: <strong>{email}</strong>
          </p>
          <p style={{ margin: "8px 0 0" }}>
            Google OAuth:{" "}
            {googleConfigured ? "Configured" : "Not configured (email/password with verified accounts)"}
          </p>
          <p className="meta">Session strategy: JWT · max age 8 hours · email verification required for credentials</p>
          <p style={{ margin: "12px 0 0" }}>
            <Link href="/portal/account">Account settings</Link>
          </p>
        </div>
        <div className="card">
          <h3>Role</h3>
          <p style={{ margin: "8px 0 0" }}>
            Current role: <strong>{role}</strong>
          </p>
          <p className="meta">Roles: customer · admin (admin console separate)</p>
        </div>
        <div className="card">
          <h3>Change password</h3>
          <ChangePasswordForm hasPassword={!!account?.passwordHash} />
        </div>
        <div className="card">
          <h3>Secure logout</h3>
          <p style={{ margin: "8px 0 12px" }}>Ends the portal session and returns to login.</p>
          <SignOutButton />
        </div>
      </div>
    </>
  );
}
