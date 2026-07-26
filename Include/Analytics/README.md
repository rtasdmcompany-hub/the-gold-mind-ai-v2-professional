# Include/Analytics

Phase 2 Sprint 3 — Enterprise Analytics Engine (**READ-ONLY**).

| File | Role |
|------|------|
| `CAnalyticsEngine.mqh` | Orchestrator — trade/profit/win/risk/history/session |
| `CAnalyticsPerfMonitor.mqh` | Execution speed, memory, health |
| `CAnalyticsExport.mqh` | CSV/JSON/DB/Cloud/Mobile/Web stubs (no export yet) |
| `SGmAnalyticsSnapshot.mqh` | Full metrics snapshot |
| `AnalyticsConstants.mqh` | Throttle / export target enums |

**Hard rule:** Never open/close/modify trades, orders, SL/TP, or risk.
