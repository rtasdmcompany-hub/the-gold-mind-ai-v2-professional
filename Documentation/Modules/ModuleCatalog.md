# Module Catalog

| Module | Path | Sprint 1 Status | Purpose |
|--------|------|-----------------|---------|
| Core | `Include/Core` | **Active** | Application lifecycle, time, session, files, errors, versioning |
| Logging | `Include/Logging` | **Active** | Structured multi-level logging |
| Configuration | `Include/Configuration` | **Active** | Centralized settings manager |
| Utilities | `Include/Utilities` | **Active** | Shared string/helpers |
| Trading | `Include/Trading` | Base only | Future trade orchestration (`CGmTradeBase`) |
| Calculation | `Include/Calculation` | Base only | Future level engines (`CGmLevelBase`) |
| Risk | `Include/Risk` | Base only | Future risk engines (`CGmRiskBase`) |
| AI | `Include/AI` | Base only | Future AI engines (`CGmAIBase`) |
| Orders | `Include/Orders` | Placeholder | Future order send/modify/delete layer |
| Indicators | `Include/Indicators` | Placeholder | Future ATR/indicator wrappers |
| Recovery | `Include/Recovery` | Placeholder | Future recovery/hedge policies |
| Reports | `Include/Reports` | Placeholder | Future journals & exports |
| Backtesting | `Include/Backtesting` | Placeholder | Future tester helpers |
| Resources | `Resources/*` | Scaffold | Images, sounds, templates |
| Documentation | `Documentation/*` | **Active** | Architecture & sprint docs |
| Experts | `Experts` | **Active** | EA entry point |

## Module Interaction (Sprint 1)

- **Experts** → **Core/Application** only.
- **Application** owns and initializes Logging, Configuration, Errors, Time, Session, Files.
- Domain bases (Trading/Risk/Calculation/AI) are constructed and initialized as stubs.
- Placeholder modules are not linked into the runtime graph yet.
