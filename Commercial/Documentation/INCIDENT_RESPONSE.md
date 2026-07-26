# INCIDENT_RESPONSE.md

**Phase:** 10 · Sprint 1  
**Console:** `/portal/admin/incidents`  

---

## Severity model

| Severity | Ack | Customer updates | Target resolve | Escalate |
|----------|-----|------------------|----------------|----------|
| Critical | 15m | 30m | 4h | Owner + CTO + Release |
| High | 30m | 60m | 24h | CTO + On-call |
| Medium | 4h | 8h | 72h | Engineering lead |
| Low | 24h | 48h | 7d | Backlog owner |

## Procedures

### Critical
1. Open incident (severity=critical)  
2. Assign commander  
3. Stabilize commercial service (scale, config, rollback package)  
4. Customer notification if user-facing  
5. Hotfix **only** if bug is outside Core  
6. Postmortem within 48h of resolve  

### High
Same as Critical with longer SLA; dual-approve production change.

### Medium / Low
Triage in business hours; link to feedback/support tickets.

### Bug escalation
Support → Launch/Incidents → Engineering. If Core suspected: **do not modify Core** — escalate to CTO for certification path.

### Emergency hotfix
Commercial portal/billing/license/installer scripts only. Dual approval. Record `hotfixRequired=true`.

### Rollback
Use prior release channel package + SHA-256 verify. Set `rollbackRequired=true` until complete.

### Customer notification
Mark `customerNotified` on incident; use portal announcements / email outbox. Prefer honesty and remediation steps over marketing language.

## Tooling

Encrypted store · audit events `incident_open` / `incident_update` · Launch Dashboard open/critical counters.
