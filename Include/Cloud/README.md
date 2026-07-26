# Include/Cloud — Enterprise Cloud Infrastructure

**Phase:** 6  
**Policy:** Cloud / Remote Monitor — **no trading authority**  
**Isolation:** Independent from Core Trading / AI / Risk / Recovery

## Modules

| Module | Role |
|--------|------|
| `CEnterpriseCloudEngine` | Sprint 1 facade: session, heartbeat, status |
| `CDeviceIdentityEngine` | Encrypted device identifiers |
| `CLicenseSessionEngine` | License tiers (architecture only) |
| `CRemoteSyncEngine` | Queued settings sync |
| `CCloudOfflineMode` | Offline-safe continue trading |
| `CCloudSecurity` | AES / hash / request signing |
| `CCloudDatabase` | `GM_CLOUD_*` persistence |
| **`RemoteMonitor/`** | **Sprint 2 — health / telemetry / events (monitor only)** |

## Rules

- Trading continues if cloud is unavailable  
- Cloud + Remote Monitor run on timer background path only  
- Never open/close/modify trades, orders, SL/TP, or risk  
