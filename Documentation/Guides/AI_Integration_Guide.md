# AI Integration Guide — Phase 2

## Principle

> The AI must **enhance** the strategy — not replace it.

Core places and manages Gold Mind trades. AI may advise, score, pause entries (when gated), or enrich analytics.

## Recommended Wiring Pattern

```
Tick / Timer
  → CGmApplication (Core path unchanged)
  → Optional: IGmAI* advisory (feature-flagged)
  → CGmPhase2Bridge (read-only observation)
```

## Using `CGmPhase2Bridge`

| Method | Use |
|--------|-----|
| `IsOwnPosition(ticket)` | Ownership gate before any AI suggestion |
| `PeekLevels(out)` | Observe current H4 grid (does not place orders) |
| `GetTrade(trade_id, out)` | Inspect registry state |
| `SessionId()` / `H4Cycle()` | Correlate insights to session |
| `OwnPositions()` / `OwnPendings()` | Exposure snapshot |
| `CoreFrozen()` | Confirm Phase 1 freeze active |

## Interface Contracts

See `Include/Phase2/IPhase2Interfaces.mqh`:

- `IGmAIMarketAnalysis` — insight only  
- `IGmAITradeScoring` — scores for levels/trades  
- `IGmAIDecisionEngine` — allow/deny **advisory**; Core may ignore  
- `IGmCapitalProtectionAI` — risk pause recommendations  
- `IGmHedgeEngine` — future hedge evaluation  
- `IGmAnalyticsEngine` — dashboard snapshots  
- `IGmCloudSync` — future sync  

## Security / Ownership

AI modules must call `IsOwnPosition` / Magic checks. Never send modifications for tickets outside Gold Mind ownership.

## Feature Flag Policy

Ship AI decision hooks **default OFF**. Enable only after validation on demo.
