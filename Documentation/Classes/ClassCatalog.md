# Class Catalog

## Active Framework Classes

| Class | File | Responsibility |
|-------|------|----------------|
| `CGmApplication` | `Include/Core/CApplication.mqh` | Root orchestrator; engine wiring; ownership + recovery on Init |
| `CGmLogger` | `Include/Logging/CLogger.mqh` | DEBUG/INFO/SUCCESS/WARNING/ERROR logging |
| `CGmConfiguration` | `Include/Configuration/CConfiguration.mqh` | Settings + locked H4 strategy TF + Magic Number |
| `CGmErrorManager` | `Include/Core/CErrorManager.mqh` | Consistent error capture & severity reporting |
| `CGmTimeManager` | `Include/Core/CTimeManager.mqh` | H4 cycle clock; new-bar detection |
| `CGmSessionManager` | `Include/Core/CSessionManager.mqh` | Session classification framework |
| `CGmFileManager` | `Include/Core/CFileManager.mqh` | Safe text file helpers |
| `CGmTradeOwnership` | `Include/Trading/CTradeOwnership.mqh` | Rules #1–#4 Magic Number gate |
| `CGmStringHelper` | `Include/Utilities/CStringHelper.mqh` | Static string utilities |

## Isolated Engine Bases

| Class | Engine | File |
|-------|--------|------|
| `CGmRiskEngine` | Risk Engine (3% / 30pip / ATR TP) | `Include/Risk/CRiskEngine.mqh` |
| `CGmLotSizeEngine` | Dynamic lot calculator | `Include/Risk/CLotSizeEngine.mqh` |
| `CGmStopLossEngine` | Fixed 30-pip SL | `Include/Risk/CStopLossEngine.mqh` |
| `CGmAtrEngine` | ATR(14) H4 | `Include/Risk/CAtrEngine.mqh` |
| `CGmTakeProfitEngine` | ATR TP | `Include/Risk/CTakeProfitEngine.mqh` |
| `CGmBrokerValidator` | Pre-trade validation | `Include/Risk/CBrokerValidator.mqh` |
| `CGmTradeManager` | Activation + SL/TP enforce | `Include/Trading/CTradeManager.mqh` |
| `CGmTradeRegistry` | Persistent trade DB | `Include/Trading/CTradeRegistry.mqh` |
| `CGmPendingOrderEngine` | Pending Order Engine | `Include/Trading/CPendingOrderEngine.mqh` |
| `CGmCycleEngine` | H4 startup + rollover orchestrator | `Include/Trading/CCycleEngine.mqh` |
| `CGmTradeIdManager` | Unique Trade ID allocator | `Include/Trading/CTradeIdManager.mqh` |
| `CGmTradeOwnership` | Magic Number gate (Rules #1–#4) | `Include/Trading/CTradeOwnership.mqh` |
| `CGmStrategyEngineBase` | Core Strategy Engine | `Include/Trading/CStrategyEngineBase.mqh` |
| `CGmLevelEngine` | Trading Level Engine (official H4 math) | `Include/Calculation/CLevelEngine.mqh` |
| `CGmRecoveryBase` | Recovery Engine | `Include/Recovery/CRecoveryBase.mqh` |
| `CGmAIBase` | AI Intelligence Layer | `Include/AI/CAIBase.mqh` |
| `CGmAnalyticsBase` | Analytics Engine | `Include/Reports/CAnalyticsBase.mqh` |
| `CGmLevelBase` | Level calculation base | `Include/Calculation/CLevelBase.mqh` |
| `CGmRiskBase` | Risk base | `Include/Risk/CRiskBase.mqh` |
| `CGmTradeBase` | Trade management base | `Include/Trading/CTradeBase.mqh` |

## Supporting Types

| Symbol | File | Purpose |
|--------|------|---------|
| `SGmErrorRecord` | `CErrorManager.mqh` | Last-error snapshot struct |
| `ENUM_GM_APP_STATE` | `EnumsCore.mqh` | Application lifecycle states |
| `ENUM_GM_MODULE_STATUS` | `EnumsCore.mqh` | Module readiness |
| `ENUM_GM_SESSION_TYPE` | `EnumsCore.mqh` | Session buckets |
| `ENUM_GM_ERROR_SEVERITY` | `EnumsCore.mqh` | Error severities |
| `ENUM_GM_LOG_LEVEL` | `EnumsLogging.mqh` | Log levels |
| `ENUM_GM_LOG_DESTINATION` | `EnumsLogging.mqh` | Log destinations |
| Version macros | `Version.mqh` | Product identity & version banner |
| Define macros | `Defines.mqh` | Structural constants (non-strategy) |

## Entry Point

| Symbol | File | Role |
|--------|------|------|
| `g_app` (`CGmApplication`) | `Experts/TheGoldMindAI_Professional.mq5` | Global application instance |
| `OnInit` / `OnDeinit` / `OnTick` / `OnTimer` / `OnTrade` / `OnTradeTransaction` / `OnChartEvent` | same | Platform event bridges |
