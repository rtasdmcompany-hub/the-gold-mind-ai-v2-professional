# CUSTOMER_FEEDBACK_REPORT.md

**Phase:** 10 · Sprint 2  

---

## Collection

| Form | Path |
|------|------|
| Structured survey (7 dimensions + overall) | `/portal/feedback` |
| Bug vs feature freeform | `/portal/feedback` |
| Admin triage | `/portal/admin/feedback` |

## Dimensions scored (1–5)

- Installation Experience  
- UI/UX  
- Performance  
- Documentation  
- Support Quality  
- License Experience  
- Overall Satisfaction  

## Separation rule

| Type | Category | Handling |
|------|----------|----------|
| Bug | `bug` | Issue tracker · possible hotfix |
| Feature | `feature` | Logged only · deferred |
| Survey | `structured` | CSAT / dimension averages |

## Executive readout

Dimension averages and CSAT appear on Executive Beta Dashboard.  
Feature requests do **not** authorize Core or strategy changes.
