"use client";

import { ScrollReveal } from "./ScrollReveal";

export function SoftwareShowcase() {
  return (
    <section className="e-section" id="platform">
      <div className="e-container-wide">
        <ScrollReveal>
          <div className="e-section-header">
            <p className="e-eyebrow">Software Platform</p>
            <h2 className="e-section-title">Intelligent trading infrastructure</h2>
            <p className="e-section-sub">
              A unified dashboard for performance analytics, AI signals, and institutional-grade market visualization.
            </p>
          </div>
        </ScrollReveal>
        <ScrollReveal delay={1}>
          <div
            className="e-glass-card"
            style={{
              padding: 0,
              overflow: "hidden",
              maxWidth: 960,
              margin: "0 auto",
            }}
          >
            <div
              style={{
                display: "grid",
                gridTemplateColumns: "repeat(4, 1fr)",
                gap: 1,
                background: "var(--e-border)",
                borderBottom: "1px solid var(--e-border)",
              }}
            >
              {[
                { label: "Win Rate", value: "68.4%", sub: "30-day rolling" },
                { label: "Sharpe", value: "1.82", sub: "Risk-adjusted" },
                { label: "Drawdown", value: "−4.2%", sub: "Max observed" },
                { label: "Signals", value: "847", sub: "This month" },
              ].map((s) => (
                <div key={s.label} style={{ background: "var(--e-card)", padding: "20px 24px" }}>
                  <div className="e-stat-label">{s.label}</div>
                  <div className="e-stat-value e-stat-value--gold" style={{ fontSize: 22 }}>
                    {s.value}
                  </div>
                  <div style={{ fontSize: 11, color: "var(--e-text-dim)", marginTop: 4 }}>{s.sub}</div>
                </div>
              ))}
            </div>
            <div style={{ display: "grid", gridTemplateColumns: "2fr 1fr", gap: 1, background: "var(--e-border)", minHeight: 280 }}>
              <div style={{ background: "var(--e-surface)", padding: 24 }}>
                <div className="e-dashboard-title" style={{ marginBottom: 16 }}>
                  Performance · XAUUSD
                </div>
                <div className="e-chart-area" style={{ height: 180 }}>
                  <svg className="e-chart-svg" viewBox="0 0 500 180" preserveAspectRatio="none">
                    <defs>
                      <linearGradient id="showFill" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="0%" stopColor="rgba(184,155,95,0.2)" />
                        <stop offset="100%" stopColor="transparent" />
                      </linearGradient>
                    </defs>
                    <path
                      d="M0,140 L50,120 L100,130 L150,90 L200,100 L250,60 L300,70 L350,40 L400,50 L450,25 L500,30 L500,180 L0,180 Z"
                      fill="url(#showFill)"
                    />
                    <path
                      className="e-chart-line"
                      d="M0,140 L50,120 L100,130 L150,90 L200,100 L250,60 L300,70 L350,40 L400,50 L450,25 L500,30"
                    />
                  </svg>
                </div>
              </div>
              <div style={{ background: "var(--e-card)", padding: 24 }}>
                <div className="e-dashboard-title" style={{ marginBottom: 16 }}>
                  AI Signals
                </div>
                {["Long XAUUSD", "Neutral EURUSD", "Short GBPJPY"].map((sig, i) => (
                  <div
                    key={sig}
                    style={{
                      padding: "12px 0",
                      borderBottom: i < 2 ? "1px solid var(--e-border)" : "none",
                      fontSize: 13,
                      color: "var(--e-text-muted)",
                      display: "flex",
                      justifyContent: "space-between",
                    }}
                  >
                    <span>{sig}</span>
                    <span className="e-stat-value--up" style={{ fontSize: 12 }}>
                      Active
                    </span>
                  </div>
                ))}
                <div style={{ marginTop: 20, fontSize: 11, color: "var(--e-text-dim)" }}>
                  Heatmap · 24 markets monitored
                </div>
              </div>
            </div>
          </div>
        </ScrollReveal>
        <ScrollReveal delay={2}>
          <p
            style={{
              textAlign: "center",
              fontSize: 11,
              color: "var(--e-text-dim)",
              marginTop: 16,
              maxWidth: 700,
              marginLeft: "auto",
              marginRight: "auto",
              lineHeight: 1.6,
            }}
          >
            * Performance data shown is historical backtest / example demo data for illustrative purposes only. Past performance does not guarantee future results. Live trading results will vary based on market conditions, broker execution, and other factors. Verify live track record on{" "}
            <a
              href="https://www.myfxbook.com/portfolio/gold-mind-ai/12200748"
              target="_blank"
              rel="noopener noreferrer"
              style={{ color: "var(--e-gold, #b89b5f)", textDecoration: "underline" }}
            >
              Myfxbook
            </a>{" "}
            or{" "}
            <a
              href="https://www.mql5.com/en/market/product/183685"
              target="_blank"
              rel="noopener noreferrer"
              style={{ color: "var(--e-gold, #b89b5f)", textDecoration: "underline" }}
            >
              MQL5 Market
            </a>
            .
          </p>
        </ScrollReveal>
      </div>
    </section>
  );
}
