# AI Decision Policy — Phase 11B

**Authority window:** Pending order exists → until deal entry (activation).  
**After activation:** AI is READ ONLY. Trading Engine has 100% control.

## Confidence Bands

| Score | Band | Action |
|-------|------|--------|
| 95–100 | EXTREMELY STRONG | Increase lot up to Owner max (+20% default) |
| 80–94 | STRONG | Trade exactly as Engine calculated |
| 60–79 | CAUTION | Reduce lot up to Owner max (−50% default), never below min lot |
| 40–59 | HIGH RISK | Freeze pending (remove from market, store exact Engine params) |
| &lt;40 | EXTREME RISK | Cancel pending only (if Emergency Cancel ON) |

## Pre-Activation Metrics

Continuously evaluated: Market Confidence, Trend Strength, Momentum, Liquidity, Spread, Volatility, ATR Expansion/Compression, Tick Speed, Price Acceleration, Broker Execution Quality, Slippage Probability, False Breakout Probability, Session Strength, News Risk, Market Structure, Execution Confidence.

## Prohibited (Active Trades)

AI MUST NEVER: move TP/SL/trail, close/open trades, modify hedge/recovery/lot/exits/strategy/calculations.

## WHY Requirement

Every decision stores a `why` string on the snapshot and AI panel (`WHY:` line).

## Self-Learning Scope

Learning file: `GM_P11B_EXEC_LEARN.csv` (Common Files).  
Records: execution confidence, freeze/cancel/lot events — **never** strategy formulas.
