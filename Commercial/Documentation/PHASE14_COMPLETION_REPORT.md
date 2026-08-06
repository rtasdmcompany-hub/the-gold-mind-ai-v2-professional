# PHASE 14 — COMPLETION REPORT

**Status:** FEATURE FROZEN  
**Product:** THE GOLD MIND AI PROFESSIONAL  
**Version label:** Phase 14 / 14A Institutional AI Validation (`GM_P14_VERSION` 14.1.0)  
**EA build (integration):** v2.068  
**Date:** 2026-08-07  

**Freeze rule:** No new features · No validator modifications · No refactoring · H4 Trading Engine remains FINAL.

---

## 1. Architecture

Phase 14 is an **enhancement layer only**. It does not replace or alter the H4 Trading Engine.

```
┌─────────────────────────────────────────┐
│         H4 Trading Engine (FROZEN)      │
│  Levels · Grid · Risk · Recovery · TP/SL│
└───────────────────┬─────────────────────┘
                    │ placement request
                    ▼
┌─────────────────────────────────────────┐
│   Phase 14 Institutional AI Validation  │
│   (optional — feature flagged)          │
│                                         │
│  Structure → Institutional → Market     │
│         → Confidence → TPSL verify      │
└───────────────────┬─────────────────────┘
                    │ allow / reject (+ minor SL/TP verify)
                    ▼
┌─────────────────────────────────────────┐
│     Trade Execution (OrderSend path)    │
│     PlaceBuy/Sell Limit|Stop            │
└─────────────────────────────────────────┘
```

**Design principles**

- Zero breaking changes when `AI_VALIDATION_ENABLED = false` (pass-through)
- Modular validators; single orchestrator
- Integrate **only** immediately before `g_trade.*` / OrderSend in Place* helpers
- No UI · No DB · No H4 strategy / pending / risk / recovery changes

---

## 2. Modules

| Module | Class | Responsibility |
|--------|-------|----------------|
| Orchestrator | `CInstitutionalValidationEngine` | Runs pipeline; applies verdict; calls TPSL optimizer on allow |
| Structure | `CStructureValidator` | HH/HL, LH/LL, break, continuation, pullback, retest, fake break |
| Institutional | `CInstitutionalValidator` | BOS, CHoCH, liquidity, OB, FVG, premium/discount, session bias |
| Market (14A) | `CMarketValidator` | Sessions, closed market, spread, ATR/vol, REAL NEWS / PROXY MODE |
| TP/SL | `CTPSLOptimizer` | Verify only; ≤20% ATR SL nudge; TP → nearest liquidity if needed |
| Confidence | `CConfidenceCalculator` | Weighted score + Execute / Optional / Reject |
| Bridge | `CGmPhase14ValidationBridge` | Inputs + `GmP14_*` EA hooks |
| Types / constants | `SGmP14Validation.mqh`, `Phase14Constants.mqh` | Shared structs, weights, thresholds |

---

## 3. Feature Flags

| Input | Default | Effect |
|-------|---------|--------|
| `AI_VALIDATION_ENABLED` | `false` | OFF = pass-through (backtests / live identical to pre-P14) |
| `AI_VALIDATION_ALLOW_OPTIONAL` | `true` | Allow execution when final confidence is 70–84 |

Defined in: `CGmPhase14ValidationBridge.mqh`

---

## 4. Validation Pipeline

1. H4 engine computes entry / shared ATR SL / ATR TP / lots (unchanged)  
2. Phase11B lot/placement gates (existing)  
3. **Phase 14** `GmP14_ValidateBeforeOrderSend(isBuy, entry, sl, tp, comment, level)`  
4. If disabled → return true, SL/TP untouched  
5. If enabled → Structure + Institutional + Market scores  
6. ConfidenceCalculator → final score + verdict  
7. REJECT → skip OrderSend  
8. EXECUTE / OPTIONAL (if allowed) → TPSLOptimizer may lightly adjust SL/TP → OrderSend  

