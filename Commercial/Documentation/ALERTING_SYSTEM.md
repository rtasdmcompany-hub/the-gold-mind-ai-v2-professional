# ALERTING_SYSTEM.md

**Phase:** 10 · Sprint 3  
**UI:** `/portal/admin/alerts`  

---

## Severities

Critical · High · Medium · Low

## Default rules

| Rule | Severity | Threshold (summary) |
|------|----------|---------------------|
| Service Down | Critical | platform unhealthy |
| High Error Rate | High | auth success &lt; 95% |
| Slow API Response | Medium | API ms &gt; 500 |
| Failed Payments | High | payment success &lt; 90% |
| License Validation Failure | High | license ok &lt; 95% |
| Database Issues | Critical | database unhealthy |
| Email Delivery Failure | Medium | email ≠ healthy |
| Update Failure | High | update success &lt; 90% |
| High Crash Rate | High | crash rate &gt; 2% |
| Support Queue Threshold | Medium | open tickets &gt; 20 |

## Lifecycle

`firing` → `acknowledged` → `resolved`

## Engine

`evaluateAlerts()` in `src/server/observability/alert-engine.ts` — errors swallowed so alert evaluation cannot cascade into commercial request failures beyond the admin action.
