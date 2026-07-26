# REPORTING_SYSTEM.md

**Phase 8 · Sprint 5**  
**Brand:** Premium Black · Metallic Gold (print: high-contrast ink-friendly variant)  
**Rule:** Reports help decisions and trust — not vanity metrics walls

---

## 1. Report catalog

### Time-based packs

| Report | Horizon | Primary audience |
|--------|---------|------------------|
| Daily | Calendar day | Active trader |
| Weekly | Calendar week | Review cadence |
| Monthly | Calendar month | Performance review |
| Yearly | Calendar year | Annual summary |
| Lifetime | Since first recorded trade | Long-horizon trust |

### Domain packs

| Report | Focus |
|--------|--------|
| Account Performance | Balance/equity curve, P&L, win rate, RR, hold time |
| Recovery Performance | Recovery events summary (display), outcomes, duration — **no control** |
| Risk Performance | Drawdown, margin stress moments, risk posture snapshots |
| Strategy Performance | By strategy version / profile label when available |

---

## 2. Standard report skeleton (all packs)

```
1. Cover / header — THE GOLD MIND PROFESSIONAL · period · account · Demo/Live
2. Executive snapshot — 5–7 KPIs max
3. Equity / balance chart (period)
4. Trade sample table (top wins/losses or full appendix)
5. Domain section (Account / Recovery / Risk / Strategy)
6. System notes — license status at generation time (optional)
7. Disclaimer — past performance ≠ future results; Core sole execution authority
8. Footer — build, generated timestamp, RTAS identity
```

---

## 3. KPI budget (anti-overload)

| Pack | Max headline KPIs |
|------|------------------:|
| Daily | 6 |
| Weekly / Monthly | 8 |
| Yearly / Lifetime | 8 |
| Domain packs | 8 + one focused chart |

Everything else → appendix or Journal deep-link.

---

## 4. Decision support prompts (copy only)

Examples of calm captions (not advice engines):

- “Margin stayed above warn threshold on N of M days.”  
- “Largest loss this period: … Review Journal filter: Losses.”  
- “Recovery events observed: N (display).”  

Never: “Guaranteed,” “AI always wins,” or trade instructions.

---

## 5. Access paths

- Nav → Reports  
- Analytics → “Generate period report”  
- Customer Portal (future): download history of generated exports  

---

## 6. Accuracy rules

- State data window and timezone  
- Separate floating vs closed P&L  
- Exclude or clearly mark incomplete days  
- Demo/Live watermark  

---

*End of REPORTING_SYSTEM.md*
