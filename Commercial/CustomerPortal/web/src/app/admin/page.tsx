import { auth, signOut } from "@/auth";
import type { Session } from "next-auth";
import Link from "next/link";
import { redirect } from "next/navigation";
import { BrandLogo } from "@/components/BrandLogo";
import { EnterpriseShell } from "@/components/enterprise/EnterpriseShell";
import { FinancialParticles } from "@/components/enterprise/FinancialParticles";
import { brand } from "@/lib/brand";
import { canAccessAdminConsole } from "@/server/admin/roles";
import { isDevAdminBypass } from "@/server/security/dev-bypass";
import { ensureBootstrapAdminFromEnv } from "@/server/accounts/service";
import { safeCredentialsSignIn } from "@/server/auth/safe-signin";

const CMS_PATH = "/portal/admin/site-content";

function adminLoginError(code?: string): string {
  switch ((code || "").trim()) {
    case "CredentialsSignin":
      return "Admin email or password is incorrect.";
    case "AccountMissing":
      return "No password account found for this email. Register once, or use an admin account that already has a password.";
    case "UseGoogle":
      return "This account is Google-only. Create/set a password via User Portal, or add this Google email to PORTAL_SUPER_ADMIN_EMAILS on Vercel.";
    case "Verification":
      return "Verify this email before admin sign-in.";
    case "AccessDenied":
      return "Access denied. Too many attempts — wait and try again.";
    case "NotAdmin":
      return "This email is signed in but is not on the admin roster. Add it to PORTAL_SUPER_ADMIN_EMAILS on Vercel, then sign in again.";
    default:
      return code ? "Admin sign-in failed. Try again." : "";
  }
}

export default async function AdminEntryPage({
  searchParams,
}: {
  searchParams: Promise<{ error?: string }>;
}) {
  // Ensure owner admin account exists (from Vercel bootstrap env) before login UI.
  try {
    await ensureBootstrapAdminFromEnv();
  } catch {
    /* non-fatal */
  }

  let session: Session | null = null;
  try {
    session = await auth();
  } catch {
    session = null;
  }

  const email = session?.user?.email?.toLowerCase() || "";
  const role = (session?.user as { role?: string } | undefined)?.role || "customer";
  const isAdmin = canAccessAdminConsole(role) || isDevAdminBypass(email);

  if (session?.user && isAdmin) {
    redirect(CMS_PATH);
  }

  const sp = await searchParams;
  const errorText =
    adminLoginError(sp.error) ||
    (session?.user && !isAdmin ? adminLoginError("NotAdmin") : "");

  return (
    <EnterpriseShell>
      <div className="e-login-page e-login-page--shell">
        <div className="e-login-bg" aria-hidden="true">
          <div className="e-login-bg-gradient" />
          <FinancialParticles density={32} />
          <div className="e-login-bg-illustration" />
        </div>

        <div className="e-login-shell">
          <div className="e-login-card e-glass-card e-login-glass">
            <div className="e-login-brand">
              <BrandLogo variant="login" priority className="e-brand-logo e-brand-logo--login" />
              <p className="e-login-eyebrow">{brand.brandName}</p>
              <h1 className="e-login-title">Admin Only</h1>
              <p className="e-login-sub">
                Enter admin email and password to open the Site Content CMS. The account must be
                listed in Vercel env <code>PORTAL_SUPER_ADMIN_EMAILS</code> (or{" "}
                <code>PORTAL_ADMIN_EMAILS</code>).
              </p>
            </div>

            {session?.user && !isAdmin ? (
              <p className="e-login-error" role="status">
                Currently signed in as <strong>{email}</strong> (customer). Sign out below, or use a
                different admin email/password.
              </p>
            ) : null}

            {errorText && !(session?.user && !isAdmin && !sp.error) ? (
              <p className="e-login-error" role="alert">
                {errorText}
              </p>
            ) : null}

            <div className="e-login-actions">
              <form
                action={async (fd) => {
                  "use server";
                  const adminEmail = String(fd.get("email") || "");
                  const password = String(fd.get("password") || "");
                  await safeCredentialsSignIn({
                    email: adminEmail,
                    password,
                    callbackUrl: CMS_PATH,
                  });
                }}
                className="e-form"
              >
                <div className="e-field">
                  <label htmlFor="admin-email">Admin Email</label>
                  <input
                    id="admin-email"
                    name="email"
                    type="email"
                    placeholder="Admin Email"
                    required
                    autoComplete="username"
                    defaultValue={email && !isAdmin ? "" : undefined}
                  />
                </div>
                <div className="e-field">
                  <label htmlFor="admin-password">Password</label>
                  <input
                    id="admin-password"
                    name="password"
                    type="password"
                    placeholder="Password"
                    required
                    minLength={8}
                    autoComplete="current-password"
                  />
                </div>
                <button type="submit" className="e-btn e-btn-primary e-btn--full">
                  Sign In to CMS
                </button>
              </form>

              {session?.user ? (
                <form
                  action={async () => {
                    "use server";
                    await signOut({ redirectTo: "/admin" });
                  }}
                >
                  <button type="submit" className="e-btn e-btn-ghost e-btn--full">
                    Sign out ({email})
                  </button>
                </form>
              ) : null}

              <p className="e-login-oauth-note" style={{ textAlign: "center" }}>
                Customers use <Link href="/login">User Portal</Link> ·{" "}
                <Link href="/">Website home</Link>
              </p>
            </div>
          </div>
        </div>
      </div>
    </EnterpriseShell>
  );
}
