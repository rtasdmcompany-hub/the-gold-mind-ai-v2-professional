import type { Metadata } from "next";
import Link from "next/link";
import { EnterpriseShell } from "@/components/enterprise/EnterpriseShell";
import { InnerPage } from "@/components/enterprise/InnerPage";
import { ScrollReveal } from "@/components/enterprise/ScrollReveal";
import { brand } from "@/lib/brand";

export const metadata: Metadata = {
  title: `Security — ${brand.productName}`,
  description: `Enterprise security, compliance, and data protection for ${brand.brandName} commercial platform.`,
};

const CONTROLS = [
  { title: "Authentication", desc: "NextAuth JWT sessions, Google OAuth, brute-force lockout, and role-based access control." },
  { title: "Transport Security", desc: "HTTPS enforcement, HSTS, strict CSP, X-Frame-Options DENY, and nosniff headers." },
  { title: "CSRF Protection", desc: "Origin/referer validation on mutating API calls in production environments." },
  { title: "Encrypted Licensing", desc: "Device-bound license keys with online validation and encrypted store at rest." },
  { title: "Data Protection", desc: "AES-256-GCM encrypted commercial stores. No card data stored on portal servers." },
  { title: "Compliance", desc: "OWASP-aligned reviews, penetration test surfaces, MQL5 compliance workflows, and legal drafts." },
];

export default function SecurityPage() {
  return (
    <EnterpriseShell>
      <InnerPage
        eyebrow="Security & Compliance"
        title="Enterprise Protection"
        subtitle="Defense-in-depth for authentication, data, licensing, and commercial operations."
      >
        <div className="e-grid-3">
          {CONTROLS.map((item, i) => (
            <ScrollReveal key={item.title} delay={(i % 3) as 0 | 1 | 2}>
              <div className="e-glass-card">
                <div className="e-icon-wrap">◈</div>
                <h3>{item.title}</h3>
                <p>{item.desc}</p>
              </div>
            </ScrollReveal>
          ))}
        </div>
        <ScrollReveal delay={2}>
          <div className="e-glass-card" style={{ marginTop: "var(--e-space-lg)", textAlign: "center" }}>
            <p style={{ color: "var(--e-text-muted)", margin: "0 0 16px" }}>
              Review our risk disclosure and privacy policy before trading or purchasing.
            </p>
            <div className="e-btn-group" style={{ justifyContent: "center" }}>
              <Link href="/risk" className="e-btn e-btn-ghost">
                Risk Disclosure
              </Link>
              <Link href="/privacy" className="e-btn e-btn-ghost">
                Privacy Policy
              </Link>
            </div>
          </div>
        </ScrollReveal>
      </InnerPage>
    </EnterpriseShell>
  );
}
