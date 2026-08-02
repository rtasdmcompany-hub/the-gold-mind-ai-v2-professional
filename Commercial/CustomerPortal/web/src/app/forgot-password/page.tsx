import type { Metadata } from "next";
import Link from "next/link";
import { redirect } from "next/navigation";
import { EnterpriseShell } from "@/components/enterprise/EnterpriseShell";
import { ScrollReveal } from "@/components/enterprise/ScrollReveal";
import { requestPasswordReset } from "@/server/accounts/service";
import { brand } from "@/lib/brand";

export const metadata: Metadata = {
  title: `Forgot Password — ${brand.productName}`,
  description: `Request a password reset link for your ${brand.productName} Customer Portal account.`,
};

export default async function ForgotPasswordPage({
  searchParams,
}: {
  searchParams: Promise<{
    error?: string;
    sent?: string;
    email?: string;
    reset?: string;
    mailed?: string;
  }>;
}) {
  const sp = await searchParams;
  const emailDelivered = sp.mailed === "1";
  const hasResetLink = !!(sp.reset || "").trim();

  return (
    <EnterpriseShell>
      <div className="e-page-hero e-container">
        <ScrollReveal>
          <p className="e-eyebrow">Account Recovery</p>
          <h1 className="e-section-title">Forgot Password</h1>
          <p className="e-section-sub">
            Enter your account email and we&apos;ll send a password reset link if an account exists.
          </p>
        </ScrollReveal>
      </div>
      <section className="e-section" style={{ paddingTop: 0 }}>
        <div className="e-container" style={{ maxWidth: 520 }}>
          <ScrollReveal>
            {sp.sent === "1" ? (
              <div className="e-glass-card">
                <h2 style={{ marginTop: 0 }}>
                  {hasResetLink || emailDelivered ? "Reset your password" : "Check your options"}
                </h2>
                {emailDelivered ? (
                  <p>
                    A password reset email was sent to <strong>{sp.email || "that address"}</strong>.
                    It expires in 1 hour. Check Inbox and Spam/Promotions.
                  </p>
                ) : hasResetLink ? (
                  <p>
                    We could not deliver email automatically for{" "}
                    <strong>{sp.email || "that address"}</strong>. Use the secure reset link below
                    (expires in 1 hour), then sign in.
                  </p>
                ) : (
                  <p>
                    No password-reset mail could be prepared for{" "}
                    <strong>{sp.email || "that address"}</strong>. This usually means the account is
                    missing, uses Google Sign-In only, or the portal store was reset. Create the
                    account again or sign in with Google.
                  </p>
                )}
                {hasResetLink ? (
                  <p style={{ fontSize: 13, wordBreak: "break-all" }}>
                    Reset link:{" "}
                    <a href={sp.reset} style={{ color: "var(--e-gold)" }}>
                      {sp.reset}
                    </a>
                  </p>
                ) : null}
                <div className="e-btn-group" style={{ marginTop: 16, flexWrap: "wrap" }}>
                  <Link href="/login" className="e-btn e-btn-primary">
                    Sign In
                  </Link>
                  <Link href="/register" className="e-btn e-btn-ghost">
                    Create Account
                  </Link>
                  <Link href="/login?provider=google" className="e-btn e-btn-ghost">
                    Google Sign-In
                  </Link>
                </div>
              </div>
            ) : (
              <form
                className="e-glass-card e-form"
                action={async (fd) => {
                  "use server";
                  const email = String(fd.get("email") || "");
                  const result = await requestPasswordReset(email);
                  if (!result.ok) {
                    redirect(`/forgot-password?error=${encodeURIComponent(result.error)}`);
                  }
                  const q = new URLSearchParams({
                    sent: "1",
                    email: email.trim().toLowerCase(),
                    mailed: result.emailSent ? "1" : "0",
                  });
                  if (result.resetUrl) q.set("reset", result.resetUrl);
                  redirect(`/forgot-password?${q.toString()}`);
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
                  />
                </div>
                <button type="submit" className="e-btn e-btn-primary">
                  Send Reset Link
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
