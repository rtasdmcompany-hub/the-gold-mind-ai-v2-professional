import type { Metadata } from "next";
import Link from "next/link";
import { redirect } from "next/navigation";
import { EnterpriseShell } from "@/components/enterprise/EnterpriseShell";
import { ScrollReveal } from "@/components/enterprise/ScrollReveal";
import { resendVerificationEmail } from "@/server/accounts/service";
import { brand } from "@/lib/brand";

export const metadata: Metadata = {
  title: `Resend Verification — ${brand.productName}`,
  description: `Resend the email confirmation link for your ${brand.productName} Customer Portal account.`,
};

export default async function ResendVerificationPage({
  searchParams,
}: {
  searchParams: Promise<{
    error?: string;
    sent?: string;
    email?: string;
    verify?: string;
    mailed?: string;
    verified?: string;
  }>;
}) {
  const sp = await searchParams;
  const emailDelivered = sp.mailed === "1";

  return (
    <EnterpriseShell>
      <div className="e-page-hero e-container">
        <ScrollReveal>
          <p className="e-eyebrow">{brand.productName}</p>
          <h1 className="e-section-title">Resend Verification</h1>
          <p className="e-section-sub">
            Did not get the confirmation email? Enter your address and we will send a new link.
          </p>
        </ScrollReveal>
      </div>
      <section className="e-section" style={{ paddingTop: 0 }}>
        <div className="e-container" style={{ maxWidth: 520 }}>
          <ScrollReveal>
            {sp.verified === "1" ? (
              <div className="e-glass-card">
                <h2 style={{ marginTop: 0 }}>Already verified</h2>
                <p>
                  <strong>{sp.email || "This email"}</strong> is already confirmed. You can sign in now.
                </p>
                <p style={{ fontSize: 13, marginBottom: 0 }}>
                  <Link href="/login">Sign in</Link>
                </p>
              </div>
            ) : sp.sent === "1" ? (
              <div className="e-glass-card">
                <h2 style={{ marginTop: 0 }}>
                  {emailDelivered ? "Confirmation resent" : "Request received"}
                </h2>
                {emailDelivered ? (
                  <p>
                    A new confirmation email was sent to <strong>{sp.email || "your email"}</strong>. Open
                    the link to activate your account, then sign in. Check Spam/Promotions if needed.
                  </p>
                ) : (
                  <p>
                    If an unverified account exists for <strong>{sp.email || "that address"}</strong>, use
                    the verification link below (or try again shortly if mail delivery is delayed).
                  </p>
                )}
                {sp.verify ? (
                  <p style={{ fontSize: 13, wordBreak: "break-all" }}>
                    Verification link:{" "}
                    <a href={sp.verify} style={{ color: "var(--e-gold)" }}>
                      {sp.verify}
                    </a>
                  </p>
                ) : null}
                <form
                  className="e-form"
                  style={{ marginTop: 16 }}
                  action={async () => {
                    "use server";
                    const email = String(sp.email || "");
                    const result = await resendVerificationEmail(email);
                    if (!result.ok) {
                      redirect(`/resend-verification?error=${encodeURIComponent(result.error)}&email=${encodeURIComponent(email)}`);
                    }
                    if (result.alreadyVerified) {
                      redirect(
                        `/resend-verification?verified=1&email=${encodeURIComponent(result.email)}`
                      );
                    }
                    const q = new URLSearchParams({
                      sent: "1",
                      email: result.email,
                      mailed: result.emailSent ? "1" : "0",
                    });
                    if (result.verifyUrl) q.set("verify", result.verifyUrl);
                    redirect(`/resend-verification?${q.toString()}`);
                  }}
                >
                  <button type="submit" className="e-btn e-btn-ghost e-btn--full">
                    Resend email again
                  </button>
                </form>
                <p style={{ fontSize: 13, marginBottom: 0, marginTop: 12 }}>
                  Already confirmed? <Link href="/login">Sign in</Link>
                </p>
              </div>
            ) : (
              <form
                className="e-glass-card e-form"
                action={async (fd) => {
                  "use server";
                  const email = String(fd.get("email") || "");
                  const result = await resendVerificationEmail(email);
                  if (!result.ok) {
                    redirect(
                      `/resend-verification?error=${encodeURIComponent(result.error)}&email=${encodeURIComponent(email.trim().toLowerCase())}`
                    );
                  }
                  if (result.alreadyVerified) {
                    redirect(
                      `/resend-verification?verified=1&email=${encodeURIComponent(result.email)}`
                    );
                  }
                  const q = new URLSearchParams({
                    sent: "1",
                    email: result.email,
                    mailed: result.emailSent ? "1" : "0",
                  });
                  if (result.verifyUrl) q.set("verify", result.verifyUrl);
                  redirect(`/resend-verification?${q.toString()}`);
                }}
              >
                {sp.error && (
                  <p className="e-login-error" role="alert">
                    {sp.error}
                  </p>
                )}
                <div className="e-field">
                  <label htmlFor="email">Account email</label>
                  <input
                    id="email"
                    name="email"
                    type="email"
                    placeholder="you@company.com"
                    required
                    autoComplete="email"
                    defaultValue={sp.email || ""}
                  />
                </div>
                <button type="submit" className="e-btn e-btn-primary">
                  Resend Verification Email
                </button>
                <p style={{ fontSize: 13, marginBottom: 0 }}>
                  <Link href="/login">Back to sign in</Link>
                  {" · "}
                  <Link href="/register">Create account</Link>
                </p>
              </form>
            )}
          </ScrollReveal>
        </div>
      </section>
    </EnterpriseShell>
  );
}
