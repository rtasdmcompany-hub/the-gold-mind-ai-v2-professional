# AI Replay Report — Phase 11C

**Generated:** 2026-07-30T09:11:08.107Z  
**Replay log:** `evidence/AI_REPLAY_LOG.csv`  
**Decisions logged:** 800  
**Evidence type:** Deterministic policy vectors (not MT5 historical ticks)

## Market Conditions Tested

| Strong Trend | conf=88.3 | STRONG | NORMAL |
| Weak Trend | conf=59.0 | HIGH_RISK | FREEZE |
| Sideways | conf=51.8 | HIGH_RISK | FREEZE |
| High Volatility | conf=72.0 | CAUTION | REDUCE_LOT |
| Low Volatility | conf=66.0 | CAUTION | REDUCE_LOT |
| London Open | conf=81.1 | STRONG | NORMAL |
| New York Open | conf=84.2 | STRONG | NORMAL |
| Asian Session | conf=60.3 | CAUTION | REDUCE_LOT |
| NFP | conf=60.8 | CAUTION | REDUCE_LOT |
| CPI | conf=60.9 | CAUTION | REDUCE_LOT |
| FOMC | conf=58.4 | HIGH_RISK | FREEZE |
| Gold Flash Moves | conf=73.7 | CAUTION | REDUCE_LOT |
| Weekend Gap | conf=40.0 | HIGH_RISK | FREEZE |
| Spread Expansion | conf=53.2 | HIGH_RISK | FREEZE |
| Broker Slippage | conf=56.4 | HIGH_RISK | FREEZE |
| Latency | conf=61.7 | CAUTION | REDUCE_LOT |

| Condition | Confidence | Band | Action |
|-----------|------------|------|--------|
| Strong Trend | 88.3 | STRONG | NORMAL |
| Weak Trend | 59.0 | HIGH_RISK | FREEZE |
| Sideways | 51.8 | HIGH_RISK | FREEZE |
| High Volatility | 72.0 | CAUTION | REDUCE_LOT |
| Low Volatility | 66.0 | CAUTION | REDUCE_LOT |
| London Open | 81.1 | STRONG | NORMAL |
| New York Open | 84.2 | STRONG | NORMAL |
| Asian Session | 60.3 | CAUTION | REDUCE_LOT |
| NFP | 60.8 | CAUTION | REDUCE_LOT |
| CPI | 60.9 | CAUTION | REDUCE_LOT |
| FOMC | 58.4 | HIGH_RISK | FREEZE |
| Gold Flash Moves | 73.7 | CAUTION | REDUCE_LOT |
| Weekend Gap | 40.0 | HIGH_RISK | FREEZE |
| Spread Expansion | 53.2 | HIGH_RISK | FREEZE |
| Broker Slippage | 56.4 | HIGH_RISK | FREEZE |
| Latency | 61.7 | CAUTION | REDUCE_LOT |

## Per-Pending Fields Verified

Timestamp, Confidence, Lot Adjustment, Freeze/Cancel Decision, Activation=PENDING_ONLY, Execution Time (LatencyMs), Reason, Owner Rule, Market Condition.

## Identity (WITH vs WITHOUT AI)

Entry, TP, SL, ATR, H4 level identical on every replay row.  
Allowed diffs only: lot scale / freeze / cancel.

## Production Evidence Gap

No real MT5 Strategy Tester or broker historical replay artifacts were available. These results validate policy logic, not live-terminal execution.

## Verdict

FAIL
