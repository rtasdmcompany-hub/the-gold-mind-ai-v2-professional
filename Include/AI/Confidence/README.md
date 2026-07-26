# AI Trade Confidence & Decision Support (Phase 3 / Sprint 6)

**ADVISOR ONLY** — never rejects, modifies, or cancels trades.  
Gold Mind Core remains the sole execution authority (including news / high-risk windows).

| Module | Role |
|--------|------|
| `CAIConfidenceEngine` | H4 cycle orchestrator |
| `CMultiFactorScoringEngine` | Configurable weighted scoring |
| `CMarketQualityAnalyzer` | Trend/range/vol/liquidity/PA quality |
| `CTradeEnvironmentClassifier` | Excellent → Extreme Risk |
| `CDecisionSupportEngine` | Recommendations only |
| `CConfidenceHistoryDatabase` | Persist scores + context |
| `CConfidenceMlApi` | Future ML feature export (no ML yet) |

## Gold Mind awareness

Evaluates each new H4 environment (3 buy / 3 sell levels, ATR TP, 30-pip SL, BE, partial, trail, second attempt) **without changing execution**.
