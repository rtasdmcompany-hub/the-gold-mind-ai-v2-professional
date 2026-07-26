# RELEASE_ENGINEERING.md

**Phase 8 · Sprint 7**  
**Product:** THE GOLD MIND  
**Rule:** Release engineering only — Core Trading Engine permanently frozen  
**Governing rule:** No public version ships unless all Quality Gates pass

---

## 1. Purpose

Operate THE GOLD MIND like Microsoft / Adobe / JetBrains / MetaQuotes / TradingView:

- One shared Core  
- Multiple commercial editions  
- Controlled promotion through release channels  
- Customer always receives stable, tested builds  

---

## 2. Release channels

| Channel | Purpose | Who receives | Promotion rule |
|---------|---------|--------------|----------------|
| **Development** | Daily engineering integration | Dev team only | Any commit that compiles locally; no customer distribution |
| **Internal QA** | Structured test against Quality Gates draft | QA / Owner | Promote from Development when smoke compile + basic sanity pass |
| **Release Candidate (RC)** | Freeze candidate for public | Internal + invited validators | Promote from Internal QA when mandatory gates green except Final Approval |
| **Public Stable** | Customer Website / Market packages | Paying / Market customers | Promote from RC **only** when **all** Quality Gates pass + Final Approval |
| **Long-Term Support (LTS)** | Extended maintenance line | Enterprise / conservative customers | Branch from a Public Stable; hotfixes only; no feature merges without LTS policy exception |
| **Beta (Future)** | Opt-in previews | Volunteers | Parallel to RC; never auto-promote to Stable without full gates |

---

## 3. Promotion flowchart

```
Development
    ↓ (smoke + owner intent)
Internal QA
    ↓ (gates except final)
Release Candidate
    ↓ (ALL Quality Gates + Final Approval)
Public Stable ──→ package Website + Market (same Core tag)
    ↓ (optional pin)
Long-Term Support
```

Beta (future) may fork from RC but cannot skip gates into Stable.

---

## 4. Channel artifacts

| Channel | Artifacts |
|---------|-----------|
| Development | Unsigned / internal build id |
| Internal QA | QA build notes · known issues list |
| RC | RC notes · gate checklist draft · rollback plan |
| Public Stable | Signed/checksummed packages · release notes · docs |
| LTS | LTS tag · security/hotfix notes only |

---

## 5. Roles

| Role | Authority |
|------|-----------|
| Engineering | Produce Development builds |
| QA | Gate evidence on Internal QA / RC |
| Release Manager / Owner | Final Approval to Public Stable / LTS |
| Support | Validate diagnostics readiness on RC |

---

## 6. Non-negotiables

1. Website Edition and Market Edition **share one Core tag** at each Public Stable  
2. Commercial packaging may differ; Core bytes/behavior must not diverge  
3. Reliability over features — slip the date rather than skip gates  
4. Core Trading / Strategy / Risk / Recovery / Execution / AI Decision Logic remain frozen unless Owner explicitly unfreezes  

---

*End of RELEASE_ENGINEERING.md*
