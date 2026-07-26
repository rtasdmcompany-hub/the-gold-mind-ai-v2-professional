# REGRESSION_PROTECTION.md

**Phase:** 9 · Sprint 1  
**Rule:** Mandatory validation **before merging** any Phase 9 implementation  
**Goal:** Commercial changes never alter certified Core trading behaviour

---

## 1. When required

| Change | Regression required? |
|--------|----------------------|
| Any Phase 9 PR / work package | **Yes** (scoped suite below) |
| Docs-only under `/Commercial/Documentation` | Documentation Validation + Core path untouched check |
| Legal copy only | Documentation + link checks |
| Cloud/portal/installer | Full suite |

---

## 2. Validation suite

### A. Compile Validation
| Check | Pass criteria |
|-------|---------------|
| EA / project compile | **0 errors** (accepted warnings documented) |
| Edition profiles touched | Compile affected profiles (Professional / Market / Internal as applicable) |
| Include path | Project root convention unchanged |

### B. Core Trading Validation
| Check | Pass criteria |
|-------|---------------|
| Diff scope | No modifications under frozen Core / Strategy / Risk / Recovery / Execution / Magic / calculation modules |
| Attestation preview | List of touched paths reviewed; Core paths absent |
| Behaviour smoke (if terminal test available) | Demo chart: EA still initializes; no new order side-effects from commercial code paths |
| Magic isolation | Manual Magic 0 policy unchanged (document confirm) |

**If any Core file appears in diff without Owner CR → FAIL / REJECT merge.**

### C. UI Validation
| Check | Pass criteria |
|-------|---------------|
| Commercial chrome | No crash on open About / License status / Wizard entry (as implemented) |
| Widget taxonomy | No unauthorized rename of frozen commercial widget IDs |
| Edition accuracy | Market build does not show Website payment/activate CTAs |

### D. Security Validation
| Check | Pass criteria |
|-------|---------------|
| Secrets | No keys/tokens committed |
| Logs | License keys masked in sample log output |
| Transport | HTTPS endpoints only for commercial network calls |
| Webhooks | Signature verify path present when payment code merges |

### E. Documentation Validation
| Check | Pass criteria |
|-------|---------------|
| Claims | Feature claims match edition scope |
| Board tracker | Updated if gate status changes |
| User-facing | Links to legal/support not left as `TBD` on launch-bound pages |

---

## 3. Evidence pack (attach to PR / task)

```
[ ] Compile log (0 errors)
[ ] Path diff summary (Core untouched)
[ ] UI smoke notes
[ ] Security checklist
[ ] Docs / tracker updates
[ ] Rollback note verified
```

---

## 4. Failure policy

- Any FAIL → do not merge  
- Fix forward on branch; re-run failed + related checks  
- Do not disable Core Trading Validation to “ship commercial”  

---

## 5. Relation to Quality Gates

This suite is **pre-merge**.  
`QUALITY_GATES.md` (1–10) remains mandatory on **RC → Public Stable**.

---

*End of REGRESSION_PROTECTION.md*
