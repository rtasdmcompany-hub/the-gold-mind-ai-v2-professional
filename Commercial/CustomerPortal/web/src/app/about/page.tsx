import type { Metadata } from "next";
import Link from "next/link";
import { EnterpriseShell } from "@/components/enterprise/EnterpriseShell";
import { ScrollReveal } from "@/components/enterprise/ScrollReveal";
import { brand } from "@/lib/brand";

export const metadata: Metadata = {
  title: `About — ${brand.productName}`,
  description: `Mission, vision, technology, and global presence of ${brand.productFullName}.`,
};

export default function AboutPage() {
  return (
    <EnterpriseShell>
      <div className="e-page-hero e-container">
        <ScrollReveal>
          <p className="e-eyebrow">{brand.brandName}</p>
          <h1 className="e-section-title">About {brand.brandName}</h1>
          <p className="e-section-sub">
            An international AI trading software company delivering institutional-grade automation on MetaTrader 5.
          </p>
        </ScrollReveal>
      </div>

      <section className="e-section" id="mission">
        <div className="e-container e-about-grid">
          <ScrollReveal>
            <p className="e-eyebrow">Mission</p>
            <h2 className="e-section-title" style={{ textAlign: "left", fontSize: "2rem" }}>
              Empower professional traders with certified AI infrastructure
            </h2>
            <p className="e-prose">
              {brand.brandName} delivers systematic, transparent, and professionally managed automated trading through a
              certified Core engine isolated from all commercial cloud services. Our mission is to provide enterprise
              traders with technology they can trust.
            </p>
          </ScrollReveal>
          <ScrollReveal delay={1}>
            <p className="e-eyebrow">Vision</p>
            <h2 className="e-section-title" style={{ textAlign: "left", fontSize: "2rem" }}>
              Global standard for AI-assisted trading software
            </h2>
            <p className="e-prose">
              We envision a world where institutional-quality trading automation is accessible through secure licensing,
              professional support, and uncompromising Core integrity — without sacrificing transparency or risk
              disclosure.
            </p>
          </ScrollReveal>
        </div>
      </section>

      <hr className="e-divider" />

      <section className="e-section e-section--alt" id="technology">
        <div className="e-container">
          <ScrollReveal>
            <div className="e-section-header">
              <p className="e-eyebrow">Technology</p>
              <h2 className="e-section-title">Enterprise architecture</h2>
            </div>
          </ScrollReveal>
          <div className="e-grid-3">
            {[
              {
                title: "Certified Core",
                desc: "SHA-256 frozen Expert Advisor on MT5. Never modified by cloud services.",
              },
              {
                title: "Cloud Isolation",
                desc: "Commercial portal, licensing, and billing operate in complete separation from trading execution.",
              },
              {
                title: "Encrypted Stores",
                desc: "AES-256-GCM encrypted commercial data with audit trails and health monitoring.",
              },
              {
                title: "AI Assistant",
                desc: "Knowledge-grounded commercial support AI — never exposes trading logic or Core internals.",
              },
              {
                title: "Update Pipeline",
                desc: "Checksum-verified releases with SHA-256 checksums and controlled distribution channels.",
              },
              {
                title: "API Platform",
                desc: "Versioned REST API for licenses, subscriptions, and partner integrations.",
              },
            ].map((t, i) => (
              <ScrollReveal key={t.title} delay={(i % 3) as 0 | 1 | 2}>
                <div className="e-glass-card">
                  <h3>{t.title}</h3>
                  <p>{t.desc}</p>
                </div>
              </ScrollReveal>
            ))}
          </div>
        </div>
      </section>

      <section className="e-section" id="security">
        <div className="e-container e-about-grid">
          <ScrollReveal>
            <p className="e-eyebrow">Security & Compliance</p>
            <h2 className="e-section-title" style={{ textAlign: "left", fontSize: "2rem" }}>
              Enterprise-grade protection
            </h2>
            <p className="e-prose">
              HTTPS enforcement, CSP headers, CSRF protection, encrypted licensing, device fingerprint binding, and
              comprehensive audit logging across the Customer Portal.
            </p>
          </ScrollReveal>
          <ScrollReveal delay={1}>
            <p className="e-eyebrow">Certifications</p>
            <h2 className="e-section-title" style={{ textAlign: "left", fontSize: "2rem" }}>
              Professional standards
            </h2>
            <p className="e-prose">
              Core integrity certification, MQL5 compliance workflows, penetration testing surfaces, OWASP-aligned
              security reviews, and production deployment certification gates.
            </p>
          </ScrollReveal>
        </div>
      </section>

      <section className="e-section e-section--alt" id="global">
        <div className="e-container" style={{ textAlign: "center" }}>
          <ScrollReveal>
            <p className="e-eyebrow">Global Presence</p>
            <h2 className="e-section-title">International by design</h2>
            <p className="e-section-sub">
              Deployed on global edge infrastructure with multi-region readiness, i18n support, and regional compliance
              configuration. Product of {brand.brandName}.
            </p>
            <Link href="/contact" className="e-btn e-btn-primary">
              Contact Us
            </Link>
          </ScrollReveal>
        </div>
      </section>
    </EnterpriseShell>
  );
}