---

## 5. Confidence Model

| Component | Weight |
|-----------|-------:|
| H4 Strategy | 60% |
| Structure Validation | 20% |
| Institutional Validation | 10% |
| Market Validation | 10% |

When placement is requested by the H4 engine, H4 confidence is treated as **100** (strategy already decided).

| Final confidence | Verdict |
|-----------------:|---------|
| ≥ 85 | Execute |
| 70–84 | Optional |
| < 70 | Reject |

Constants: `GM_P14_W_*`, `GM_P14_CONF_EXECUTE`, `GM_P14_CONF_OPTIONAL`

---

## 6. MarketValidator Logic (Phase 14A)

| Check | Behavior |
|-------|----------|
| Sessions | Asia / London / NY / Overlap / Off-hours / Closed (UTC XAU map) |
| Closed | Weekend, Friday ≥21 UTC, broker trade mode, quote sessions |
| Spread | Live vs absolute cap and broker typical `SYMBOL_SPREAD` |
| ATR / volatility | Spike vs median(14); abnormally low ATR |
| News | **REAL NEWS** if MT5 Economic Calendar API available; else **PROXY MODE** |
| Unavailable news | Never hard-blocks solely for missing calendar data |
| Logging | `TGM [P14A-MARKET]: REAL NEWS | …` or `PROXY MODE | …` |

---

## 7. Integration Points

| Location | Hook |
|----------|------|
| `#include` | `AI/InstitutionalValidation/CGmPhase14ValidationBridge.mqh` |
| `OnInit` | `GmP14_OnInit(g_atrHandle)` |
| `OnDeinit` | `GmP14_OnDeinit()` |
| `PlaceBuyLimit` | `GmP14_ValidateBeforeOrderSend(true, …)` before `g_trade.BuyLimit` |
| `PlaceBuyStop` | same |
| `PlaceSellLimit` | `GmP14_ValidateBeforeOrderSend(false, …)` before `g_trade.SellLimit` |
| `PlaceSellStop` | same |

**Not integrated into:** hedge paths (removed), market-validation tester trades, recovery, trailing, dashboard UI.

---

## 8. Files Changed / Added

### Added — `Include/AI/InstitutionalValidation/`

| File |
|------|
| `Phase14Constants.mqh` |
| `SGmP14Validation.mqh` |
| `CStructureValidator.mqh` |
| `CInstitutionalValidator.mqh` |
| `CMarketValidator.mqh` |
| `CTPSLOptimizer.mqh` |
| `CConfidenceCalculator.mqh` |
| `CInstitutionalValidationEngine.mqh` |
| `CGmPhase14ValidationBridge.mqh` |
| `README.md` |
| `PHASE14_VALIDATION_REPORT.md` *(copy)* |
| `MARKET_VALIDATOR_REPORT.md` *(copy)* |

### Modified — Expert

| File | Change |
|------|--------|
| `Experts/TheGoldMindAI_Professional.mq5` | Include bridge; OnInit/OnDeinit; Place* pre-OrderSend gates; v2.068 banner |

### Documentation (Commercial)

| File |
|------|
| `Commercial/Documentation/PHASE14_VALIDATION_REPORT.md` |
| `Commercial/Documentation/MARKET_VALIDATOR_REPORT.md` |
| `Commercial/Documentation/PHASE14_COMPLETION_REPORT.md` *(this file)* |

---

## 9. Related reports

- `PHASE14_VALIDATION_REPORT.md` — stub/implementation audit  
- `MARKET_VALIDATOR_REPORT.md` — Phase 14A MarketValidator finalization  
- `BACKTEST_PLAN.md` — OFF vs ON comparison plan  
- `PHASE15_RECOMMENDATIONS.md` — recommendations only  

---

## 10. Freeze declaration

**PHASE 14 IS FEATURE FROZEN.**

Do not add features, modify validators, or refactor Phase 14 code without a new phase authorization.
