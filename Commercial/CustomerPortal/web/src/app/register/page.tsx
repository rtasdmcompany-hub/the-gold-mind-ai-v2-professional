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
  searchParams: Promise<{ error?: string; sent?: string; email?: string; verify?: string }>;
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
            Register with your email, confirm the verification link, then sign in.
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
                <p>
                  We prepared a confirmation for <strong>{sp.email || "your email"}</strong>. Open the verification
                  link to activate your account, then sign in.
                </p>
                {sp.verify ? (
                  <p style={{ fontSize: 13, wordBreak: "break-all" }}>
                    Verification link:{" "}
                    <a href={sp.verify} style={{ color: "var(--e-gold)" }}>
                      {sp.verify}
                    </a>
                  </p>
                ) : (
                  <p style={{ fontSize: 13, color: "var(--e-text-muted)" }}>
                    Check your inbox (and spam). After confirmation, use <Link href="/login">Sign in</Link>.
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
                  const q = new URLSearchParams({ sent: "1", email: result.email });
                  if (result.verifyUrl) q.set("verify", result.verifyUrl);
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
                  You must confirm your email before you can sign in. Google Sign-In also creates a verified account.
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
