# AI News Intelligence (Phase 3 / Sprint 5)

**ANALYSIS ONLY** — never opens/closes/modifies trades.  
**HARD POLICY:** `NO TRADE BLOCK` — never skips, blocks, or cancels Gold Mind trades during news.

| Module | Role |
|--------|------|
| `CAINewsEngine` | Orchestrator |
| `CNewsDataEngine` | Provider aggregation |
| `CCalendarNewsProvider` | MT5 Economic Calendar |
| Stub providers | API / Broker / RSS / Institutional |
| `CEconomicCalendarAnalyzer` | Upcoming / high-impact selection |
| `CNewsImpactClassifier` | Very Low → Black Swan |
| `CMarketReactionAnalyzer` | Spread / ATR / momentum observations |
| `CGoldEventMonitor` | XAUUSD-sensitive events |
| `CNewsDecisionApi` | Future Decision Support export |
| `CNewsHistoryDatabase` | Persist reactions + scores |
