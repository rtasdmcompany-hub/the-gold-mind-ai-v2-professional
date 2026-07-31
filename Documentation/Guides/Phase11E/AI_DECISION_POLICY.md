# PHASE 11E — Decision Policy

## Authority Window

AI may act **only** while order state is PENDING.

After activation:

- AI = READ ONLY
- No TP/SL/price/direction/engine changes

## Continuous Evaluation

Every evaluation recomputes:

- BUY Confidence, SELL Confidence
- Trend, Momentum, Liquidity, Spread Health, Volatility, News Risk
- Overall AI Confidence
- Decision Confidence (side-specific)

## Actions

| Action | When | Geometry |
|--------|------|----------|
| INCREASE LOT | Decision ≥ 95 | Price/SL/TP unchanged |
| RESTORE LOT | Decision 80–94 | Price/SL/TP unchanged |
| REDUCE LOT | Decision 60–79 | Price/SL/TP unchanged |
| FREEZE | Decision 40–59 | Pending removed & stored; geometry preserved |
| RESUME | Frozen + Decision ≥ 60 (or max freeze elapsed) | Re-place exact stored price/SL/TP |
| CANCEL | Decision < 40 (if enabled) | Pending removed before activation |

## Lot Caps

- Increase ≤ `P11B_Max_Lot_Increase_Pct` of **original Engine lot**
- Reduce ≤ `P11B_Max_Lot_Reduction_Pct` of **original Engine lot**
- Hard cap: `Max_Lot_Size` / symbol max volume
- Normalized to symbol volume step

## Explainability

Every action logs previous/new confidence, previous/new lot, market evidence, and reason.
