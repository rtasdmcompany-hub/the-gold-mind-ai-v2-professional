# AI Decision Support & XAI (Phase 3 / Sprint 8)

**ADVISORY ONLY** — never executes, rejects, modifies, or cancels trades.

| Module | Role |
|--------|------|
| `CAIDecisionSupportEngine` | H4 decision orchestrator |
| `CDecisionMatrixEngine` | Multi-factor weighted matrix |
| `CExplainableAI` | Human-readable reasons (XAI) |
| `CHistoricalSimilarityEngine` | Similar H4 session search |
| `CStrategyValidationEngine` | Gold Mind setup consistency |
| `CFutureAutonomyLayer` | Future interfaces — **ALL INACTIVE** |
| `CDecisionHistoryDatabase` | Persist decisions + explanations |

## Gold Mind awareness

Evaluates each H4 cycle (3 buy / 3 sell, ATR TP, 30-pip SL, BE, partial, trail, 2nd attempt) and explains confidence — without changing execution.
