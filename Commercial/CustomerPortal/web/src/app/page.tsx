import Link from "next/link";
import type { Metadata } from "next";
import { EnterpriseShell } from "@/components/enterprise/EnterpriseShell";
import { HeroBackground } from "@/components/enterprise/HeroBackground";
import { HeroDashboard } from "@/components/enterprise/HeroDashboard";
import { ScrollReveal } from "@/components/enterprise/ScrollReveal";
import { SoftwareShowcase } from "@/components/enterprise/SoftwareShowcase";
import { TrustSection } from "@/components/enterprise/TrustSection";
import { AiAssistantWidget } from "@/components/AiAssistantWidget";

export const metadata: Metadata = {
  title: "Official Website",
  description:
    "THE GOLD MIND AI v2.0 PROFESSIONAL — institutional-grade MetaTrader 5 Expert Advisor. Licensed, certified, and enterprise-ready.",
};

const FEATURES = [
  {
    icon: "◆",
    title: "Certified Core Engine",
    desc: "Frozen SHA-256 certified trading core operating exclusively on MetaTrader 5 Professional.",
  },
  {
    icon: "◇",
    title: "AI Signal Intelligence",
    desc: "Advanced pattern recognition and systematic execution with institutional risk parameters.",
  },
  {
    icon: "⬡",
    title: "Enterprise Portal",
    desc: "Unified licensing, downloads, device management, and subscription billing in one secure hub.",
  },
  {
    icon: "◈",
    title: "Global Infrastructure",
    desc: "Cloud-isolated commercial services with encrypted stores, audit trails, and health monitoring.",
  },
  {
    icon: "◎",
    title: "Professional Updates",
    desc: "Checksum-verified installers and controlled release channels for every deployment.",
  },
  {
    icon: "◉",
    title: "Dedicated Support",
    desc: "Knowledge base, ticket intake, and AI-assisted guidance for licensed customers worldwide.",
  },
];

export default function HomePage() {
  return (
    <EnterpriseShell navTransparent>
      <section className="e-hero">
        <HeroBackground />
        <div className="e-hero-grid">
          <ScrollReveal className="e-hero-content">
            <p className="e-eyebrow">THE GOLD MIND AI · v2.0 Professional</p>
            <h1 className="e-hero-title">Institutional AI Trading Software</h1>
            <p className="e-lead">
              Systematic MetaTrader 5 automation with certified Core integrity, enterprise licensing, and global
              infrastructure.
            </p>
            <div className="e-btn-group">
              <Link href="/pricing" className="e-btn e-btn-primary">
                View Pricing
              </Link>
              <Link href="/login" className="e-btn e-btn-ghost">
                Customer Portal
              </Link>
            </div>
          </ScrollReveal>
          <ScrollReveal delay={2}>
            <HeroDashboard />
          </ScrollReveal>
        </div>
      </section>

      <hr className="e-divider" />

      <section className="e-section">
        <div className="e-container">
          <ScrollReveal>
            <div className="e-section-header">
              <p className="e-eyebrow">Capabilities</p>
              <h2 className="e-section-title">Engineered for professional traders</h2>
              <p className="e-section-sub">
                Every component is designed for reliability, transparency, and institutional-grade operation.
              </p>
            </div>
          </ScrollReveal>
          <div className="e-grid-3">
            {FEATURES.map((f, i) => (
              <ScrollReveal key={f.title} delay={(i % 3) as 0 | 1 | 2}>
                <div className="e-glass-card">
                  <div className="e-icon-wrap">{f.icon}</div>
                  <h3>{f.title}</h3>
                  <p>{f.desc}</p>
                </div>
              </ScrollReveal>
            ))}
          </div>
        </div>
      </section>

      <hr className="e-divider" />
      <SoftwareShowcase />
      <hr className="e-divider" />
      <TrustSection />

      <section className="e-section">
        <div className="e-container" style={{ textAlign: "center" }}>
          <ScrollReveal>
            <p className="e-eyebrow">Get Started</p>
            <h2 className="e-section-title">Begin your professional journey</h2>
            <p className="e-section-sub">
              License THE GOLD MIND through the official Customer Portal. Trading involves substantial risk of loss.
            </p>
            <div className="e-btn-group" style={{ justifyContent: "center" }}>
              <Link href="/register" className="e-btn e-btn-primary">
                Create Account
              </Link>
              <Link href="/docs" className="e-btn e-btn-ghost">
                Read Documentation
              </Link>
            </div>
          </ScrollReveal>
        </div>
      </section>

      <AiAssistantWidget surface="website" role="anonymous" title="Ask AI" />
    </EnterpriseShell>
  );
}
