import { EnterpriseShell } from "@/components/enterprise/EnterpriseShell";
import { ScrollReveal } from "@/components/enterprise/ScrollReveal";

export function LegalShell({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <EnterpriseShell>
      <div className="e-page-hero e-container">
        <ScrollReveal>
          <p className="e-eyebrow">THE GOLD MIND PROFESSIONAL</p>
          <h1 className="e-section-title">{title}</h1>
          <p className="e-section-sub">
            Production legal draft — OWNER REVIEW REQUIRED before open commercial launch.
          </p>
        </ScrollReveal>
      </div>
      <section className="e-section" style={{ paddingTop: 0 }}>
        <div className="e-container e-prose">
          <ScrollReveal>{children}</ScrollReveal>
          <p style={{ marginTop: 32, fontSize: 13, color: "var(--e-text-dim)" }}>
            Core Trading Engine operation on MetaTrader is independent of this commercial website policy surface.
          </p>
        </div>
      </section>
    </EnterpriseShell>
  );
}
