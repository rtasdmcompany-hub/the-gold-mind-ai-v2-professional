# Include/Dashboard/QA

Phase 2 Sprint 9 — Dashboard stress testing, optimization metrics, and RC-1 certification (**READ-ONLY**).

| File | Role |
|------|------|
| `CDashboardQAEngine.mqh` | Full QA suite + report writer |
| `CUIStressTest.mqh` | Rapid tick / multi-state stress |
| `CDashboardSyncValidator.mqh` | Core ↔ Dashboard sync checks |
| `CDashboardVisualValidator.mqh` | Theme / DPI / layout |
| `CDashboardSettingsValidator.mqh` | Persistence fields |
| `CDashboardRecoveryValidator.mqh` | Restart / disconnect recovery |
| `CDashboardRuntimeMonitor.mqh` | 12/24/48/72h milestones |
| `CDashboardPerfMonitor.mqh` | Collect cost + memory |

Reports written as `GM_DASH_QA_*.txt` in the common files folder.
