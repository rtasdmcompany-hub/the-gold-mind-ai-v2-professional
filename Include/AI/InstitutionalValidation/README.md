# PHASE 14 — Institutional AI Validation Engine

**Enhancement layer only.** Does **not** replace the H4 Trading Engine.

```
H4 Strategy → Institutional AI Validation → Trade Execution (OrderSend)
```

## Feature flag

| Input | Default | Effect |
|-------|---------|--------|
| `AI_VALIDATION_ENABLED` | `false` | OFF = pass-through (existing backtests unchanged) |
| `AI_VALIDATION_ALLOW_OPTIONAL` | `true` | Allow 70–84 confidence band |

## Modules

| Class | Role |
|-------|------|
| `CStructureValidator` | HH/HL, LH/LL, break, continuation, pullback, retest, fake break |
| `CInstitutionalValidator` | BOS, CHoCH, liquidity, OB, FVG, premium/discount, session |
| `CMarketValidator` | News, ATR, spread, volatility, session, basic bias |
| `CTPSLOptimizer` | Verify SL/TP; max SL adjust 20% ATR; TP → nearest liquidity |
| `CConfidenceCalculator` | Weighted final score |
| `CInstitutionalValidationEngine` | Orchestrator |

## Confidence weights

- H4 Strategy **60%** (100 when placement is requested by H4 engine)
- Structure **20%**
- Institutional **10%**
- Market **10%**

## Execution gates

| Score | Action |
|------:|--------|
| ≥ 85 | Execute |
| 70–84 | Optional (if allowed) |
| < 70 | Reject |

## Integration

Hooked **only** inside `PlaceBuyLimit` / `PlaceBuyStop` / `PlaceSellLimit` / `PlaceSellStop` immediately before `g_trade.*` (OrderSend).

No UI · No DB · No H4 strategy / level / risk / recovery changes.
