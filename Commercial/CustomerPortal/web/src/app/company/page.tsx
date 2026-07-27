import type { Metadata } from "next";
import Link from "next/link";
import { EnterpriseShell } from "@/components/enterprise/EnterpriseShell";
import { InnerPage } from "@/components/enterprise/InnerPage";
import { ScrollReveal } from "@/components/enterprise/ScrollReveal";

export const metadata: Metadata = {
  title: "Company — THE GOLD MIND PROFESSIONAL",
  description: "RTAS GROUP OF COMPANIES — THE GOLD MIND AI international trading software division.",
};

export default function CompanyPage() {
  return (
    <EnterpriseShell>
      <InnerPage
        eyebrow="RTAS GROUP OF COMPANIES"
        title="Our Company"
        subtitle="An international technology group delivering professional trading software and commercial cloud services."
      >
        <div className="e-about-grid">
          <ScrollReveal>
            <div className="e-glass-card">
              <h3>Who We Are</h3>
              <p>
                THE GOLD MIND AI v2.0 PROFESSIONAL is developed by RTAS Digital Marketing Company, a division of RTAS
                GROUP OF COMPANIES. We build institutional-grade MetaTrader 5 automation with a certified, frozen Core
                engine and enterprise commercial infrastructure.
              </p>
            </div>
          </ScrollReveal>
          <ScrollReveal delay={1}>
            <div className="e-glass-card">
              <h3>What We Do</h3>
              <p>
                We license professional Expert Advisor software, operate the Customer Portal for activation and updates,
                and provide enterprise support — entirely separate from live trading execution on customer MT5
                terminals.
              </p>
            </div>
          </ScrollReveal>
        </div>
        <ScrollReveal delay={2}>
          <div className="e-glass-card" style={{ marginTop: "var(--e-space-lg)" }}>
            <h3>Leadership & Governance</h3>
            <p>
              Commercial operations follow controlled launch governance with executive certification gates, security
              audits, and counsel-reviewed legal surfaces before open Stable release.
            </p>
            <div className="e-btn-group" style={{ marginTop: 20 }}>
              <Link href="/about" className="e-btn e-btn-ghost">
                About THE GOLD MIND
              </Link>
              <Link href="/contact" className="e-btn e-btn-primary">
                Contact
              </Link>
            </div>
          </div>
        </ScrollReveal>
      </InnerPage>
    </EnterpriseShell>
  );
}
