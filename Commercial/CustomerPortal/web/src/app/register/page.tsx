import type { Metadata } from "next";
import Link from "next/link";
import { EnterpriseShell } from "@/components/enterprise/EnterpriseShell";
import { ScrollReveal } from "@/components/enterprise/ScrollReveal";

export const metadata: Metadata = {
  title: "Register — THE GOLD MIND PROFESSIONAL",
  description: "Invite-only registration for THE GOLD MIND PROFESSIONAL Controlled Launch.",
};

export default async function RegisterPage({
  searchParams,
}: {
  searchParams: Promise<{ invite?: string }>;
}) {
  const sp = await searchParams;
  const invite = (sp.invite || "").trim();
  const openSignup = process.env.PORTAL_OPEN_SIGNUP === "true";

  return (
    <EnterpriseShell>
      <div className="e-page-hero e-container">
        <ScrollReveal>
          <p className="e-eyebrow">THE GOLD MIND PROFESSIONAL</p>
          <h1 className="e-section-title">Create Account</h1>
        </ScrollReveal>
      </div>
      <section className="e-section" style={{ paddingTop: 0 }}>
        <div className="e-container" style={{ maxWidth: 520 }}>
          <ScrollReveal>
            {!openSignup && !invite ? (
              <div className="e-glass-card">
                <p>
                  Public registration is closed during Controlled Launch. Use an invite link from RTAS, or{" "}
                  <Link href="/login">sign in</Link> if you already have access.
                </p>
                <p style={{ fontSize: 13, color: "var(--e-text-dim)", marginTop: 16 }}>
                  Email verification and license purchase continue inside the Customer Portal after invite acceptance.
                </p>
              </div>
            ) : (
              <form className="e-glass-card e-form" action="/login">
                <input type="hidden" name="invite" value={invite} />
                <div className="e-field">
                  <label htmlFor="email">Work email</label>
                  <input id="email" name="email" type="email" required />
                </div>
                <p style={{ fontSize: 13, color: "var(--e-text-muted)" }}>
                  After sign-in, complete email verification (when enabled), purchase a plan, activate your license,
                  then download the installer.
                </p>
                <button type="submit" className="e-btn e-btn-primary">
                  Continue to Sign In
                </button>
              </form>
            )}
          </ScrollReveal>
        </div>
      </section>
    </EnterpriseShell>
  );
}
