# DIAGNOSTICS_CENTER.md

**Phase 8 · Sprint 6**  
**Goal:** Professional “why is my system unhealthy?” module for users and Support  
**Extends:** Sprint 5 `SYSTEM_HEALTH_DASHBOARD.md`  
**Rule:** Read-only checks + guided actions — never mutates Core trading

---

## 1. Module sections

| Section | Checks |
|---------|--------|
| System Status | App/shell init, build, uptime, Safe State flag |
| Broker Status | Connected, trade-allowed flags (as exposed), account mode Demo/Live |
| License Status | Active / Grace / Expired / device seats |
| Configuration Validation | Profile load OK, checksum, missing required commercial keys |
| Connection Status | Internet reachability for license/cloud (when used) |
| Data Integrity | Journal/index readable; lease MAC OK; backup freshness |
| Environment Check | OS, terminal build, disk free, DPI/resolution class |
| Health Summary | Single roll-up: Healthy / Degraded / Critical |

---

## 2. UX layout

```
┌─ Diagnostics Center ─────────────────────────────────────┐
│ HEALTH SUMMARY: Healthy | Degraded | Critical            │
├─ Cards grid ─────────────────────────────────────────────┤
│ System · Broker · License · Config · Connection          │
│ Integrity · Environment                                  │
├─ Findings table ─────────────────────────────────────────┤
│ Severity · Code · Message · Suggested action             │
├─ Actions ────────────────────────────────────────────────┤
│ Refresh · Export Diagnostics Pack · Open Logs · Support  │
└──────────────────────────────────────────────────────────┘
```

---

## 3. Diagnostics pack contents

| Include | Exclude |
|---------|---------|
| Health JSON snapshot | Full license keys |
| Redacted recent logs | Passwords / tokens |
| Config checksum + names (not secrets) | Unrelated personal files |
| Build / version / edition | Raw memory dumps by default |

Customer-initiated only.

---

## 4. Suggested actions (examples)

| Finding | Action |
|---------|--------|
| License grace | Open License / Portal |
| Broker disconnect | Wait / check MT5 Journal |
| Config checksum fail | Restore last backup |
| Disk low | Free space guidance |
| Cloud unreachable | Offline grace notice |

---

## 5. Support readiness

- Every finding has stable `code`  
- Pack includes `correlation` window  
- Severity aligns with Error Handling Standard  

---

*End of DIAGNOSTICS_CENTER.md*
