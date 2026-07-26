# EXECUTIVE_LAUNCH_DASHBOARD.md

**Phase:** 10 · Sprint 1  
**UI:** `/portal/admin/launch`  
**API:** `GET /api/admin/launch`  

---

## Metrics displayed

| Metric | Meaning |
|--------|---------|
| Beta Users | Active beta participants / total roster |
| Active Licenses | Commercial active+grace licenses |
| Install Success Rate | Proxy from release update success when downloads exist |
| Activation Success Rate | Activated licenses / total |
| Crash Rate | Portal health proxy (Core crash telemetry not instrumented — Core frozen) |
| Update Success Rate | Updater telemetry success |
| Support Tickets | Open / pending |
| Open Incidents | Incl. Critical count |
| System Health | Domain rollup |
| CSAT | Avg satisfaction from feedback |

## Related admin pages

- Beta Program  
- Incidents  
- Feedback  
- Cloud Health  

## Audience

CEO / CTO / CPO / Commercial / QA / Release — read via `admin.launch.read`.
