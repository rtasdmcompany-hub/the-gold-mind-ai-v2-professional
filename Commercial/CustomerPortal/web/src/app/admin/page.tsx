import { auth } from "@/auth";
import type { Session } from "next-auth";
import Link from "next/link";
import { redirect } from "next/navigation";
import { BrandLogo } from "@/components/BrandLogo";
import { EnterpriseShell } from "@/components/enterprise/EnterpriseShell";
import { FinancialParticles } from "@/components/enterprise/FinancialParticles";
import { brand } from "@/lib/brand";
import { canAccessAdminConsole } from "@/server/admin/roles";
import { isDevAdminBypass } from "@/server/security/dev-bypass";
import { safeCredentialsSignIn } from "@/server/auth/safe-signin";

const CMS_PATH = "/portal/admin/site-content";

function adminLoginError(code?: string): string {
  switch ((code || "").trim()) {
    case "CredentialsSignin":
      return "Admin email or password is incorrect.";
    case "AccountMissing":
      return "No admin account found for this email.";
    case "UseGoogle":
      return "This account is Google-only. Use an admin email/password account, or sign in via User Portal with Google then open Admin.";
    case "Verification":
      return "Verify this email before admin sign-in.";
    case "AccessDenied":
      return "Access denied. Too many attempts — wait and try again.";
    default:
      return code ? "Admin sign-in failed. Try again." : "";
  }
}

export default async function AdminEntryPage({
  searchParams,
}: {
  searchParams: Promise<{ error?: string }>;
}) {
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
  const errorText = adminLoginError(sp.error);

  if (session?.user && !isAdmin) {
    return (
      <EnterpriseShell>
        <div className="e-login-page e-login-page--shell">
          <div className="e-login-bg" aria-hidden="true">
            <div className="e-login-bg-gradient" />
            <FinancialParticles density={28} />
          </div>
          <div className="e-login-shell">
            <div className="e-login-card e-glass-card e-login-glass">
              <h1 className="e-login-title">Admin access only</h1>
              <p className="e-login-sub">
                Signed in as {email || "customer"}. This area is restricted to configured admin
                accounts ({brand.productName} admin roster).
              </p>
              <div className="e-login-actions">
                <Link href="/portal" className="e-btn e-btn-primary e-btn--full">
                  Go to Customer Portal
                </Link>
                <Link href="/" className="e-btn e-btn-ghost e-btn--full">
                  Back to website
                </Link>
              </div>
            </div>
          </div>
        </div>
      </EnterpriseShell>
    );
  }

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
              <h1 className="e-login-title">Admin Console</h1>
              <p className="e-login-sub">
                Sign in with your admin email and password to open the Site Content CMS.
              </p>
            </div>

            {errorText ? (
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
                  <label htmlFor="admin-email">Admin email</label>
                  <input
                    id="admin-email"
                    name="email"
                    type="email"
                    placeholder="admin@company.com"
                    required
                    autoComplete="username"
                  />
                </div>
                <div className="e-field">
                  <label htmlFor="admin-password">Password</label>
                  <input
                    id="admin-password"
                    name="password"
                    type="password"
                    placeholder="••••••••"
                    required
                    minLength={8}
                    autoComplete="current-password"
                  />
                </div>
                <button type="submit" className="e-btn e-btn-primary e-btn--full">
                  Enter Site Content CMS
                </button>
              </form>

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
