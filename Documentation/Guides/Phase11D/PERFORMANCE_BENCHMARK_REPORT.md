# PERFORMANCE BENCHMARK REPORT — Phase 11D

**Generated:** 2026-07-30  
**Dataset:** XAUUSDm H4, 2026.06.02–2026.06.20, Every Tick / 100% real ticks

## Side-by-Side Benchmark

| Metric | AI ON | AI OFF | Delta (ON − OFF) |
|--------|------:|-------:|-----------------:|
| Total Net Profit | -2,918.19 | -3,370.02 | **+451.83** |
| Gross Profit | 33,573.29 | 31,396.47 | +2,176.82 |
| Gross Loss | -36,491.48 | -34,766.49 | -1,724.99 |
| Profit Factor | 0.92 | 0.90 | +0.02 |
| Expected Payoff | -10.85 | -12.53 | +1.68 |
| Total Trades | 269 | 269 | 0 |
| Largest profit trade | 504.21 | 468.56 | +35.65 |
| Largest loss trade | -422.34 | -396.55 | -25.79 |
| Average profit trade | 238.11 | 222.67 | +15.44 |
| Average loss trade | -285.09 | -271.61 | -13.48 |
| Equity DD Maximal | 6,648.65 (49.71%) | 6,219.75 (49.70%) | — |

## Interpretation (evidence-based)

- AI did **not** change trade count or entry geometry.
- AI **did** change lot size pre-activation (volume diffs across nearly all pendings/deals).
- On this window, AI ON finished with a smaller net loss than AI OFF (+451.83 USD relative).
- Relative drawdown percentages remained essentially equal (~49.7%).

## Tester Runtime

From MT5 tester log (AI ON):

- Ticks generated: 4,825,624
- Test passed in ~0:32:44 (agent timing)

## Note

This report measures observed performance impact of permitted lot policy only. It does **not** claim profitability certification; it certifies evidence completeness and policy-bounded AI behaviour.
