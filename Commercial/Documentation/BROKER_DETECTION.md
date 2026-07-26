# BROKER_DETECTION.md

**Phase 8 · Sprint 2**  
**Purpose:** Help customers attach to the correct local MT5 terminal  
**Rule:** Detection is local & observational — no remote broker trading control

---

## Goals

1. Auto-detect installed MetaTrader 5 terminals  
2. List them clearly for selection  
3. Reduce “wrong terminal / wrong account” support tickets  
4. Remain Market-safe for Edition B (local only)

---

## Detection model (product)

| Step | Behavior |
|------|----------|
| Scan | Common MT5 install locations / registered terminals |
| Read | Terminal path; company/server strings when available from terminal data |
| Present | List: Name · Path · Broker company (if known) · Demo/Live hint (if known) |
| Select | User chooses primary terminal for onboarding |
| Persist | Save preference in commercial config (not Core risk store) |
| Refresh | Button to rescan after installing a new terminal |

---

## Customer UI

**Title:** Select your MetaTrader 5 terminal  

**Empty state:**  
“No MT5 terminal found. Install MetaTrader 5 from your broker, then click Refresh.”

**Warning state:**  
Multiple terminals found — explain why selection matters.

**Success state:**  
Selected terminal shown with path + “You can change this later in Settings.”

---

## Broker verification (lightweight)

Product-level checks (non-trading):

| Check | Intent |
|-------|--------|
| Terminal launches | Path valid |
| Account readable after user login | User must log into MT5 themselves |
| Symbol guidance | Point to gold symbol naming differences (broker-specific) in Quick Start |

**Out of scope for Sprint 2 design:** automated live order tests, remote terminal control, credential harvesting.

---

## Privacy

- Do not upload account passwords  
- Do not scrape unrelated documents  
- Only store selected terminal path + display labels needed for UX  

---

## Market edition

- Local detection only  
- No external broker API dependency  
- Keep UI minimal: select terminal → continue  

---

*End of BROKER_DETECTION.md*
