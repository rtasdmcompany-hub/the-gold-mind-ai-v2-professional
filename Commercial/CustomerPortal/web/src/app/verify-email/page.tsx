import type { Metadata } from "next";
import Link from "next/link";
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
  searchParams: Promise<{ token?: string; email?: string }>;
}) {
  const sp = await searchParams;
  const token = (sp.token || "").trim();
  const email = (sp.email || "").trim();

  let ok = false;
  let message = "Missing verification token.";
  if (token && email) {
    const result = await verifyAccountEmail(email, token);
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
          <h1 className="e-section-title">{ok ? "Email confirmed" : "Verification needed"}</h1>
          <p className="e-section-sub">
            {ok
              ? "Password sign-in is unlocked for this account."
              : "Open the link from your confirmation email, or register again if the link expired."}
          </p>
        </ScrollReveal>
      </div>
      <section className="e-section" style={{ paddingTop: 0 }}>
        <div className="e-container" style={{ maxWidth: 520 }}>
          <ScrollReveal>
            <div className="e-glass-card">
              <p>{message}</p>
              <div className="e-btn-group" style={{ marginTop: 20 }}>
                <Link href="/login" className="e-btn e-btn-primary">
                  Sign In
                </Link>
                <Link href="/register" className="e-btn e-btn-ghost">
                  Register
                </Link>
              </div>
            </div>
          </ScrollReveal>
        </div>
      </section>
    </EnterpriseShell>
  );
}
