# Include/AI/Core — Phase 3 Sprint 1

Independent **AI Intelligence Layer** (ANALYSIS ONLY).

| Module | Role |
|--------|------|
| `CAICoreEngine` | Root orchestrator |
| `CAIManager` | Analysis cycle coordinator |
| `CAIController` | Enable/pause/mode |
| `CAIDataBus` | Observation bus (Bridge/Analytics/Recovery/Market only) |
| `CAIStateManager` | AI states |
| `CAIContextManager` | Live context + confidence |
| `CAIMemoryManager` | Ring memory |
| `CAIDecisionQueue` | Advisory decisions (never executed) |
| `CAIEventDispatcher` | AI events |
| `CAICoreDatabase` | Sessions/analysis/learning/predictions |
| `CAISecurityGuard` | Blocks all trade mutation requests |
| `CAICoreApi` | Python/ML/DL/Cloud/GPT/REST stubs |

**Hard rule:** Never binds TradeManager / PendingEngine / Risk mutators. Gold Mind remains the only execution engine.
