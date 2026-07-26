# Include/MultiInstance

Phase 2 Sprint 7 — Multi-Chart, Multi-Symbol & Multi-Instance Management (**monitoring only**).

| File | Role |
|------|------|
| `CMultiInstanceEngine.mqh` | Orchestrator |
| `CInstanceManager.mqh` | Local instance registration + heartbeat |
| `CChartManager.mqh` | Chart identity tracking |
| `CGlobalMonitor.mqh` | READ-ONLY peer aggregation |
| `CInstanceHealthMonitor.mqh` | Health score |
| `CSyncEngine.mqh` | Monitoring sync (no trading sync) |
| `CMultiInstanceApi.mqh` | Central/Cloud/Mobile/Web/AI stubs |

**Isolation:** Each instance owns its Magic, Symbol, Chart, Trades, Sessions.  
**Never** synchronizes trading actions across instances.
