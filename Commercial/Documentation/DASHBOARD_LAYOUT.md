# DASHBOARD_LAYOUT.md

**Phase 8 · Sprint 4**  
**Goal:** Institutional glanceability — full account status in seconds  
**Inspiration:** Bloomberg density · TradingView clarity · MT5 familiarity · Creative Cloud polish

---

## 1. Layout regions

```
┌────────────────────────────────────────────────────────────────┐
│ TOP NAVIGATION  (brand · account · session · notifications)    │
├──────────────┬─────────────────────────────────────────────────┤
│ LEFT NAV     │ WORKSPACE AREA                                  │
│ (collapsible)│  ┌─────────────┬──────────────┬───────────────┐ │
│              │  │ Trading     │ Statistics   │ Portfolio     │ │
│              │  │ Panel       │ Panel        │ Panel         │ │
│              │  └─────────────┴──────────────┴───────────────┘ │
│              │  ┌─────────────┬──────────────┬───────────────┐ │
│              │  │ Market      │ AI Status    │ Notifications │ │
│              │  │ Status      │              │ / Alerts      │ │
│              │  └─────────────┴──────────────┴───────────────┘ │
│              │  [ Modular widget grid — configurable density ] │
├──────────────┴─────────────────────────────────────────────────┤
│ FOOTER  (build · license · connection · risk disclaimer)       │
└────────────────────────────────────────────────────────────────┘
```

---

## 2. Region responsibilities

### Top Navigation
- THE GOLD MIND wordmark (official)  
- Environment: Demo / Live (clear badge)  
- Account login / broker label (display only)  
- Global search (future)  
- Notification bell  
- Profile / License shortcut  

### Left Navigation Panel
See `NAVIGATION_STRUCTURE.md` — collapse / expand.

### Workspace Area
Primary content for the selected nav item. Dashboard home uses the panel grid below.

### Trading Panel
- Open positions summary  
- Pending count  
- Quick links to Positions / Orders  
**Does not** place orders from decorative chrome; order actions remain in designated trading surfaces.

### Statistics Panel
- Daily P&L, win rate, trade count (observe)

### Portfolio Panel
- Equity, balance, margin level snapshot

### Market Status
- Symbol / session / spread snapshot

### AI Status
- Advisory health only — never implies AI executes

### Notifications
- Highest-severity unread items

### Footer
- Version / build  
- License status chip  
- Connection / latency  
- Short risk disclaimer line  

---

## 3. Information hierarchy (3-second scan)

| Seconds | User should see |
|--------:|-----------------|
| 0–1 | Equity / Balance / Daily P&L / Margin health |
| 1–2 | Open trades count · Spread · Broker/session |
| 2–3 | AI advisory health · License · Alerts needing action |

Anything else is secondary (scroll / nav).

---

## 4. Adaptive behavior

| Width | Behavior |
|-------|----------|
| ≤1366 | Nav collapsed by default; 2-column widget grid |
| 1600–1920 | Nav expanded; 3-column panels |
| ≥2560 | Optional 4-column; denser tables without stretching text |

Details: `RESPONSIVE_GUIDE.md`

---

## 5. Hard UX rules

- No sprint-telemetry naming in customer-facing widgets  
- No overlapping panels at supported resolutions  
- Functionality before visual effects  
- Dashboard is **status + navigation**, not a second EA  

---

*End of DASHBOARD_LAYOUT.md*
