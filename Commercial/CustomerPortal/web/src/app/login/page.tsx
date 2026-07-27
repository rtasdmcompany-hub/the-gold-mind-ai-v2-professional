import { auth, signIn } from "@/auth";
import { redirect } from "next/navigation";
import { BrandLogo } from "@/components/BrandLogo";
import { FinancialParticles } from "@/components/enterprise/FinancialParticles";
import { GoogleSignInButton } from "@/components/enterprise/GoogleSignInButton";
import { shouldEnableDemoAuth } from "@/server/security/dev-bypass";

export default async function LoginPage({
  searchParams,
}: {
  searchParams: Promise<{ callbackUrl?: string; error?: string }>;
}) {
  const session = await auth();
  if (session?.user) redirect("/portal");

  const sp = await searchParams;
  const callbackUrl = sp.callbackUrl || "/portal";
  const googleConfigured = !!(process.env.GOOGLE_CLIENT_ID && process.env.GOOGLE_CLIENT_SECRET);
  const demoAllowed = shouldEnableDemoAuth(googleConfigured);

  return (
    <div className="e-login-page">
      <div className="e-login-bg" aria-hidden="true">
        <div className="e-login-bg-gradient" />
        <FinancialParticles density={40} />
        <div className="e-login-bg-illustration" />
      </div>

      <div className="e-login-shell">
        <div className="e-login-card e-glass-card e-login-glass">
          <div className="e-login-brand">
            <BrandLogo variant="login" priority className="e-brand-logo e-brand-logo--login" />
            <p className="e-login-eyebrow">RTAS GROUP OF COMPANIES</p>
            <h1 className="e-login-title">Customer Portal</h1>
            <p className="e-login-sub">
              Secure access to licenses, downloads, billing, and professional support.
            </p>
          </div>

          {sp.error && (
            <p className="e-login-error" role="alert">
              Sign-in could not be completed. Please try again.
            </p>
          )}

          <div className="e-login-actions">
            <GoogleSignInButton callbackUrl={callbackUrl} configured={googleConfigured} />

            {!googleConfigured && (
              <p className="e-login-oauth-note">
                Google Sign-In requires production OAuth credentials from the Owner.
              </p>
            )}

            {demoAllowed && (
              <>
                <div className="e-login-divider">
                  <span>Internal access</span>
                </div>
                <form
                  action={async (fd) => {
                    "use server";
                    const email = String(fd.get("email") || "demo@goldmind.local");
                    await signIn("demo", { email, redirectTo: callbackUrl });
                  }}
                  className="e-form"
                >
                  <div className="e-field">
                    <label htmlFor="email">Email</label>
                    <input id="email" name="email" type="email" placeholder="you@company.com" required />
                  </div>
                  <button type="submit" className="e-btn e-btn-ghost e-btn--full">
                    Continue with Email
                  </button>
                </form>
              </>
            )}
          </div>

          <p className="e-login-footer-note">
            Trading involves substantial risk of loss. This portal does not execute trades.
          </p>
        </div>
      </div>
    </div>
  );
}
