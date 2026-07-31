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
  searchParams: Promise<{ error?: string; sent?: string; email?: string; reset?: string }>;
}) {
  const sp = await searchParams;

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
                <h2 style={{ marginTop: 0 }}>Check your email</h2>
                <p>
                  If an account exists for <strong>{sp.email || "that address"}</strong>, we sent a password reset
                  link. It expires in 1 hour.
                </p>
                {sp.reset ? (
                  <p style={{ fontSize: 13, wordBreak: "break-all" }}>
                    Reset link:{" "}
                    <a href={sp.reset} style={{ color: "var(--e-gold)" }}>
                      {sp.reset}
                    </a>
                  </p>
                ) : (
                  <p style={{ fontSize: 13, color: "var(--e-text-muted)" }}>
                    Check your inbox (and spam) for the reset link.
                  </p>
                )}
                <p style={{ fontSize: 13, marginBottom: 0 }}>
                  Remembered it? <Link href="/login">Sign in</Link>
                </p>
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
                  const q = new URLSearchParams({ sent: "1", email: email.trim().toLowerCase() });
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
                  <input id="email" name="email" type="email" placeholder="you@company.com" required autoComplete="email" />
                </div>
                <button type="submit" className="e-btn e-btn-primary">
                  Send Reset Link
                </button>
                <p style={{ fontSize: 13, marginBottom: 0 }}>
                  <Link href="/login">Back to sign in</Link>
                </p>
              </form>
            )}
          </ScrollReveal>
        </div>
      </section>
    </EnterpriseShell>
  );
}
