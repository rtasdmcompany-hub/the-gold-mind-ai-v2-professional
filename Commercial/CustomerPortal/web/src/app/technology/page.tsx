import type { Metadata } from "next";
import { EnterpriseShell } from "@/components/enterprise/EnterpriseShell";
import { InnerPage } from "@/components/enterprise/InnerPage";
import { ScrollReveal } from "@/components/enterprise/ScrollReveal";

export const metadata: Metadata = {
  title: "Technology — THE GOLD MIND PROFESSIONAL",
  description: "AI infrastructure, certified Core engine, and enterprise cloud architecture.",
};

const STACK = [
  { title: "Certified Core EA", desc: "SHA-256 frozen Expert Advisor on MetaTrader 5 Professional. Never modified by cloud services." },
  { title: "AI Signal Layer", desc: "Commercial AI assistant and analytics operate outside the trading execution path." },
  { title: "Encrypted Stores", desc: "AES-256-GCM licensing, billing, audit, and support data with serverless-safe persistence." },
  { title: "API Platform", desc: "Versioned REST API v1 for licenses, subscriptions, webhooks, and partner integrations." },
  { title: "Update Pipeline", desc: "Signed installers, SHA-256 checksums, rollback support, and controlled release channels." },
  { title: "Health Monitoring", desc: "Real-time service health checks across auth, licensing, billing, and portal subsystems." },
];

export default function TechnologyPage() {
  return (
    <EnterpriseShell>
      <InnerPage
        eyebrow="Technology"
        title="Enterprise Architecture"
        subtitle="Purpose-built separation between certified trading execution and commercial cloud services."
      >
        <div className="e-grid-3">
          {STACK.map((item, i) => (
            <ScrollReveal key={item.title} delay={(i % 3) as 0 | 1 | 2}>
              <div className="e-glass-card">
                <div className="e-icon-wrap">◆</div>
                <h3>{item.title}</h3>
                <p>{item.desc}</p>
              </div>
            </ScrollReveal>
          ))}
        </div>
      </InnerPage>
    </EnterpriseShell>
  );
}
