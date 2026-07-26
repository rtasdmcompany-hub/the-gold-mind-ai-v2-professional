# NAVIGATION_STRUCTURE.md

**Phase 8 · Sprint 4**  
**Pattern:** Enterprise left rail — collapse / expand  
**Rule:** Navigation routes to views; it does not alter Core trading authority

---

## 1. Primary left navigation (Professional)

| Order | Item | Purpose |
|------:|------|---------|
| 1 | Dashboard | Account glance / home |
| 2 | Trading | Trading workspace entry |
| 3 | Open Positions | Live positions table |
| 4 | Pending Orders | Pending orders table |
| 5 | History | Closed deals / account history |
| 6 | Trade Journal | Journal / notes / replay entry |
| 7 | Analytics | Performance analytics |
| 8 | Portfolio | Portfolio & capital views |
| 9 | Reports | Investor / executive reports |
| 10 | AI Center | Advisory / decision quality (observe) |
| 11 | Backtesting | Strategy Lab entry |
| 12 | Optimization | Optimization Lab entry |
| 13 | Configuration | Profiles / templates (safe prefs) |
| 14 | License | Entitlement / devices / portal link |
| 15 | Support | Tickets / KB shortcuts |
| 16 | About | Brand, version, RTAS identity |

---

## 2. Grouping (visual sections)

```
OVERVIEW
  Dashboard

TRADE
  Trading · Open Positions · Pending Orders · History

INSIGHT
  Trade Journal · Analytics · Portfolio · Reports

RESEARCH
  AI Center · Backtesting · Optimization

SYSTEM
  Configuration · License · Support · About
```

Section labels: muted, uppercase micro-type — not clickable.

---

## 3. Collapse / expand

| Mode | Spec |
|------|------|
| Expanded | Icons + labels; width ~220–260px |
| Collapsed | Icons only; width ~56–64px; tooltips on hover |
| Toggle | Chevron / hamburger in top of rail or top nav |
| Persist | Remember last state per user/profile |
| Default ≤1366 | Collapsed |
| Default ≥1600 | Expanded |

Keyboard: focusable items; collapse toggle reachable.

---

## 4. Top navigation (companion)

- Brand lockup  
- Context: current page title  
- Demo/Live badge  
- Notifications  
- Account / License chip  

Avoid duplicating the entire left tree in the top bar.

---

## 5. Active / hover states

| State | Treatment |
|-------|-----------|
| Default | Ivory icon + muted label |
| Hover | Slight elevated wash |
| Active | Gold accent bar + gold icon/label |
| Disabled | Reduced opacity (feature gated by edition/license) |

---

## 6. Deep links & badges

Optional count badges: open positions, unread support, license grace.  
Badge color follows semantic rules — not decorative gold for everything.

---

## 7. Market Edition note

Edition B (MQL5 Market) may expose a **reduced** nav (Market compliance / product scope). Full rail is Professional Website target.

---

*End of NAVIGATION_STRUCTURE.md*
