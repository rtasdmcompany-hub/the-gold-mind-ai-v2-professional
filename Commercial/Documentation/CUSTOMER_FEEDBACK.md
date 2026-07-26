# CUSTOMER_FEEDBACK.md

**Phase:** 10 · Sprint 1  

---

## Channels

| Channel | Path |
|---------|------|
| Customer form | `/portal/feedback` |
| Admin triage | `/portal/admin/feedback` |
| API | `GET /api/admin/launch?view=feedback` |

## Categories collected

- Bug Reports  
- Feature Requests  
- UI Feedback  
- Performance  
- Installation Experience  
- Support Experience  
- Overall Satisfaction (1–5)  

## Workflow

1. Customer submits (authenticated)  
2. Status `new` → triage → `in_progress` → `resolved` / `wont_fix`  
3. Satisfaction scores roll into Launch Dashboard CSAT avg  
4. Bugs that are Critical commercial defects → open Incident  

## Trust rule

Feedback never triggers Core Trading Engine changes in Phase 10. Feature requests affecting strategy/risk are logged only for post-certification roadmap.
