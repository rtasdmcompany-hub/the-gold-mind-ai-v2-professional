import type { Metadata } from "next";
import Link from "next/link";
import { redirect } from "next/navigation";
import { EnterpriseShell } from "@/components/enterprise/EnterpriseShell";
import { ScrollReveal } from "@/components/enterprise/ScrollReveal";
import { verifyAccountEmail } from "@/server/accounts/service";
import { brand } from "@/lib/brand";

export const metadata: Metadata = {
  title: `Verify Email — ${brand.productName}`,
};

export default async function VerifyEmailPage({
  searchParams,
}: {
  searchParams: Promise<{
    token?: string;
    email?: string;
    code?: string;
    error?: string;
    confirmed?: string;
  }>;
}) {
  const sp = await searchParams;
  const token = (sp.token || "").trim();
  const code = (sp.code || "").trim();
  const email = (sp.email || "").trim();
  const secret = token || code;

  let ok = sp.confirmed === "1";
  let autoAttempted = false;
  let message = ok
    ? "Your email is confirmed. You can sign in with your password now."
    : "";

  if (!ok && secret && email) {
    autoAttempted = true;
    const result = await verifyAccountEmail(email, secret);
    ok = result.ok;
    message = result.ok
      ? "Your email is confirmed. You can sign in with your password now."
      : result.error || "Verification failed.";
  }

  return (
    <EnterpriseShell>
      <div className="e-page-hero e-container">
        <ScrollReveal>
          <p className="e-eyebrow">Account verification</p>
          <h1 className="e-section-title">{ok ? "Email confirmed" : "Confirm your email"}</h1>
          <p className="e-section-sub">
            {ok
              ? "Password sign-in is unlocked for this account."
              : "Enter the 6-digit code from your confirmation email, or open the Confirm email button in that message."}
          </p>
        </ScrollReveal>
      </div>
      <section className="e-section" style={{ paddingTop: 0 }}>
        <div className="e-container" style={{ maxWidth: 520 }}>
          <ScrollReveal>
            <div className="e-glass-card">
              {ok ? (
                <>
                  <p>{message}</p>
                  <div className="e-btn-group" style={{ marginTop: 20 }}>
                    <Link href="/login" className="e-btn e-btn-primary">
                      Sign In
                    </Link>
                  </div>
                </>
              ) : (
                <>
                  {(autoAttempted || sp.error) && (
                    <p className="e-login-error" role="alert">
                      {sp.error || message || "Verification failed."}
                    </p>
                  )}
                  <form
                    className="e-form"
                    action={async (fd) => {
                      "use server";
                      const formEmail = String(fd.get("email") || "").trim();
                      const formCode = String(fd.get("code") || "").trim();
                      const result = await verifyAccountEmail(formEmail, formCode);
                      if (result.ok) {
                        redirect(
                          `/verify-email?confirmed=1&email=${encodeURIComponent(formEmail)}`
                        );
                      }
                      redirect(
                        `/verify-email?email=${encodeURIComponent(formEmail)}&error=${encodeURIComponent(result.error || "Invalid code")}`
                      );
                    }}
                  >
                    <div className="e-field">
                      <label htmlFor="email">Email</label>
                      <input
                        id="email"
                        name="email"
                        type="email"
                        required
                        autoComplete="email"
                        defaultValue={email}
                      />
                    </div>
                    <div className="e-field">
                      <label htmlFor="code">Verification code</label>
                      <input
                        id="code"
                        name="code"
                        type="text"
                        inputMode="numeric"
                        pattern="[0-9]{6}"
                        maxLength={6}
                        minLength={6}
                        required
                        placeholder="6-digit code"
                        autoComplete="one-time-code"
                        style={{ letterSpacing: "0.28em", fontWeight: 700, fontSize: 18 }}
                      />
                    </div>
                    <button type="submit" className="e-btn e-btn-primary e-btn--full">
                      Confirm email
                    </button>
                  </form>
                  <p style={{ fontSize: 13, marginTop: 16, marginBottom: 0 }}>
                    No code? <Link href="/resend-verification">Resend verification email</Link>
                    {" · "}
                    <Link href="/login">Sign in</Link>
                  </p>
                </>
              )}
            </div>
          </ScrollReveal>
        </div>
      </section>
    </EnterpriseShell>
  );
}
