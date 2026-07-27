import type { Metadata } from "next";
import { EnterpriseShell } from "@/components/enterprise/EnterpriseShell";
import { InnerPage } from "@/components/enterprise/InnerPage";
import { ScrollReveal } from "@/components/enterprise/ScrollReveal";

export const metadata: Metadata = {
  title: "Infrastructure — THE GOLD MIND PROFESSIONAL",
  description: "Global cloud deployment, edge infrastructure, and operational resilience.",
};

const INFRA = [
  { title: "Edge Deployment", desc: "Production on Vercel global edge with HTTPS enforcement and security headers at the middleware layer." },
  { title: "Serverless Persistence", desc: "Writable commercial data stores on serverless-safe paths with encrypted file-backed persistence." },
  { title: "Cache Layer", desc: "In-memory cache with optional Upstash Redis for multi-instance rate limiting and session affinity." },
  { title: "Audit System", desc: "Immutable audit trail for auth events, license actions, support tickets, and admin operations." },
  { title: "Disaster Recovery", desc: "Documented recovery procedures, backup snapshots, and incident response workflows." },
  { title: "Observability", desc: "Health endpoints, service metrics, and admin observability dashboards for commercial ops." },
];

export default function InfrastructurePage() {
  return (
    <EnterpriseShell>
      <InnerPage
        eyebrow="Infrastructure"
        title="Global Cloud Platform"
        subtitle="Resilient, monitored, and isolated commercial infrastructure — independent of the Trading Engine."
      >
        <div className="e-grid-3">
          {INFRA.map((item, i) => (
            <ScrollReveal key={item.title} delay={(i % 3) as 0 | 1 | 2}>
              <div className="e-glass-card">
                <div className="e-icon-wrap">⬡</div>
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
