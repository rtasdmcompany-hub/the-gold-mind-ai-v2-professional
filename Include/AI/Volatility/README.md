# AI Volatility Intelligence (Phase 3 / Sprint 4)

**ANALYSIS ONLY** — no trading, risk, or order mutation.

| Module | Role |
|--------|------|
| `CAIVolatilityEngine` | Orchestrator |
| `CAtrIntelligenceEngine` | ATR-14 intelligence |
| `CVolatilityIntelligence` | Multi-horizon volatility |
| `CMarketEnergyEngine` | Energy score 0–100 |
| `CVolatilityPhaseClassifier` | Calm → Explosive phases |
| `CRangeAnalyzer` | H4/D1/W1/MN ranges |
| `CMovementProbabilityEngine` | Probability estimates only |
| `CVolatilityHistoryDatabase` | Persist ATR/vol/energy history |
| `CVolatilityEventEngine` | ATR/Energy/Range/Prob events |
