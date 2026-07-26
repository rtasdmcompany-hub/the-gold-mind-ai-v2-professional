# SYSTEM_HEALTH_DASHBOARD.md

**Phase 8 · Sprint 5**  
**Goal:** One screen to answer “Is THE GOLD MIND healthy right now?”  
**Rule:** Status display only — no engine reconfiguration from health tiles

---

## 1. Health tiles

| Tile | Shows | Healthy example |
|------|-------|-----------------|
| Trading Engine Status | Core process / module ready (observe) | Running / Ready |
| Broker Connection | Terminal ↔ broker | Connected |
| Market Session | Session label for focus symbol | London / NY Open |
| Spread | Current spread vs soft warn | Normal |
| Latency | Terminal/network delay if available | Within norm |
| License | Entitlement state | Active |
| Cloud | Cloud services reachability | Online / N/A |
| Memory Usage | Process/host memory band | OK |
| CPU Usage | Process/host CPU band | OK |
| Log Status | Logger writable / recent errors | OK |
| Recovery Status | Recovery engine display state | Idle / Active (info) |

---

## 2. Layout

```
┌─ System Health ──────────────────────────────────────────┐
│ ENGINE        BROKER         SESSION        SPREAD       │
│ LATENCY       LICENSE        CLOUD          RECOVERY     │
│ MEMORY        CPU            LOG STATUS                  │
├─ Attention (only if any warn/error) ─────────────────────┤
│ Banner list with deep links                              │
└─ Last refreshed: timestamp ──────────────────────────────┘
```

Overall chip: `Healthy` · `Degraded` · `Critical` (worst-child wins).

---

## 3. Status semantics

| State | Meaning |
|-------|---------|
| OK / Healthy | Within policy |
| Warn / Degraded | Usable but attention needed |
| Error / Critical | Trading confidence impaired — investigate |
| Unknown | No data — show honestly |

Pair color + icon + text (Sprint 4 a11y).

---

## 4. What health never does

- Restart Core trading algorithms  
- Change risk parameters  
- Force close positions  
- Bypass license  

Actions allowed: open logs · open Support · open License · copy diagnostics pack (customer-initiated).

---

## 5. Diagnostics pack (confidence + support)

Optional export bundle:

- Health snapshot JSON/CSV  
- Recent non-sensitive log tail  
- Build / version / license state  

Aligns with Support Tickets attachments (Sprint 3 portal).

---

## 6. Refresh policy

- Visible while on page: periodic soft refresh  
- Manual Refresh control  
- Stale data > N seconds → “Stale” badge  

---

*End of SYSTEM_HEALTH_DASHBOARD.md*
