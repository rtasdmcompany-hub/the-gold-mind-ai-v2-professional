# BETA_OPERATIONS.md

**Phase:** 10 · Sprint 2  
**Edition:** Website Professional (invite-only)  
**Core:** FROZEN  

---

## Operating principles

1. Real customer feedback has priority over assumptions.  
2. No new features during beta unless they resolve validated production issues.  
3. Stability, trust, and confidence over growth.  
4. Core Trading Engine is never modified from beta findings.

## Daily ops checklist

| Step | Owner | Tool |
|------|-------|------|
| Review Beta Dashboard | Launch lead | `/portal/admin/beta-dashboard` |
| Triage new feedback / bugs | Support + Eng | Feedback · Issues |
| Check P0/P1 open = 0 for Critical | QA | Issues |
| Confirm system health healthy | Ops | Metrics / Launch monitoring |
| Advance enrollment steps | CS | Beta participants |
| Record install/activation outcomes | Release | Metrics |

## Enrollment workflow

Invitation → Acceptance → Account → License → Portal → Download → Install → Activation → Welcome Wizard → First Login → First Trading Session

Participants self-serve at `/portal/beta`. Admins can mark steps at `/portal/admin/beta`.

## Feature freeze

- Bugs: fix if commercial and validated.  
- Features: log as `feature_request` / P3 — defer past beta.  
- Core strategy/risk/execution: **out of scope**.

## Expansion rule

Do not invite the next cohort until:

- P0 open = 0  
- Install & activation success ≥ targets  
- Avg satisfaction ≥ 4.0 (n ≥ 10 preferred)  
- System health stable
