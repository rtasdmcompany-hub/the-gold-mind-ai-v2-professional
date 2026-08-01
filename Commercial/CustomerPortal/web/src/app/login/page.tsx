import { auth } from "@/auth";
import type { Session } from "next-auth";
import { redirect } from "next/navigation";
import Link from "next/link";
import { BrandLogo } from "@/components/BrandLogo";
import { EnterpriseShell } from "@/components/enterprise/EnterpriseShell";
import { FinancialParticles } from "@/components/enterprise/FinancialParticles";
import { GoogleAutoStart } from "@/components/enterprise/GoogleAutoStart";
import { GoogleSignInButton } from "@/components/enterprise/GoogleSignInButton";
import { brand } from "@/lib/brand";
import { safeCredentialsSignIn, safeGoogleSignIn } from "@/server/auth/safe-signin";

function loginErrorMessage(code?: string): string {
  switch ((code || "").trim()) {
    case "CredentialsSignin":
      return "Email or password is incorrect, or the email is not verified yet. Register and confirm your email first.";
    case "AccessDenied":
      return "Sign-in was denied. If you tried too many times, wait a few minutes and try again.";
    case "Configuration":
    case "MissingSecret":
      return "Sign-in is temporarily unavailable (server configuration). Please try again shortly or use Google.";
    case "OAuthSignInError":
    case "OAuthCallbackError":
      return "Google sign-in failed. Try again, or use your verified email and password.";
    case "Verification":
      return "Please verify your email before signing in.";
    default:
      return code
        ? "Sign-in failed. Try Google again, or use your verified email and password."
        : "";
  }
}

export default async function LoginPage({
  searchParams,
}: {
  searchParams: Promise<{ callbackUrl?: string; error?: string; provider?: string; return?: string }>;
}) {
  // Stale cookies or transient auth config issues must not crash the login screen.
  let session: Session | null = null;
  try {
    session = await auth();
  } catch {
    session = null;
  }
  if (session?.user) redirect("/portal");

  const sp = await searchParams;
  const callbackUrl = sp.callbackUrl || sp.return || "/portal";
  const googleConfigured = (() => {
    const id = (process.env.AUTH_GOOGLE_ID || process.env.GOOGLE_CLIENT_ID || "").trim();
    const secret = (process.env.AUTH_GOOGLE_SECRET || process.env.GOOGLE_CLIENT_SECRET || "").trim();
    return id.includes(".apps.googleusercontent.com") && secret.length >= 20;
  })();
  const preferGoogle = (sp.provider || "").toLowerCase() === "google" && googleConfigured && !sp.error;
  const errorText = loginErrorMessage(sp.error);

  return (
    <EnterpriseShell>
      <div className="e-login-page e-login-page--shell">
        <div className="e-login-bg" aria-hidden="true">
          <div className="e-login-bg-gradient" />
          <FinancialParticles density={40} />
          <div className="e-login-bg-illustration" />
        </div>

        <div className="e-login-shell">
          <div className="e-login-card e-glass-card e-login-glass">
            <div className="e-login-brand">
              <BrandLogo variant="login" priority className="e-brand-logo e-brand-logo--login" />
              <p className="e-login-eyebrow">{brand.brandName}</p>
              <h1 className="e-login-title">Customer Portal</h1>
              <p className="e-login-sub">
                Sign in with a verified account. New users must register and confirm email first.
              </p>
            </div>

            {errorText && (
              <p className="e-login-error" role="alert">
                {errorText}
              </p>
            )}

            <div className="e-login-actions">
              {preferGoogle && (
                <form
                  id="google-auto-signin"
                  action={async () => {
                    "use server";
                    await safeGoogleSignIn({ callbackUrl });
                  }}
                >
                  <GoogleAutoStart enabled formId="google-auto-signin" />
                </form>
              )}

              <GoogleSignInButton callbackUrl={callbackUrl} configured={googleConfigured} />

              <div className="e-login-divider">
                <span>Or sign in with email</span>
              </div>

              <form
                action={async (fd) => {
                  "use server";
                  const email = String(fd.get("email") || "");
                  const password = String(fd.get("password") || "");
                  await safeCredentialsSignIn({ email, password, callbackUrl });
                }}
                className="e-form"
              >
                <div className="e-field">
                  <label htmlFor="email">Email</label>
                  <input id="email" name="email" type="email" placeholder="you@company.com" required autoComplete="email" />
                </div>
                <div className="e-field">
                  <label htmlFor="password">Password</label>
                  <input
                    id="password"
                    name="password"
                    type="password"
                    placeholder="••••••••"
                    required
                    minLength={8}
                    autoComplete="current-password"
                  />
                </div>
                <button type="submit" className="e-btn e-btn-ghost e-btn--full">
                  Sign In
                </button>
              </form>

              <p className="e-login-oauth-note" style={{ textAlign: "center" }}>
                <Link href="/forgot-password">Forgot password?</Link>
                {" · "}
                <Link href="/resend-verification">Resend verification email</Link>
              </p>

              <p className="e-login-oauth-note" style={{ textAlign: "center" }}>
                No account yet? <Link href="/register">Create account</Link>
              </p>
            </div>

            <p className="e-login-footer-note">
              Trading involves substantial risk of loss. This portal does not execute trades.
            </p>
          </div>
        </div>
      </div>
    </EnterpriseShell>
  );
}
