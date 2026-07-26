# PRODUCTION_METRICS.md

**Phase:** 10 · Sprint 2  
**Console:** `/portal/admin/metrics`  
**API:** `GET /api/admin/launch?view=metrics`  

---

## Collected rates / counts

| Metric | Source events |
|--------|----------------|
| Installation Success Rate | install_success / install_fail |
| Activation Success Rate | activation_success / fail |
| Login Success Rate | login_success / fail |
| License Validation Rate | license_validation_ok / fail |
| Portal Usage | portal_page_view |
| Update Success Rate | update_success / fail |
| Crash Rate | crash_report vs login+views (portal proxy) |
| Average Session Time | session_end.sessionMinutes |
| Support Requests | support_request |

## Notes

- Events stored encrypted under `.data/launch/metrics/`  
- Admins may record events manually during beta interviews  
- Core EA crash dumps are **not** instrumented in this sprint (Core frozen)
