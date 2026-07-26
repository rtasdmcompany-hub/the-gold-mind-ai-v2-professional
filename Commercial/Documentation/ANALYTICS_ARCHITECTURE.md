# ANALYTICS_ARCHITECTURE.md

**Phase 8 · Sprint 5**  
**Product:** THE GOLD MIND PROFESSIONAL  
**Rule:** Product experience only — observe / explain / report. Never modifies Trading · Strategy · Recovery · Risk · Execution · AI Decision Logic.

---

## 1. Purpose

Give every customer a clear answer to:

| Question | Analytics answer |
|----------|------------------|
| What is the software doing? | System Health + live account overview |
| Why did it open a trade? | Trade Journal · Reason field (from Core logs / journal — display) |
| Is my account healthy? | Margin · Equity · Risk summary |
| Is the system healthy? | Engine · Broker · License · Cloud |
| How am I performing? | Period P&L · Win rate · RR · reports |

**Principle:** Accurate · simple · useful. Never overload. Every view must increase trust.

---

## 2. Analytics Dashboard — information architecture

### Tier A — Account Overview (first viewport)

| Metric | Role |
|--------|------|
| Balance | Settled account balance |
| Equity | Balance + floating |
| Margin | Used margin |
| Free Margin | Available margin |
| Floating Profit | Open P&L |
| Daily Profit | Calendar-day closed (+ optional floating note) |

**3-second scan:** Equity · Daily P&L · Free Margin health.

### Tier B — Performance snapshot

| Metric | Role |
|--------|------|
| Weekly Profit | Rolling / calendar week |
| Monthly Profit | Calendar month |
| Win Rate | Closed trades win % |
| Average RR | Average reward:risk on closed sample |
| Largest Win | Period or lifetime (toggle) |
| Largest Loss | Period or lifetime (toggle) |
| Average Holding Time | Mean duration closed trades |

### Tier C — Confidence strip (status, not vanity)

| Metric | Role |
|--------|------|
| Recovery Status | Display-only engine state |
| AI Status | Advisory health — never implies AI executes |
| License Status | Active / Grace / Expired |

---

## 3. Layout composition

```
┌─ Account Overview (Tier A) ─────────────────────────────┐
│ Balance  Equity  Margin  Free  Floating  Daily P&L      │
├─ Performance (Tier B) ──────────────────────────────────┤
│ Weekly  Monthly  Win%  Avg RR  Best  Worst  Hold Time   │
├─ Confidence strip (Tier C) ─────────────────────────────┤
│ Recovery · AI · License                                 │
└─ Optional sparkline: Equity (period) ───────────────────┘
```

Aligns with Sprint 4 widgets + Design System density rules.

---

## 4. Data principles

| Rule | Spec |
|------|------|
| Source of truth | Account/history APIs and journal records — **display** of Core outcomes |
| Freshness | Label “as of” timestamps on critical tiles |
| Demo vs Live | Badge inherited from top nav — never mix series silently |
| Magic isolation | Manual (Magic 0) vs EA trades filterable |
| No fake precision | Round money to account digits; avoid false 8-decimal noise |

---

## 5. Decision support (light)

Analytics may surface **read-only** cues:

- Margin level approaching warn threshold → link to Risk panel (display)  
- Losing streak context → link to Journal filter  
- License grace → link to License / Portal  

Analytics must **never** auto-change lots, SL, or recovery.

---

## 6. Anti-overload rules

- Home Analytics: Tier A + B + C only  
- Deep metrics live in Reports / Journal  
- Hide research-lab KPIs from first viewport  
- One primary number per tile  

---

## 7. Relationship to frozen platforms

| Existing capability (engineering) | Commercial role |
|-----------------------------------|-----------------|
| Trade Journal / Reporting Center / Portfolio Analytics | Data providers for this UX map |
| Dashboard widgets | Stable commercial taxonomy (Sprint 4) |
| This sprint | Customer-facing experience architecture |

No requirement to rewrite Phase 7 engines in Sprint 5.

---

*End of ANALYTICS_ARCHITECTURE.md*
