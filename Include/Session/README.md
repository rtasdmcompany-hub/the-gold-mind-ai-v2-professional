# Include/Session

H4 Session Management, Order Synchronization, Execution Control, Audit & Performance (Sprint 7).

One closed H4 candle = one Trading Session.

Modules:
- CH4SessionEngine — session lifecycle + archive + recovery
- CSessionSyncEngine / COrderSyncEngine — DB ↔ terminal sync
- CExecutionControl — duplicate prevention
- CSessionAudit — enterprise audit trail
- CSessionPerformance — timing / memory / abnormal events
