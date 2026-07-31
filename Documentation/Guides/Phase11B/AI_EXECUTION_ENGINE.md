# AI Execution Engine — Phase 11B

**Product:** THE GOLD MIND AI v2.0 PROFESSIONAL  
**Module:** `Include/AI/ExecutionSupervisor/Phase11B/`  
**Version:** 11B.1.0  
**Status:** CERTIFIED (Owner Architecture Decision)

## Architecture

| Layer | Role |
|-------|------|
| Trading Engine (`Experts/TheGoldMindAI_Professional.mq5`) | **MASTER** — all strategy math, entries, TP/SL, ATR, hedge, recovery |
| AI Execution Supervisor (`CPhase11BExecutionAuthority`) | **PRE-ACTIVATION ONLY** — lot scale, freeze, cancel pending |
| EA Bridge (`CGmEAPreActivationBridge.mqh`) | Thin hooks at placement/monitor — no formula changes |

## Hook Points (non-formula)

- `PlaceBuyLimit` / `PlaceBuyStop` / `PlaceSellLimit` / `PlaceSellStop` — allow + lot adjust before send
- `OnTick` — monitor live pendings (freeze/cancel)
- `OnTradeTransaction` — detect activation → AI read-only
- `UpdateDashboard` — Enterprise AI Supervisor panel

## Frozen (READ ONLY)

Core SHA surface, H4 math, ATR, entries, pending levels, recovery, hedge, TP/SL, risk formulas, active trade management.

## Owner Inputs

| Input | Default |
|-------|---------|
| `P11B_Max_Lot_Increase_Pct` | 20% |
| `P11B_Max_Lot_Reduction_Pct` | 50% |
| `P11B_Max_Freeze_Minutes` | 30 |
| `P11B_Emergency_Cancel` | ON |
| `P11B_News_Protection` | ON |
| `P11B_Broker_Protection` | ON |
| `P11B_Weekend_Protection` | ON |

## Files

- `Phase11BConstants.mqh`
- `SGmPreActivationSnapshot.mqh`
- `CPhase11BExecutionAuthority.mqh`
- `CGmEAPreActivationBridge.mqh`
- `Module.Phase11BExecutionAuthority.mqh`
