# IMPLEMENTATION_GOVERNANCE.md

**Phase:** 9 · Sprint 1  
**Applies to:** Every Phase 9 implementation task / PR / work package  
**Authority:** Board APPROVED WITH CONDITIONS

---

## 1. Standing rules

1. Core Trading Engine is certified and frozen.  
2. No task may modify Trading / Strategy / Risk / Recovery / Order Execution / Magic / Trade Calculations.  
3. Every task must wrap commercially — never patch Core for demos.  
4. Prefer serial safety over risky parallel work on shared modules.  
5. No public launch claim until Board Conditions Tracker = all Verified.  

---

## 2. Mandatory task template

Every task record **must** include:

| Field | Description |
|-------|-------------|
| **Objective** | One sentence outcome |
| **Scope** | In / out of scope; paths allowed |
| **Dependencies** | Upstream tasks / Board Conditions |
| **Risk Level** | Critical · High · Medium · Low |
| **Testing Requirement** | What must be proven |
| **Rollback Plan** | How to undo safely |
| **Completion Criteria** | Binary pass checks |

### Template (copy)

```markdown
### Task ID: P9-XXX
Objective:
Scope:
  In:
  Out: Core Trading Engine and all frozen modules
Dependencies:
Risk Level:
Testing Requirement:
Rollback Plan:
Completion Criteria:
  - [ ]
Board Conditions impacted:
Regression suite: per REGRESSION_PROTECTION.md
```

---

## 3. Risk level guidance

| Level | Examples | Extra controls |
|-------|----------|----------------|
| Critical | Payments, license issue, legal publish | Dual review · staging first |
| High | Installer, portal auth, update apply | Full regression + checksum |
| Medium | KB articles, email copy, UI chrome | Standard regression |
| Low | Docs typo, non-prod config | Smoke only |

---

## 4. Merge authority

| Change type | Required |
|-------------|----------|
| Commercial / portal / website | Reviewer + regression PASS |
| Anything touching shared packaging profiles | Release Manager awareness |
| Anything under Core / Experts trading logic | **REJECT** unless Owner CR |

---

## 5. Completion & audit

- Task closed only when Completion Criteria checked  
- Link evidence (logs, screenshots, checksums, gate sheet)  
- Update `BOARD_CONDITIONS_TRACKER.md` if a gate moves  

---

*End of IMPLEMENTATION_GOVERNANCE.md*
