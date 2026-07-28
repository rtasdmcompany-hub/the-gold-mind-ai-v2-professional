import type { Metadata } from "next";
import Link from "next/link";
import { redirect } from "next/navigation";
import { EnterpriseShell } from "@/components/enterprise/EnterpriseShell";
import { ScrollReveal } from "@/components/enterprise/ScrollReveal";
import { registerAccount } from "@/server/accounts/service";

export const metadata: Metadata = {
  title: "Register — THE GOLD MIND PROFESSIONAL",
  description: "Create a verified Customer Portal account for THE GOLD MIND PROFESSIONAL.",
};

export default async function RegisterPage({
  searchParams,
}: {
  searchParams: Promise<{
    error?: string;
    sent?: string;
    email?: string;
    verify?: string;
    emailed?: string;
    mailError?: string;
  }>;
}) {
  const sp = await searchParams;
  const openSignup = process.env.PORTAL_OPEN_SIGNUP !== "false";

  return (
    <EnterpriseShell>
      <div className="e-page-hero e-container">
        <ScrollReveal>
          <p className="e-eyebrow">THE GOLD MIND PROFESSIONAL</p>
          <h1 className="e-section-title">Create Account</h1>
          <p className="e-section-sub">
            Register with your email. Confirm via the verification link before password sign-in.
          </p>
        </ScrollReveal>
      </div>
      <section className="e-section" style={{ paddingTop: 0 }}>
        <div className="e-container" style={{ maxWidth: 520 }}>
          <ScrollReveal>
            {!openSignup ? (
              <div className="e-glass-card">
                <p>
                  Public registration is temporarily closed. <Link href="/login">Sign in</Link> if you already have
                  an account, or <Link href="/contact">contact sales</Link>.
                </p>
              </div>
            ) : sp.sent === "1" ? (
              <div className="e-glass-card">
                <h2 style={{ marginTop: 0 }}>Confirm your email</h2>
                {sp.emailed === "1" ? (
                  <p>
                    A confirmation email was sent to <strong>{sp.email || "your email"}</strong>. Open the link to
                    verify, then sign in. Check spam/promotions if you do not see it within a few minutes.
                  </p>
                ) : (
                  <>
                    <p className="e-login-error" role="alert">
                      Account created for <strong>{sp.email || "your email"}</strong>, but the confirmation email
                      could not be delivered.
                      {sp.mailError ? ` ${sp.mailError}` : " Outbound email (Resend) is not configured or failed."}
                    </p>
                    <p>
                      Use the verification link below to confirm your account, then sign in. Ask the site owner to
                      set <code>RESEND_API_KEY</code> and <code>RESEND_FROM_EMAIL</code> for automatic delivery.
                    </p>
                  </>
                )}
                {sp.verify ? (
                  <p style={{ fontSize: 13, wordBreak: "break-all" }}>
                    Verification link:{" "}
                    <a href={sp.verify} style={{ color: "var(--e-gold)" }}>
                      {sp.verify}
                    </a>
                  </p>
                ) : (
                  <p style={{ fontSize: 13, color: "var(--e-text-muted)" }}>
                    After confirmation, use <Link href="/login">Sign in</Link>.
                  </p>
                )}
                <p style={{ fontSize: 13, marginBottom: 0 }}>
                  Already confirmed? <Link href="/login">Sign in</Link>
                </p>
              </div>
            ) : (
              <form
                className="e-glass-card e-form"
                action={async (fd) => {
                  "use server";
                  const result = await registerAccount({
                    name: String(fd.get("name") || ""),
                    email: String(fd.get("email") || ""),
                    password: String(fd.get("password") || ""),
                  });
                  if (!result.ok) {
                    redirect(`/register?error=${encodeURIComponent(result.error)}`);
                  }
                  const q = new URLSearchParams({
                    sent: "1",
                    email: result.email,
                    emailed: result.emailSent ? "1" : "0",
                  });
                  if (result.verifyUrl) q.set("verify", result.verifyUrl);
                  if (!result.emailSent && result.mailError) {
                    q.set("mailError", result.mailError.slice(0, 240));
                  }
                  redirect(`/register?${q.toString()}`);
                }}
              >
                {sp.error && (
                  <p className="e-login-error" role="alert">
                    {sp.error}
                  </p>
                )}
                <div className="e-field">
                  <label htmlFor="name">Full name</label>
                  <input id="name" name="name" type="text" required minLength={2} autoComplete="name" />
                </div>
                <div className="e-field">
                  <label htmlFor="email">Work email</label>
                  <input id="email" name="email" type="email" required autoComplete="email" />
                </div>
                <div className="e-field">
                  <label htmlFor="password">Password</label>
                  <input
                    id="password"
                    name="password"
                    type="password"
                    required
                    minLength={8}
                    autoComplete="new-password"
                  />
                </div>
                <p style={{ fontSize: 13, color: "var(--e-text-muted)" }}>
                  Confirmation email is required before password sign-in. Google Sign-In creates a verified account.
                </p>
                <button type="submit" className="e-btn e-btn-primary">
                  Create Account
                </button>
                <p style={{ fontSize: 13, marginBottom: 0 }}>
                  Already registered? <Link href="/login">Sign in</Link>
                </p>
              </form>
            )}
          </ScrollReveal>
        </div>
      </section>
    </EnterpriseShell>
  );
}
