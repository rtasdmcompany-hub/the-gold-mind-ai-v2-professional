# PROJECT_STRUCTURE.md

**Product:** THE GOLD MIND AI Professional Edition  
**Owner:** RTAS Group of Companies · RTAS Digital Marketing Company  
**Review date:** 2026-07-26  
**Build under review:** 21060  
**Scope:** Read-only enterprise repository audit (no code changes)

---

## 1. Repository inventory

| Metric | Count (approx.) |
|--------|-----------------|
| Total files (workspace) | **946** |
| Source headers (`.mqh`) | **755** |
| Experts (`.mq5`) | **1** (`TheGoldMindAI_Professional.mq5`) |
| Compiled binary (`.ex5`) | 1 |
| Documentation (`.md`) | **188** |
| Folders (recursive) | **88** |
| Top-level `Include/` subsystems | **39** directories |
| Module entrypoints (`Module.*.mqh`) | **61** |
| Classes (`class CGm…`) | **~217+** (plus FutureInterfaces stubs) |
| Result structs (`struct SGm…`) | **~59** |
| Enums (`enum ENUM_GM…`) | **~69** |
| Future interface stub files | **12** |
| File-DB `WriteTable(` sites | **~78** logical tables |
| Third-party libraries | **None packaged** (pure MQL5 + MetaTrader 5 runtime APIs) |

---

## 2. Top-level layout

```
THE GOLD MIND AI v2.0 Professional/
├── Experts/                 # Single production EA
├── Include/                 # All enterprise + core modules
├── Documentation/Guides/    # Phase + operations documentation
└── (build artifacts: .ex5 / .log)
```

---

## 3. Include subsystems (major)

| Folder | Role |
|--------|------|
| `Calculation/` | H4 level math (frozen) |
| `Trading/` `Orders/` `TradeManagement/` `Lifecycle/` | Execution, pending, ownership |
| `Risk/` `Protection/` `Recovery/` `Session/` | Risk, capital protection, recovery, H4 session |
| `Dashboard/` `UI/` `Analytics/` `Journal/` `Reports/` | Phase 2 surfaces |
| `AI/` (+ many subfolders) | Advisory AI (Phases 3–5) |
| `Cloud/` | Phase 6 infrastructure |
| `TradeJournal/` `StrategyLab/` `OptimizationLab/` | Phase 7 research |
| `PortfolioAnalytics/` `ReportingCenter/` `ConfigurationCenter/` | Phase 7 analytics/config |
| `AIDecisionCenter/` `MultiAccountCenter/` `CommandCenter/` | Phase 7 intelligence/ops |
| `Phase2/`–`Phase7/` | Closure / certification engines |
| `Core/` `Validation/` `Production/` `Logging/` | Orchestration & quality gates |

---

## 4. MT5 components

| Component | Count |
|-----------|-------|
| Expert Advisors | 1 |
| Indicators (project) | Catalog under `Include/Indicators/` (supporting) |
| Scripts / Services (standalone) | 0 |
| Custom charts / panels | Dashboard engine (chart objects / widgets) |

---

## 5. Services / platforms (enterprise facades)

Primary `CGmEnterprise*Engine` (and Phase closures) wired through `CApplication`:

Cloud, Remote Monitor, Notifications, Infrastructure, Identity/License, Backup, Audit, API Gateway, Deployment, Trade Journal, Strategy Lab, Optimization Lab, Portfolio Analytics, Reporting Center, Configuration Center, AI Decision Center, Multi-Account Center, Command Center, Phase 1–7 Closures.

---

## 6. Database model

Not SQL — **file-backed tables** via `CGmFileManager` with prefixes such as:

`GM_CLOUD_*`, `GM_ETJ_*`, `GM_ESL_*`, `GM_EOL_*`, `GM_EPA_*`, `GM_ERC_*`, `GM_ECC_*`, `GM_ADC_*`, `GM_MAC_*`, `GM_EOC_*`, plus `GM_PHASE*_` closure packages.

---

## 7. APIs / interfaces

| Type | Notes |
|------|-------|
| Internal APIs | Engine `Init` / `Process` / `Last` / `ApplyToAISnapshot` / Bind* |
| External REST | Architecture-ready via API Gateway (observe/auth catalog) |
| FutureInterfaces | Explicit inactive stubs (Phase 4/5 autonomy reserved) |
| MQL5 Market API | Not separated yet (see edition plan) |

---

## 8. Dashboards / UI

| Surface | Notes |
|---------|-------|
| Enterprise Dashboard Engine | Phase 2 frozen foundation |
| AI widget strip (14 slots) | Remapped per sprint; currently Phase 7 certification view |
| Theme / Settings / Refresh | Existing dashboard subsystem |

---

*End of PROJECT_STRUCTURE.md*
