# QUALITY_GATES.md

**Phase 8 · Sprint 7**  
**Rule:** **No public version** may release unless **all** gates pass  
**Applies to:** Public Stable and LTS hotfixes (full or expedited subset with Owner waiver documented)

---

## 1. Mandatory gates (Public Stable)

| # | Gate | Pass criteria |
|---|------|---------------|
| 1 | **Compile** | 0 errors on release profiles (Professional + Market as applicable) |
| 2 | **Static Analysis** | No new high-severity issues; accepted warnings documented |
| 3 | **Performance** | No major regression vs prior Stable on agreed smoke metrics |
| 4 | **Security** | License/redaction/TLS checklist; no secrets in artifacts |
| 5 | **UI Review** | Commercial IA sanity; no broken nav/critical empty crashes |
| 6 | **Documentation** | Release notes · version · upgrade notes present |
| 7 | **Commercial Review** | Edition claims accurate; Market compliance for Edition B |
| 8 | **Regression Review** | Prior critical bugs remain fixed; Core freeze respected |
| 9 | **Packaging Validation** | Checksums · contents manifest · correct edition modules |
| 10 | **Final Approval** | Owner / Release Manager sign-off recorded |

---

## 2. Gate evidence

Each gate stores:

- Owner name  
- Date/time  
- Result PASS/FAIL  
- Link to logs/artifacts  
- Notes / waivers (waivers **not** allowed to skip Compile or Final Approval for public)  

---

## 3. Channel requirements

| Channel | Gates required |
|---------|----------------|
| Development | Compile (local) |
| Internal QA | Compile + smoke subset |
| RC | Gates 1–9 (Final optional as “ready for approval”) |
| Public Stable | **All 1–10** |
| LTS hotfix | Compile · Security · Regression · Packaging · Final; others risk-assessed |
| Beta (future) | Documented subset; never silent Stable |

---

## 4. Failure policy

- Any FAIL → block promotion  
- Fix on branch → re-run failed gates + impacted neighbors  
- Do not “fix forward” into public without re-validation  

---

## 5. Core freeze gate (standing)

Regression Review must explicitly confirm:

> Trading Engine · Strategy · Risk · Recovery · Order Execution · AI Decision Logic unchanged unless Owner-approved change request exists.

---

*End of QUALITY_GATES.md*
