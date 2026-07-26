# BUILD_INFORMATION.md

**Product:** THE GOLD MIND AI  
**Edition label:** Professional Enterprise Edition  
**Version string:** `2.0.0`  
**Build:** **21060**  
**Sprint label:** Phase 7 / Sprint 10 – Trading Ecosystem Certification, Hardening & Closure  

---

## Compile

| Item | Value |
|------|-------|
| Tool | MetaEditor64 |
| Include root | Project workspace |
| Target | `Experts/TheGoldMindAI_Professional.mq5` |
| Last known result | **0 errors, 5 warnings** |
| Warning source | `Include/AI/News/CCalendarNewsProvider.mqh` (ulong/long/double casts) |
| CPU target | X64 Regular |

---

## Freeze flags (active)

- `GM_CORE_ARCHITECTURE_FROZEN`  
- `GM_DASHBOARD_ARCHITECTURE_FROZEN`  
- `GM_AI_ARCHITECTURE_FROZEN`  
- `GM_PHASE4_COMPLETE`  
- `GM_PHASE5_COMPLETE` / `GM_PHASE5_AI_MARKET_INTEL_FROZEN`  
- `GM_PHASE6_COMPLETE` / `GM_PHASE6_INFRASTRUCTURE_FROZEN`  
- `GM_PHASE7_COMPLETE` / `GM_PHASE7_ECOSYSTEM_FROZEN`  

---

## Release Candidate

**RC-1** = Build **21060** source tree as of enterprise master review (2026-07-26).

Artifacts:

- `TheGoldMindAI_Professional.ex5` (local compile output)  
- `GM_PHASE6_*` / `GM_PHASE7_*` closure packages (generated at runtime)  
- Documentation under `Documentation/Guides/`

---

## Versioning policy (recommended)

| Channel | Versioning |
|---------|------------|
| Internal Dev | Build++ every sprint |
| Website Professional | SemVer marketing + build suffix |
| MQL5 Market | Market-required version + trimmed feature set |

---

*End of BUILD_INFORMATION.md*
