# IMPLEMENTATION_QUEUE.md

**Phase:** 9 · Sprint 1  
**Principle:** Exact order · minimize parallel risk · protect shared modules  
**Companion:** `PHASE9_IMPLEMENTATION_PLAN.md`

---

## 1. Queue rules

1. Do not start a step until its predecessors are Complete (or explicitly Waived).  
2. Parallelism allowed only where listed under **Safe parallel**.  
3. Shared modules (packaging profiles, version strings, license API contracts) have a single owner at a time.  
4. Core / frozen trading paths are never in the queue as modify tasks.  

---

## 2. Exact implementation order

| Seq | Work package | Workstream | Risk | Predecessors | Board gate |
|----:|--------------|------------|------|--------------|------------|
| 1 | Governance baseline live (this sprint docs) | Commercial | Low | — | — |
| 2 | Brand assets intake + inventory | Commercial | High | Owner supply | BC-BRAND |
| 3 | Security baseline (secrets, TLS targets, redaction rules in services) | Security | Critical | 1 | — |
| 4 | Cloud service skeleton (License API + webhook receiver stubs) | Cloud | Critical | 3 | — |
| 5 | Payment Port adapter (test mode) | Licensing / Cloud | Critical | 4 | BC-PAYLIC |
| 6 | License generation + email delivery | Licensing | Critical | 5 | BC-PAYLIC |
| 7 | Activation + device registration API/client contract | Licensing | Critical | 6 | BC-PAYLIC |
| 8 | Customer Portal MVP auth + My Licenses / Downloads / Devices / Ticket entry | Portal | High | 7 | BC-PORTAL |
| 9 | Legal pack authoring & Owner approval | Website / Legal | Critical | 1 | BC-LEGAL |
| 10 | Website pages host legal + pricing + download shell | Website | High | 2, 9 | BC-LEGAL |
| 11 | Professional package profile + checksum pipeline | Commercial / Installer | High | 2 | BC-INSTALL |
| 12 | Installer branding + sealed artifact | Installer | High | 11 | BC-INSTALL |
| 13 | Wire Download page to sealed artifact | Website | High | 10, 12 | BC-INSTALL |
| 14 | Support KB Top-20 + diagnostics instructions | Support / Docs | Medium | 8 or email bridge | BC-SUPPORT |
| 15 | Ticket intake published (portal or interim email) | Support | Medium | 14 | BC-SUPPORT |
| 16 | Website update check design→impl (after package exists) | Updates | High | 12, 4 | — |
| 17 | Freeze commercial widget taxonomy in product | Commercial / UI | Medium | 1 | BC-QGATES note |
| 18 | Market compliance build + audit (if in window) | Commercial / MQL5 | Critical | Core tag pick | BC-MQL5 |
| 19 | RC dual-edition builds | Release | Critical | 12, 18 if Market | — |
| 20 | Quality Gates 1–10 + Core Attestation | QA / CTO | Critical | 19 | BC-QGATES, BC-CORE |
| 21 | Soft-launch eligibility review (Owner) | Executive | Critical | All VERIFIED | Launch formula |

---

## 3. Safe parallel (limited)

| Parallel set | May run together | Constraint |
|--------------|------------------|------------|
| P-A | Seq 9 (Legal drafting) ‖ Seq 3–4 (Security/Cloud stubs) | No production secrets in docs PRs |
| P-B | Seq 14 content writing ‖ Seq 11–12 packaging | No shared version bump conflicts — coordinate Release |
| P-C | Market listing copy draft ‖ Website copy | Separate edition claims; compliance review before publish |

**Not safe parallel:** Payment live cutover ‖ untested updater; Market upload ‖ Core tag still moving.

---

## 4. Shared module locks

| Shared module | Lock owner role | Rule |
|---------------|-----------------|------|
| SemVer / Core tag | Release Manager | One active release train |
| Payment webhook → license | Licensing lead | Idempotency required |
| Installer artifact name | Release Manager | Matches `COMMERCIAL_PACKAGING.md` |
| Portal auth | Portal lead | No duplicate identity stores |

---

## 5. Current queue pointer

**Now complete:** Seq 1; Seq 8 partial→licensing wired (Sprint 2–3); license generate/activate/devices (Sprint 3)  
**Next (Sprint 4 candidate):** Payment Port + email delivery (complete BC-PAYLIC) and/or Installer + Brand assets

---

*End of IMPLEMENTATION_QUEUE.md*
