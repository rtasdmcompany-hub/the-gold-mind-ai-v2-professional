# AI Regression Report — Phase 11B

**Method:** Static verification + hook isolation audit  
**Date:** 2026-07-30

## Comparison Matrix

| Surface | Without AI | With AI | Permitted Difference |
|---------|------------|---------|----------------------|
| H4 level calculation | Engine | Engine | NONE |
| ATR TP/SL distances | Engine | Engine | NONE |
| Pending price levels | Engine | Engine | NONE |
| Recovery / hedge math | Engine | Engine | NONE |
| Risk 3% formula | Engine | Engine | NONE |
| BE / partial / trail | Engine | Engine | NONE |
| Lot at placement | `GetTradeVolume` output | ±Owner % scale | YES (pre-activation only) |
| Pending existence | Engine places | May freeze/cancel | YES (pre-activation only) |

## Verified Constants (unchanged)

- `TGM_RISK_PER_TRADE_FRACTION = 0.03`
- `CalculateAutoLotSize` body untouched
- `GetLiveATR` / grid placement math untouched
- No AI code paths modify open positions

## Hook Files Only

`Place*Limit/Stop` wrappers, `OnTick` monitor, `OnTradeTransaction` activation detect, dashboard panel.

## Script

Run: `Scripts/Phase11B-Regression-Verify.ps1`

## Result

**PASS** — Formula outputs remain identical; only permitted pre-activation execution deltas.
