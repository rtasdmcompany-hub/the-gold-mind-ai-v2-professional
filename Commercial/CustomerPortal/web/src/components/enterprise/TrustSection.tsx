import { ScrollReveal } from "./ScrollReveal";

const TRUST = [
  { icon: "◆", title: "Verified MT5 Technology", desc: "Certified Expert Advisor on MetaTrader 5 Professional platform." },
  { icon: "◇", title: "AI Infrastructure", desc: "Enterprise-grade signal processing and risk-aware automation." },
  { icon: "⬡", title: "Enterprise Security", desc: "Encrypted licensing, audit trails, and hardened cloud isolation." },
  { icon: "◈", title: "Encrypted Licensing", desc: "Device-bound keys with online validation and secure delivery." },
  { icon: "◎", title: "Professional Support", desc: "Dedicated support center with ticket intake and knowledge base." },
  { icon: "◉", title: "Global Availability", desc: "International deployment with regional compliance readiness." },
  { icon: "▣", title: "Risk Management", desc: "Built-in safeguards separate from the certified Core engine." },
  { icon: "◐", title: "Compliance Ready", desc: "Enterprise documentation, legal surfaces, and audit workflows." },
];

export function TrustSection() {
  return (
    <section className="e-section e-section--alt" id="trust">
      <div className="e-container">
        <ScrollReveal>
          <div className="e-section-header">
            <p className="e-eyebrow">Trust & Security</p>
            <h2 className="e-section-title">Built for institutional confidence</h2>
            <p className="e-section-sub">
              Every layer of THE GOLD MIND ecosystem is engineered for transparency, security, and professional
              operation.
            </p>
          </div>
        </ScrollReveal>
        <div className="e-trust-grid">
          {TRUST.map((t, i) => (
            <ScrollReveal key={t.title} delay={(i % 3) as 0 | 1 | 2}>
              <div className="e-trust-item">
                <div className="e-trust-icon">{t.icon}</div>
                <h4>{t.title}</h4>
                <p>{t.desc}</p>
              </div>
            </ScrollReveal>
          ))}
        </div>
      </div>
    </section>
  );
}
