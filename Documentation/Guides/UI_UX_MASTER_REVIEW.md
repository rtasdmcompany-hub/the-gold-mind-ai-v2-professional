# UI_UX_MASTER_REVIEW.md

**Lens:** Commercial Product Director (TradingView / JetBrains / MetaQuotes quality bar)  
**Product:** THE GOLD MIND AI  
**No implementation — evaluation only**

---

## 1. North-star UX statement

> A professional gold trader should feel in control within one screen, without needing to understand the company’s internal phase roadmap.

---

## 2. Surface-by-surface review

### Navigation
- **Today:** Module-centric (enterprise inventory).  
- **Needed:** Goal-centric (Trade · Risk · Performance · Reports · Account · Help).  
- **Verdict:** Redesign IA for commercial edition; keep module map for Internal Dev.

### Dashboard
- **Today:** Dense, powerful, unstable labels across sprints.  
- **Needed:** Frozen commercial dashboard with 3 modes:
  - **Trader** — Core health, positions, H4 state, risk  
  - **Investor** — growth, drawdown, monthly, PDF export  
  - **Admin** — license, backups, alerts, multi-account  
- **Verdict:** Strong foundation; weak product composition.

### Charts
- Relies on MT5 excellence — good.  
- Product should brand overlays/status, not compete with MT5 charting.

### Panels
- Too many equal-priority panels.  
- Apply progressive disclosure: primary strip + “More analytics”.

### Trading Controls
- Correct philosophy: Core owns trading.  
- UX must make that visible: “Execution: Gold Mind Core” badge always present.  
- Never present research buttons that look like trade buttons.

### Reports
- Depth is a premium asset.  
- Customer wants: Daily / Monthly / Investor pack — one click.  
- Avoid internal BI jargon on first screen.

### Settings
- Rename from engineer catalogs to customer tasks:
  - Risk profile  
  - Notifications  
  - License  
  - Display  
  - Advanced (collapsed)

---

## 3. Heuristic scores

| Heuristic | Score | Comment |
|-----------|------:|---------|
| Learnability | 55 | Experts ok; beginners lost |
| Efficiency (pros) | 78 | Dense data helps pros |
| Error prevention | 70 | Core isolation helps; UI doesn’t teach it |
| Consistency | 62 | Sprint remaps hurt trust |
| Aesthetic professionalism | 66 | Serious, not yet premium brand |
| Accessibility | 58 | Density/contrast issues likely |
| Emotional trust | 64 | Needs calm onboarding |

**Composite UI/UX: 65 / 100**

---

## 4. Competitive UX gaps

| Competitor pattern | Gold Mind gap |
|--------------------|---------------|
| TradingView empty-state teaching | Weak empty/first states |
| JetBrains first-run tips | No tip system |
| MetaQuotes Market simplicity | Too much enterprise visible |
| Adobe modal clarity | Risk/legal modals not productized |

---

## 5. UX principles for commercial freeze

1. One primary job per screen.  
2. Hide Phase history from customers.  
3. Never churn widget labels on RC builds.  
4. Separate Trader vs Investor vs Admin.  
5. Research tools behind “Laboratory” door.  
6. Always show Core authority badge.  
7. Prefer calm status language over telemetry dumps.

---

## 6. Director priority UX backlog (product)

P0: Welcome Wizard + demo-first  
P0: Commercial dashboard IA freeze  
P1: Mode switcher (Trader/Investor/Admin)  
P1: Customer settings language  
P2: Report one-click packs  
P2: Empty states & teaching tips  
P3: Motion / polish  

---

*End of UI_UX_MASTER_REVIEW.md*
