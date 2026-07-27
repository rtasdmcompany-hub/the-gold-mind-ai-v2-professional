import type { Metadata } from "next";
import Link from "next/link";
import { EnterpriseShell } from "@/components/enterprise/EnterpriseShell";
import { ScrollReveal } from "@/components/enterprise/ScrollReveal";
import { PLAN_CATALOG, formatMoney } from "@/server/billing/util";

export const metadata: Metadata = {
  title: "Pricing — THE GOLD MIND PROFESSIONAL",
  description: "Enterprise pricing for THE GOLD MIND AI v2.0 PROFESSIONAL. Trial, monthly, yearly, and lifetime plans.",
};

const ORDER = ["trial", "monthly", "yearly", "lifetime"] as const;

const FEATURES = [
  "Certified Core EA (MT5)",
  "Customer Portal access",
  "License activation & device binding",
  "Signed installer downloads",
  "Update center & release notes",
  "Support ticket intake",
  "Knowledge base access",
  "AI commercial assistant",
];

const COMPARE = [
  { feature: "Certified Core EA", trial: true, monthly: true, yearly: true, lifetime: true },
  { feature: "Customer Portal", trial: true, monthly: true, yearly: true, lifetime: true },
  { feature: "Device activation", trial: true, monthly: true, yearly: true, lifetime: true },
  { feature: "Installer downloads", trial: true, monthly: true, yearly: true, lifetime: true },
  { feature: "Update pipeline", trial: true, monthly: true, yearly: true, lifetime: true },
  { feature: "Priority support", trial: false, monthly: false, yearly: true, lifetime: true },
  { feature: "Lifetime updates", trial: false, monthly: false, yearly: false, lifetime: true },
];

export default function PricingPage() {
  return (
    <EnterpriseShell>
      <div className="e-page-hero e-container">
        <ScrollReveal>
          <p className="e-eyebrow">Enterprise Licensing</p>
          <h1 className="e-section-title">Professional Pricing</h1>
          <p className="e-section-sub">
            Website Edition licensing via Customer Portal. No guaranteed profits. Past performance is not future
            results.
          </p>
        </ScrollReveal>
      </div>

      <section className="e-section" style={{ paddingTop: 0 }}>
        <div className="e-container-wide">
          <div className="e-grid-4">
            {ORDER.map((code, i) => {
              const p = PLAN_CATALOG[code];
              const featured = code === "yearly";
              return (
                <ScrollReveal key={code} delay={(i % 3) as 0 | 1 | 2}>
                  <div className={`e-pricing-card ${featured ? "e-pricing-card--featured" : ""}`}>
                    {featured && <span className="e-pricing-badge">Recommended</span>}
                    <h3 style={{ fontSize: 14, letterSpacing: "0.08em", textTransform: "uppercase", color: "var(--e-gold)", margin: "0 0 8px" }}>
                      {p.label}
                    </h3>
                    <div className="e-price">
                      {p.amountCents === 0 ? "Free" : formatMoney(p.amountCents, p.currency)}
                    </div>
                    <div className="e-price-interval">/{p.interval}</div>
                    <ul style={{ listStyle: "none", padding: 0, margin: "24px 0", fontSize: 13, color: "var(--e-text-muted)" }}>
                      {FEATURES.slice(0, featured ? 8 : 6).map((f) => (
                        <li key={f} style={{ padding: "6px 0", borderBottom: "1px solid var(--e-border)" }}>
                          <span className="e-check">✓</span> {f}
                        </li>
                      ))}
                    </ul>
                    <Link href="/login" className={`e-btn ${featured ? "e-btn-primary" : "e-btn-ghost"}`} style={{ width: "100%" }}>
                      Get Started
                    </Link>
                  </div>
                </ScrollReveal>
              );
            })}
          </div>
        </div>
      </section>

      <hr className="e-divider" />

      <section className="e-section">
        <div className="e-container-wide">
          <ScrollReveal>
            <div className="e-section-header">
              <p className="e-eyebrow">Compare Plans</p>
              <h2 className="e-section-title">Feature comparison</h2>
            </div>
          </ScrollReveal>
          <ScrollReveal delay={1}>
            <div className="e-table-wrap">
              <table className="e-table">
                <thead>
                  <tr>
                    <th>Feature</th>
                    <th>Trial</th>
                    <th>Monthly</th>
                    <th>Yearly</th>
                    <th>Lifetime</th>
                  </tr>
                </thead>
                <tbody>
                  {COMPARE.map((row) => (
                    <tr key={row.feature}>
                      <td>{row.feature}</td>
                      <td>{row.trial ? <span className="e-check">✓</span> : "—"}</td>
                      <td>{row.monthly ? <span className="e-check">✓</span> : "—"}</td>
                      <td>{row.yearly ? <span className="e-check">✓</span> : "—"}</td>
                      <td>{row.lifetime ? <span className="e-check">✓</span> : "—"}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </ScrollReveal>
          <p style={{ textAlign: "center", marginTop: 32, fontSize: 13, color: "var(--e-text-dim)" }}>
            Live checkout uses PaymentPort when production PSP credentials are configured. Sandbox available for RC.
          </p>
        </div>
      </section>
    </EnterpriseShell>
  );
}
