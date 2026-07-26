# Include/Lifecycle

Sprint 4 Level Lifecycle Engine — controls every level from creation to completion.

| File | Role |
|------|------|
| `CLevelManager.mqh` | Facade + `CGmLevelGate` |
| `CLevelManagerImpl.mqh` | First-SL reactivation placement |
| `CLevelLifecycleManager.mqh` | TP / First SL / Second SL rules |
| `CLevelStateManager.mqh` | State transitions |
| `CLevelDatabase.mqh` | Persistent level DB |
| `CLevelValidationManager.mqh` | Pre-reactivation gates |
| `CLevelRecoveryManager.mqh` | Restart recovery |
| `CLevelHistoryManager.mqh` | Per-level event history |
| `CLevelGate.mqh` | Abstract gate (no circular includes) |
| `SGmLevelRecord.mqh` | Level record + history |
| `EnumsLifecycle.mqh` | States / events |
