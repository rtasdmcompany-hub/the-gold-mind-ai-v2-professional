# PRODUCTION_MONITORING.md

**Phase:** 10 · Sprint 3  
**Scope:** Commercial cloud observability only — never stops local Trading Engine  

---

## Platform

First-party observability inspired by Azure Monitor / Datadog / Grafana patterns, implemented inside the Customer Portal commercial stack.

## Health dashboard

**UI:** `/portal/admin/observability`  
**API:** `GET /api/admin/observability?view=health`

Cards: Overall Platform · Portal · API Gateway · Auth · License · Subscription · Payments · Email · Updates · Database · Redis Cache · Background Workers

## Related consoles

| Console | Path |
|---------|------|
| Telemetry | `/portal/admin/telemetry` |
| Usage Analytics | `/portal/admin/usage` |
| Alerts | `/portal/admin/alerts` |
| Ops Intelligence | `/portal/admin/ops-intelligence` |
| Incident Timeline | `/portal/admin/incident-timeline` |
| Monitoring Security | `/portal/admin/monitoring-security` |

## Isolation rule

If monitoring services fail, trading operations continue normally. Monitoring never imports or controls the Core Trading Engine.
