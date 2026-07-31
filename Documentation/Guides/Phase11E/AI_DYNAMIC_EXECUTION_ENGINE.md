# PHASE 11E — Dynamic AI Pre-Activation Execution Engine

**Product:** THE GOLD MIND AI v2.0 PROFESSIONAL  
**Phase:** 11E  
**Type:** AI Evolution ONLY (not Trading Strategy Evolution)  
**Compile:** 0 errors, 0 warnings  
**EX5 size:** 248280 bytes  
**EX5 SHA256:** `BCF0D01980292EA652CDC6B780A87FD33329B6F6213ED5618B0CB6AF8B50FFA2`

## Architecture Freeze (unchanged)

AI MUST NOT modify:

- H4 Formula, ATR Formula
- SL / TP / Entry / Grid / Pending price calculation
- Strategy logic, trade direction, hedge logic
- Active trade management / Trading Engine

AI authority ends when a pending becomes a market order (READ ONLY).

## What Changed

| Capability | Phase 11B | Phase 11E |
|------------|-----------|-----------|
| Confidence | Single static-ish score at place time | Multi-factor + side-specific, continuous |
| Monitor cadence | Throttled tick scan | Every tick (500ms) + scheduled 5s |
| Lot after place | No live lot restore/increase on pending | Dynamic lot modify while pending |
| BUY/SELL scores | No | Yes |
| Logging | event/confidence/detail | prev/new conf + prev/new lot + evidence + reason |
| UI | Basic supervisor panel | Full multi-factor + lot panel |

## Multi-Factor Confidence

Computed every evaluation:

- BUY Confidence / SELL Confidence
- Trend Strength / Momentum Strength
- Liquidity Score / Spread Health
- Volatility Score / News Risk
- Overall AI Confidence
- Decision Confidence (side-aware)

Decision bands:

| Band | Confidence | Action |
|------|------------|--------|
| EXTREMELY STRONG | 95–100 | Increase lot (≤ owner max %) |
| STRONG | 80–94 | Restore original Engine lot |
| CAUTION | 60–79 | Reduce lot (≤ owner max %) |
| HIGH RISK | 40–59 | Freeze pending |
| EXTREME RISK | <40 | Cancel pending (if enabled) |

## Lot Lifecycle Example

1. Engine original lot = 5.0  
2. Initial confidence 68 → place 2.5  
3. Later confidence 92 → modify pending volume 2.5 → 5.0  
4. Price / SL / TP remain exactly the Engine values  

Lot changes are applied by delete+replace using **immutable captured price/SL/TP** (never recalculated by AI).

## Modules

```
Include/AI/ExecutionSupervisor/Phase11E/
  Phase11EConstants.mqh
  SGmDynamicConfidence.mqh
  SGmTrackedPending.mqh
  CPhase11EDynamicExecutionEngine.mqh
  Module.Phase11EDynamicExecution.mqh
```

Bridge (`Phase11B/CGmEAPreActivationBridge.mqh`) now hosts the Phase 11E engine while preserving `GmP11B_*` EA hooks (no Trading Engine edits).

## Logging

`Common/Files/GM_P11E_EXEC_LEARN.csv` columns:

`time,event,prev_conf,new_conf,prev_lot,new_lot,evidence,reason`

Also dual-writes summary lines to `GM_P11B_EXEC_LEARN.csv` for continuity.

## Owner Inputs

- `P11B_Enable_Supervisor`
- `P11B_Max_Lot_Increase_Pct` / `P11B_Max_Lot_Reduction_Pct`
- `P11B_Max_Freeze_Minutes`
- `P11B_Emergency_Cancel`
- `P11B_News_Protection` / `P11B_Broker_Protection` / `P11B_Weekend_Protection`
- `P11E_Dynamic_Lot_Monitor` (continuous pending lot control)

## Certification Status

Phase 11E **code + compile** complete.  
Production certification still requires a fresh Every-Tick AI ON/OFF evidence pass on this EX5 (Phase 11D process).
