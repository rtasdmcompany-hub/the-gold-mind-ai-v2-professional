# TELEMETRY_ARCHITECTURE.md

**Phase:** 10 · Sprint 3  

---

## Pipeline

```
Commercial services → recordTelemetry() → encrypted .data/observability/telemetry
                                    ↓
                         getTelemetrySummary() → dashboards / alerts
```

## Sample kinds

| Kind | Meaning |
|------|---------|
| app_startup_ms | Process/app start duration |
| portal_load_ms | Portal render/load proxy |
| api_response_ms | API latency sample |
| db_query_ms | Persistence probe latency |
| auth_success / auth_fail | Auth outcomes |
| license_ok / license_fail | License validation |
| payment_ok / payment_fail | Payment outcomes |
| installer_ok / installer_fail | Installer outcomes |
| update_ok / update_fail | Updater outcomes |

## Privacy

- Detail strings sanitized (emails / secrets redacted)  
- Retention default **30 days**  
- No Core trade ticks, positions, or magic numbers collected  

## Module

`src/server/observability/telemetry-store.ts`
