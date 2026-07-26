# PHASE8_PREPARATION.md

**Status:** PREPARATION ONLY — **DO NOT START PHASE 8**  
**Prerequisite:** Owner approval after RC-1 commercial gates

---

## 1. Purpose of this document

Capture what Phase 8 *may* safely pursue after Core integrity and commercial packaging are settled.  
This is **not** authorization to implement.

---

## 2. Hard constraints carried into Phase 8

1. Do not modify Core Trading Engine, Gold Mind math, Risk, Recovery, pending/SL/TP control.  
2. Do not grant enterprise modules trade execution authority.  
3. Extend via new modules / APIs only.  
4. Protect manual trade isolation (Magic 0).  
5. Prefer trading accuracy, stability, reliability, performance, UX, maintainability over new enterprise surface area.

---

## 3. Recommended Phase 8 themes (candidates)

| Theme | Intent | Risk to Core |
|-------|--------|--------------|
| Edition build matrix | Website / Market / Internal profiles | Low if flags only |
| Customer onboarding UX | First-run wizard, safer defaults | Low |
| Warning cleanup & hardening | News casts, naming consistency | Low |
| Broker soak & certification kit | Evidence packs for live claims | None (ops) |
| Dashboard IA freeze | Stable commercial widget map | Low |
| Support & docs productization | Quickstarts, FAQ, runbooks | None |
| Optional read-only SDK | External BI connectors | Low if observe-only |

**Explicitly deferred / high-risk (reject unless separate Core program):**  
auto-trading remote commands, auto-apply optimization to live, strategy redesign, multi-symbol execution Core changes.

---

## 4. Entry criteria for Phase 8 (proposed)

- [ ] RC-1 Core soak accepted by owner  
- [ ] Market vs Website edition plan approved  
- [ ] Customer Quick Start published  
- [ ] Support runbook published  
- [ ] Compiler warnings reduced to zero critical  
- [ ] Written approval: “Start Phase 8”

---

## 5. STOP

Await approval. No Phase 8 coding in this review sprint.

---

*End of PHASE8_PREPARATION.md*
