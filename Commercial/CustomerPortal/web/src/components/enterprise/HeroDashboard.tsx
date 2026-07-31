"use client";

import { brand } from "@/lib/brand";

export function HeroDashboard() {
  return (
    <div className="e-dashboard" aria-hidden="true">
      <div className="e-dashboard-header">
        <span className="e-dashboard-title">{brand.brandName} · Live</span>
        <span style={{ fontSize: 10, color: "var(--e-text-dim)" }}>MT5 Professional</span>
      </div>
      <div className="e-dashboard-stats">
        <div className="e-stat">
          <div className="e-stat-label">Portfolio</div>
          <div className="e-stat-value e-stat-value--gold">$284,920</div>
        </div>
        <div className="e-stat">
          <div className="e-stat-label">Today</div>
          <div className="e-stat-value e-stat-value--up">+2.41%</div>
        </div>
        <div className="e-stat">
          <div className="e-stat-label">AI Signals</div>
          <div className="e-stat-value">12 Active</div>
        </div>
      </div>
      <div className="e-chart-area">
        <svg className="e-chart-svg" viewBox="0 0 400 120" preserveAspectRatio="none">
          <defs>
            <linearGradient id="chartFill" x1="0" y1="0" x2="0" y2="1">
              <stop offset="0%" stopColor="rgba(184,155,95,0.25)" />
              <stop offset="100%" stopColor="rgba(184,155,95,0)" />
            </linearGradient>
          </defs>
          <path
            d="M0,90 L40,75 L80,82 L120,55 L160,60 L200,35 L240,42 L280,25 L320,30 L360,15 L400,20 L400,120 L0,120 Z"
            fill="url(#chartFill)"
          />
          <path
            className="e-chart-line"
            d="M0,90 L40,75 L80,82 L120,55 L160,60 L200,35 L240,42 L280,25 L320,30 L360,15 L400,20"
          />
          {[0, 1, 2, 3, 4, 5, 6, 7].map((i) => {
            const x = 30 + i * 48;
            const h = 20 + (i % 3) * 15;
            const up = i % 2 === 0;
            return (
              <g key={i} className="e-candle" style={{ animationDelay: `${i * 0.15}s` }}>
                <line x1={x} y1={100 - h - 10} x2={x} y2={100} stroke="rgba(255,255,255,0.2)" strokeWidth="1" />
                <rect
                  x={x - 6}
                  y={100 - h}
                  width={12}
                  height={h}
                  rx={2}
                  fill={up ? "rgba(110,207,154,0.7)" : "rgba(200,100,100,0.6)"}
                />
              </g>
            );
          })}
        </svg>
      </div>
      <div style={{ display: "flex", gap: 8, marginTop: 12, flexWrap: "wrap" }}>
        {["XAUUSD", "EURUSD", "GBPUSD"].map((pair) => (
          <span
            key={pair}
            style={{
              fontSize: 10,
              letterSpacing: "0.06em",
              padding: "4px 10px",
              borderRadius: 6,
              background: "rgba(0,0,0,0.3)",
              border: "1px solid var(--e-border)",
              color: "var(--e-text-muted)",
            }}
          >
            {pair}
          </span>
        ))}
      </div>
    </div>
  );
}
