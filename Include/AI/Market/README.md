# Include/AI/Market — Phase 3 Sprint 2

AI Market Analysis Engine (**ANALYSIS ONLY**).

| Module | Role |
|--------|------|
| `CAIMarketAnalyzer` | Orchestrator (`IGmAIMarketAnalysis`) |
| `CMarketStructureAnalyzer` | HH/HL/LH/LL/BOS/trend/momentum |
| `CPriceActionAnalyzer` | Engulfing/Doji/Pin/Hammer/etc. |
| `CVolatilityAnalyzer` | ATR/ranges/expansion |
| `CMarketConditionClassifier` | Trending/ranging/breakout… |
| `CMarketSnapshotEngine` | H4 snapshots |
| `CMarketAnalysisDatabase` | Persist histories |

Never opens/closes/modifies trades.
