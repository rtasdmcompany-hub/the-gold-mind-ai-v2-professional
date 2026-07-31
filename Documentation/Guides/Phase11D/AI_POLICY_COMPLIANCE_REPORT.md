# AI POLICY COMPLIANCE REPORT — Phase 11D

**Generated:** 2026-07-30  
**Evidence:** Real MT5 Every-Tick AI ON vs AI OFF comparison

## Policy Under Test

AI may ONLY:

1. Monitor market behaviour  
2. Calculate confidence  
3. Increase/reduce lot size within owner policy (before activation)  
4. Freeze pending orders  
5. Cancel pending orders before activation  

AI must NEVER change:

- TP  
- SL  
- H4 formula outputs  
- ATR formula outputs  
- Pending order prices  
- Active trade direction  
- Core Trading Engine calculations  

## Compliance Matrix

| Rule | Evidence | Pass |
|------|----------|:----:|
| No TP change | 610/610 pending orders: TP identical ON vs OFF | YES |
| No SL change | 610/610 pending orders: SL identical ON vs OFF | YES |
| No pending price change | 610/610 pending orders: Price identical ON vs OFF | YES |
| No direction change | 468/468 deals: direction identical | YES |
| Lot adjust allowed | Volume differs 610/610 pendings and 464/468 deals; learn shows `LOT_ADJUST` | YES |
| Post-activation read-only | Learn shows `ACTIVATED_READONLY` × 400; no active-trade AI modify actions | YES |
| No forbidden learn actions | Forbidden pattern count = 0 | YES |
| Identical trade count / structure | Total trades 269/269; short/long and win/loss counts identical | YES |

## Lot Policy Window Check

Owner limits in both sets:

- `P11B_Max_Lot_Increase_Pct=20.0`
- `P11B_Max_Lot_Reduction_Pct=50.0`

Observed first-grid pending volumes under CAUTION:

- AI OFF: `1.0`
- AI ON: `0.5` (50% reduction — within policy)

## Verdict

**POLICY COMPLIANT** under real MT5 Strategy Tester evidence.
