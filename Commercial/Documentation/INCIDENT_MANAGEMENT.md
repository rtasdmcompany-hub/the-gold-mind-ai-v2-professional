# INCIDENT_MANAGEMENT.md

**Phase:** 10 · Sprint 3  

---

## Consoles

| Console | Path |
|---------|------|
| Incidents (ops) | `/portal/admin/incidents` |
| Incident Timeline | `/portal/admin/incident-timeline` |

## Timeline fields (required)

- Timestamp  
- Environment  
- Severity  
- Affected Service  
- Impact  
- Root Cause  
- Resolution  
- Owner  

## Relationship to alerts

Critical/High alerts should open or update an incident with environment + owner. Hotfixes remain commercial-only; Core stays frozen.

See also: `INCIDENT_RESPONSE.md` (Sprint 1 SLA model).
