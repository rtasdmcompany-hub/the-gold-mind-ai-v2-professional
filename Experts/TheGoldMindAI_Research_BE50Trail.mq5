//+------------------------------------------------------------------+
//|                               TheGoldMindAI_Research_BE50Trail.mq5|
//|                 The Gold Mind - H4 Grid  [RESEARCH BUILD 416]      |
//|  No H4 range lock | No hedge | shared SL last±50pip | +30 FULL   |
//+------------------------------------------------------------------+
#property copyright "RTAS Digital Marketing Company | RTAS Group of Companies"
#property version   "2.131"
#property description "RESEARCH BUILD 416 — NOT FOR LIVE. DO NOT attach to live account."
#property description "Any H4 range: 3 BUY + 3 SELL | broker SL last±50pip | no hedge."
#property link      "https://www.mql5.com/en/users/rtas"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

//--- Core constants
#define EXPERT_MAGIC              112234   // RESEARCH BUILD - isolated from production magic
#define GRID_LINE_PREFIX          "TGM_GL_"
#define UI_PREFIX                 "TGM_UI_"
#define TGM_AI_PANEL_PREFIX       "TGM_AI_" // legacy Phase11E chart objects — wiped on init
#define TGM_BE_STRATEGY_POINTS      500.0
#define TGM_TRAIL_STRATEGY_POINTS   300.0
#define TGM_STAGE1_AT_PIPS           30.0   // +30 pip -> FULL close (equity→balance)
#define TGM_STAGE1_CLOSE_PCT        100.0
#define TGM_STAGE2_AT_PIPS           30.0
#define TGM_STAGE2_CLOSE_PCT        100.0
#define TGM_STAGE3_AT_PIPS           30.0
#define TGM_STAGE3_CLOSE_PCT        100.0
#define TGM_STAGE3_REMAIN_PCT         0.0
#define TGM_STAGE4_AT_PIPS           30.0
#define TGM_RUNNER_TRAIL_PIPS         0.0   // no runner — full book at +30
#define TGM_LOT_SIZE_ON_BALANCE         1   // R415: size on BALANCE not floating equity
#define TGM_LOSS_HEDGE_PIPS          30.0   // open 1:1 hedge when parent loss >= 30 pip
#define TGM_LOSS_BE_PIPS             40.0   // parent -40pip (~hedge +10) -> arm BE on hedge
#define TGM_HEDGE_OWN_BE_PIPS        10.0   // hedge +10pip profit -> BE SL (parent untouched)
#define TGM_HEDGE_OWN_LOSS_PIPS      10.0   // hedge -10pip -> close HEDGE only (parent stays)
#define TGM_HEDGE_BE_PROFIT_PIPS     TGM_LOSS_BE_PIPS // legacy alias -> parent-loss BE trigger
#define TGM_SHARED_SL_BEYOND_LAST_PIPS 50.0 // pending shared SL = last level ±50pip (lot sizing)
#define TGM_RISK_DIST_PIPS           50.0   // fallback lot distance if shared SL missing
#define TGM_NO_FIXED_BROKER_SL          1   // parent pending SL NEVER stripped — stays until hit
#define R376_MAX_OPEN_GRID_TOTAL        6
#define R376_MAX_OPEN_GRID_PER_SIDE     3
#define R376_ENABLE_H4_DIRECTION_FILTER false
#define TGM_EXTREME_H4_RANGE_PIPS    250.0
#define TGM_EXTREME_H4_BODY_PIPS     180.0
#define TGM_EXTREME_H4_COOLDOWN_HOURS   24
#define TGM_SIDE_LOSS_STREAK_LIMIT   9999
#define TGM_MAX_LEVEL_ACTS_H4_HARD      1
#define TGM_H4_RANGE_MAX_PIPS       200.0
#define TGM_ATR_SL_PERIOD              14
#define TGM_BUILD_SERIAL             416
#define TGM_HEDGE_REOPEN_MIN_SEC        0
#define TGM_MANDATORY_REHEDGE_ATTEMPTS  3
#define TGM_R380_DISABLE_SHOCK_COOLDOWN 1
#define TGM_R380_DISABLE_SIDE_CASCADE   1
#define TGM_R380_FORCE_NO_H4_RANGE_FILTER 1   // R416: any H4 range — both sides always
#define TGM_FORCE_DISABLE_DAILY_PROFIT_LOCK 1

#include <AI/RiskGovernor/Phase17/CPhase17RiskGovernor.mqh>
#define TGM_RETCODE_FROZEN          10029
#define TGM_RISK_PER_TRADE_FRACTION 0.02   // 2% of BALANCE (R415) — not floating equity
#define TGM_HEDGE_TRIGGER_STRATEGY_PTS 500.0
#define TGM_HEDGE_CLOSE_STRATEGY_PTS   100.0
#define TGM_HEDGE_COMMENT              "GM_HEDGE"
#define TGM_MAX_GRID_POSITIONS_TOTAL    6
// Max activations/level/H4: PHASE18_MAX_LEVEL_ACTIVATIONS_H4 (default 2) — 1st SL re-arm; 2nd SL locks
#define TGM_MAX_HEDGE_CYCLES_PER_H4     3
#define TGM_HEDGE_REOPEN_RECOVERY_PTS   100.0
#define TGM_PROTECTION_SCAN_INTERVAL_SEC 10
#define TGM_PROTECTION_ALERT_INTERVAL_SEC 120
#define TGM_DEFAULT_EMERGENCY_PARENT_SL_PTS 750.0
#define TGM_DEFAULT_UNPROTECTED_HANG_SEC    90
#define TGM_MAX_HEDGE_FAIL_BEFORE_EMERGENCY 3
#define TGM_HEDGE_REARM_LOCKED      1.0
#define TGM_HEDGE_REARM_READY       2.0
#define TGM_HEDGE_REARM_ARMED       3.0   // READY + loss crossed back above trigger
#define TGM_HEDGE_CHOP_MAX_EVENTS   6     // rolling hedge-death samples for chop detect
#define TGM_GRID_LEVEL_IDLE         0.0
#define TGM_GRID_LEVEL_PENDING      1.0
#define TGM_GRID_LEVEL_LIVE         2.0
#define TGM_GRID_LEVEL_SPENT        3.0
#define TGM_DASHBOARD_BE_EPSILON    0.50
#define TGM_PANEL_WIDTH             250
#define TGM_PANEL_HEIGHT_MIN        48
#define TGM_PANEL_HEIGHT_FULL       300
#define TGM_HEADER_H                50
#define TGM_LOGO_W                  42
#define TGM_LOGO_H                  42
#define TGM_LOGO_X_OFFSET           7
#define TGM_LOGO_Y_OFFSET           5
#define TGM_TITLE_X_OFFSET          58
#define TGM_TITLE_Y_OFFSET          8
#define TGM_TAGLINE_Y_OFFSET        26
#define TGM_AUTOTRADE_COOLDOWN_SEC  30
#define TGM_TRADE_WARN_INTERVAL_SEC 300
#define TGM_MODIFY_RETRY_SEC        20
#define TGM_SERVER_PAUSE_SEC        900
#define TGM_DASHBOARD_TIMER_SEC     2
#define TGM_RETCODE_MARKET_CLOSED   10018
#define TGM_BASE_DEVIATION_PTS      50.0
#define CLEANUP_SLEEP_MS            300
#define CLEANUP_MAX_ITERATIONS      500

#ifndef OBJ_ALL_PERIODS
#define OBJ_ALL_PERIODS 0x00FFFFFF
#endif
#ifndef OBJ_NO_PERIODS
#define OBJ_NO_PERIODS 0x00000000
#endif

//--- Custom Logo (MQL5/Images/TheGoldMind_Logo.PNG - bundled for compile).
//    Drop any image (any size) at this path; the panel auto-fits it to the
//    logo frame at runtime. Keep the same file name so the resource resolves.
#resource "\\Images\\TheGoldMind_Logo.bmp"
#define LOGO_RESOURCE_PATH        "::Images\\TheGoldMind_Logo.bmp"
#define LOGO_FIT_RESOURCE         "::TGM_LogoFit"
#define TGM_UI_Z_PANEL            0
#define TGM_UI_Z_LOGO_FRAME       1
#define TGM_UI_Z_LOGO             3
#define TGM_UI_Z_HEADER           4
#define TGM_UI_Z_LABELS           10
#define TGM_UI_Z_BUTTON           11
#define UI_LEGACY_PREFIX_LOCK     "TGMLK_UI_"
#define UI_LEGACY_PREFIX_RTAS     "RTAS_"

//--- Risk mode enumeration
enum ENUM_RISK_MODE
  {
   RISK_AUTO_3_PERCENT_EQUITY = 0, // Auto: each trade risks 3% of account equity
   RISK_MANUAL_LOT            = 1  // Manual Lot Size
  };

//--- Mode A (hedge + loss-cap) permanently removed in v2.067 — Mode B only.

//--- R392 = no fixed SL | hedge@-30 | hedge-only BE@-40 (parent stays) | profit ladder | 3%
// H4<=200 | NO broker SL | hedge cycles open/BE/close until parent profit method
input group "--- Risk & Lot Sizing ---"
input ENUM_RISK_MODE RiskMode           = RISK_AUTO_3_PERCENT_EQUITY; // Risk Mode
input double         Manual_Lot_Size      = 0.50; // Manual lot size (RiskMode=Manual only)
input double         Max_Lot_Size         = 5.00; // Hard lot cap

input group "--- ATR Fallback ---"
const double         InpFixedStopLossUSD  = 3.00; // Fallback risk-distance only (no broker SL)

input group "--- Live ATR Indicator Settings ---"
input int            ATR_Period           = 12; // ATR period for TP only

input group "--- SL & TP Settings ---"
const bool           Enable_ATR_StopLoss  = false; // R392: NO fixed/ATR broker SL
const double         SL_ATR_Multiplier    = 1.0;   // unused
input double         TP_ATR_Multiplier    = 1.0;   // TP = ATR-12 × this

input group "--- Price-Based ($) Profit Engine ---"
const double         InpProfitBE          = 3.00;  // profit-side BE reference
const double         InpTrailingStopUSD   = 2.00;  // unused in R393

//--- Hedge loss-control (R412): hedge@-30 | hedge +10pip BE | hedge -10pip close | parent SL stays
const double         InpHedgeTriggerUSD   = 3.00;  // ~30pip on XAU (overridden by pip gate)
const double         InpHedgeStopLossUSD  = 1.00;  // ~10pip death SL on hedge only (see TGM_HEDGE_OWN_LOSS_PIPS)
const double         InpHedgeBreakEvenUSD = 1.00;  // ~10pip BE on hedge (see TGM_HEDGE_OWN_BE_PIPS)
const double         InpHedgeRearmClearUSD = 3.00;
const int            InpHedgeRearmMinSec  = TGM_HEDGE_REOPEN_MIN_SEC; // anti-spam between hedge cycles
const double         InpHedgeReturnArmUSD = 0.00;
const bool           Enable_LossCapEngine     = false;
const double         InpLossCapUSD            = 6.00;
const double         InpHedgeReleaseUSD       = 1.00; // release hedge when parent nearly recovered
const bool           Enable_ParentHardCapSL   = false;
const bool           Enable_Hedge_Protection   = false; // R416: hedge OFF — broker SL only
const bool           InpHedgeChopFreezeEnable  = false;
const double         InpHedgeChopRangeUSD    = 2.00;
const int            InpHedgeChopMinDeaths   = 2;
const int            InpHedgeChopWindowSec = 900;
const double         InpHedgeChopBreakoutUSD = 3.00;
const int            InpHedgeChopFreezeMinSec= 180;

input group "--- Account Protection (mandatory safety) ---"
input bool           Enable_Account_Protection = true;  // Master safety switch - limits exposure
input double         Max_Floating_DD_Percent   = 15.0; // Layer 1: block NEW grid at this floating DD %
const int            Max_Hedge_Cycles_Per_H4   = 0;    // legacy unused (Mode A removed)
const int            Hedge_Retry_Seconds       = 30;   // legacy unused (Mode A removed)
const bool           Enable_Basket_TP          = false; // permanently OFF (Mode A removed)
const double         Basket_TP_Amount          = 500.0;
const bool           Enable_TrendBleedProtect  = false; // R380 OFF — both sides always allowed

input group "--- Kill Switch (last resort) ---"
// R395: Kill Switch DISABLED in research — hedge system pure test (no forced close interference).
const bool           Enable_Triple_Protection       = false; // Layer 3 OFF for hedge research
const double         Emergency_Parent_SL_Points     = 750.0; // legacy Layer 2 (unused in Mode B)
const int            Unprotected_Hang_Seconds       = 90;    // legacy Layer 2 (unused in Mode B)
const double         Emergency_Close_DD_Percent     = 9999.0; // R395 RESEARCH: disabled
const double         Max_Daily_Loss_Percent         = 9999.0; // R395 RESEARCH: disabled

input group "--- Advanced Trade Management ($ Based) ---"
const bool           Enable_BreakEven        = true;   // R375 LOCKED: BE always on
const bool           Enable_PartialClose     = false;  // R375 LOCKED: no partial close via old engine
const double         PartialClose_Percent    = 0.0;    // R375 LOCKED: unused

//--- Globals
CTrade              g_trade;
int                 g_atrHandle              = INVALID_HANDLE; // ATR-12 for TP
int                 g_atrSlHandle            = INVALID_HANDLE; // ATR-14 for SL
datetime            g_lastH4BarTime          = 0;
datetime            g_lastDashboardUpdate    = 0;
datetime            g_historyCacheH4Start    = 0;
bool                g_historyCacheSelectOk   = false;
double              point_modifier           = 1.0;

int                 g_uiX                    = 15;
int                 g_uiY                    = 40;
bool                g_uiMinimized            = false;
bool                g_isDragging             = false;
int                 g_dragOffsetX            = 0;
int                 g_dragOffsetY            = 0;
datetime            g_autotradeCooldownUntil  = 0;
datetime            g_lastTradeBlockWarnTime  = 0;
datetime            g_lastRetcode10026LogTime = 0;
bool                g_autotradeBoxShown       = false;
datetime            g_serverTradePausedUntil  = 0;
datetime            g_modifyPausedUntil       = 0;
datetime            g_lastServerPauseLogTime  = 0;
string              g_lastServerPauseReason   = "";
datetime            g_lastProtectionAlertTime  = 0;
bool                g_gridStrategyBusy         = false; // re-entrancy lock for ExecuteH4GridStrategy
datetime            g_lastEmptyGridRebuildH4  = 0;     // one-shot same-H4 rebuild when bot has no live/pending trades
bool                g_accountProtectionActive = false;
string              g_accountProtectionReason = "";
bool                g_emergencyKillSwitchActive = false;
string              g_emergencyKillSwitchReason = "";
bool                g_marketValidationCompleted = false; // tester: true after Market validation trades done

//--- R408: paired parent+hedge cycle nets (MT5 report splits them; this is the truth)
int                 g_pairCycles             = 0;
int                 g_pairWins               = 0;
int                 g_pairLosses             = 0;
int                 g_pairUnhedgedSL         = 0;
double              g_pairNetSum             = 0.0;
double              g_pairWinSum             = 0.0;
double              g_pairLossSum            = 0.0;
double              g_pairWorstNet           = 0.0;
double              g_pairBestNet            = 0.0;

//--- Forward declarations
bool   ShouldRenderUI();
void   RecordPairedCycleNet(const double netMoney, const bool hedged, const string tag);
void   LogPairedNetSummary();
double SumLiveHedgeMoneyForParent(const ulong parentTicket);
void   InitBrokerPointModifier();
bool   GetLiveATR(double &atrOut);
bool   GetLiveAtrSl(double &atrOut);
void   DeleteLegacyAiPanelObjects();
double GetLiveAtrStopDistance();
double GetConfiguredStopDistance();
bool   GetSharedGridSideStopLoss(const ENUM_POSITION_TYPE side, double &slOut);
bool   IsResearchH4RangeAllowed(string &reasonOut);
bool   CalculateH4GridLevels(double &high1, double &low1, double &pivot, double &buy1, double &buy2, double &buy3, double &sell1, double &sell2, double &sell3);
bool   CalculateExcelGridSLTP(const double buy1, const double buy2, const double buy3, const double sell1, const double sell2, const double sell3, const double atrValue, double &buySL, double &sellSL, double &buyTP1, double &buyTP2, double &buyTP3, double &sellTP1, double &sellTP2, double &sellTP3);
double StrategyPointsToBrokerPoints(const double strategyPoints);
double StrategyPointsToPriceDistance(const double strategyPoints);
void   ManagePositionTradeLifecycle(const ulong ticket);
void   CloseAllBotPositions(const string reason);
void   CloseAllBotPositionsForced(const string reason);
void   RecordEaBuildSerial();
bool   EnsureAllBotPendingDeleted();
bool   EnsureAllBotPendingDeletedForced();
void   CleanupEAChartVisuals();
bool   PreTradeGuard(const string operation);
bool   PreProtectionTradeGuard(const string operation);
bool   HasOpenBotPositions();
bool   IsPositionMgmtAllowed();
bool   IsGridOpsAllowed();
bool   IsTradeOpsAllowed();
bool   IsWeekendOrMarketClosed();
bool   IsTradeProfitZoneSecured(const ulong ticket);
bool   IsModifyTradeOperation(const string operation);
bool   IsNearSessionBreak(const int warningSec = 300);
bool   ResolveGridLevelSide(const string level, ENUM_POSITION_TYPE &sideOut);
datetime GetTradeDayStart(const datetime when);
datetime GetNextTradeDayStart(const datetime when);
string DirectionalLossCountKey(const ENUM_POSITION_TYPE side, const datetime when);
string DirectionalPauseKey(const ENUM_POSITION_TYPE side);
string ExtremeH4ShockUntilKey();
string ExtremeH4ShockBarKey();
int    GetDirectionalLossCountToday(const ENUM_POSITION_TYPE side, const datetime when);
void   ResetDirectionalLossCountToday(const ENUM_POSITION_TYPE side, const datetime when);
void   RecordDirectionalLossAndMaybePause(const ENUM_POSITION_TYPE side, const datetime eventTime, const string level, const double net);
bool   IsDirectionalPauseActive(const ENUM_POSITION_TYPE side, string &reasonOut);
void   UpdateExtremeH4ShockCooldown();
bool   IsExtremeH4ShockCooldownActive(string &reasonOut);
int    CancelPendingOrdersForSide(const ENUM_POSITION_TYPE side);
void   ClearResearchRuntimeGuards();
void   MarkBreakEvenPending(const ulong ticket);
void   ClearBreakEvenPending(const ulong ticket);
bool   IsBreakEvenPending(const ulong ticket);
bool   TryApplyBreakEvenAndPartial(const ulong ticket, const bool forceAttempt = false);
void   ProcessBreakEvenPriorityQueue();
bool   IsDashboardMarketClosed();
string GetDashboardClosedStatusLabel();
void   RegisterServerTradePause(const uint retcode, const string operation);
void   MonitorServerTradeRecovery();
bool   IsTradeModifyCooldownActive();
void   ShowAutoTradeSetupWarningIfNeeded();
void   EnableDashboardChartEvents();
void   EnsureDashboardPresent();
void   UpdateDashboard(const bool forceUpdate = false);
void   DestroyAllChartDashboardUI();
bool   CreateUIBitmap(string name, string bmp_path);
void   CreateUISeparator(string name);
void   CreateUILogoFrame();
bool   BuildScaledLogoResource(const string srcResource, const int dstW, const int dstH);
bool   LoadDashboardLogo();
void   RemoveLogoFrame();
void   RemoveDashboardDragHandle();
bool   IsDashboardSymbolMatch(const string dealSymbol);
bool   IsDashboardDealRelevant(const ulong ticket);
double GetDashboardDealNetProfit(const ulong ticket);
bool   IsGridPositionComment(const string comment);
bool   IsBotGridPendingOrder(const ulong orderTicket);
int    CountGridOpenPositions();
bool   GetTradeSessionWindow(datetime &fromOut, datetime &toOut, bool &sessionOpenOut);
void   CollectDashboardTradeStats(double &sessionProfit, int &openGridTrades, int &openHedgeTrades, int &sessionOpenedGrid, int &sessionClosedTotal, int &sessionClosedWins, int &sessionClosedLosses);
bool   AddUniquePositionId(const long positionId, long &ids[]);
bool   GetDashboardDayWindow(datetime &fromOut, datetime &toOut);
bool   IsDashboardGridPositionId(const long positionId);
bool   IsDashboardGridEntryDeal(const ulong dealTicket);
bool   IsDashboardGridClosingDeal(const ulong dealTicket);
double SumGridPositionSessionNet(const long positionId, const datetime sessFrom, const datetime statsEnd);
bool   IsSessionPositionIdSeen(const long positionId, const long &seenIds[]);
string FormatDashboardMoney(const double value);
color  GetDailyProfitColor(const double dailyProfit);
void   SetUILabelColor(const string name, const color textColor);
string GetDashboardMarketStatus();
color  GetMarketStatusColor(const string status);
void   InitDashboard();
void   RenderDashboardLayout();
int    ExecuteH4GridStrategy(const bool freshH4Cycle = false);
bool   PlaceBuyLimit(const double price, const double sl, const double tp, const double slDistForLots, const int levelIndex, const string comment);
bool   PlaceBuyStop(const double price, const double sl, const double tp, const double slDistForLots, const int levelIndex, const string comment);
bool   PlaceSellLimit(const double price, const double sl, const double tp, const double slDistForLots, const int levelIndex, const string comment);
bool   PlaceSellStop(const double price, const double sl, const double tp, const double slDistForLots, const int levelIndex, const string comment);
void   LogLotCalculationDetail(const string tag, const string comment, const int levelIndex, const double slDistancePrice, const double finalLots);
void   RefreshGridOnNewH4Bar(const string trigger);
void   ForceRebuildCurrentGrid(const string trigger);
bool   MaybeForceRebuildCurrentH4IfEmpty(const string trigger);
void   RefreshGridChartLinesFromH4();
void   UniversalGoldTrailingEngine();
void   UpdateHedgePeakProfitPoints(const ulong hedgeTicket, const double pointsInProfit);
double GetHedgePeakProfitPoints(const ulong hedgeTicket);
void   ClearHedgePeakProfitPoints(const ulong hedgeTicket);
bool   ShouldCloseHedgeOnMarketReturn(const ulong hedgeTicket, const ulong parentTicket, const double point, const double closeBrokerPts, const double triggerBrokerPts);
void   ProcessHedgeProtectionEngine();
void   SyncHedgeOrphanPositions();
void   ClearMandatoryHedgeGates(const ulong parentTicket);
bool   ForceRehedgeIfParentStillInLoss(const ulong parentTicket, const string reason);
void   EnforceMandatoryHedgeCoverage();
void   ProcessHedgeExitRehedgeFromDeal(const ulong dealTicket);
void   ProcessHedgeFillBindFromDeal(const ulong dealTicket);
ulong  FindHedgeProtectStopTicket(const ulong parentTicket);
int    CancelHedgeProtectStopsForParent(const ulong parentTicket, const string reason);
bool   PlaceHedgeProtectStop(const ulong parentTicket);
void   EnsureHedgeProtectArmed(const ulong parentTicket);
void   ManageHedgeBreakEvenCycle();
bool   ArmHedgeBreakEvenSL(const ulong hedgeTicket);
void   ProcessBreakEvenPriorityQueue();
void   RunAccountProtectionEngine();
void   EnforceHedgeCoverageScan();
void   MonitorAccountDrawdownProtection();
void   EnforceSurvivalBeforeStopOut();
int    CountGridPositions();
int    CountHedgePositions();
bool   IsGridPlacementAllowed(const bool freshH4Cycle = false);
bool   IsHedgeOpenAllowedForParent(const ulong parentTicket, const double parentLossPts);
void   ClearHedgeProtectionState(const ulong parentTicket);
void   LogProtectionAlert(const string message);
void   MonitorLayer3HardKillSwitch();
void   EnforceLayer2EmergencyParentProtection();
bool   IsKillSwitchActiveToday();
bool   ApplyEmergencyParentSL(const ulong ticket);
bool   CloseGridPositionEmergency(const ulong ticket, const string reason);
bool   SafePositionModify(const ulong ticket, const double sl, const double tp, const string operation);
bool   IsBrokerStopDistanceOK(const ENUM_POSITION_TYPE posType, const double refPrice, const double slPrice);
bool   EnsureParentHasBrokerSL(const ulong ticket);
bool   ApplyParentHardLossCap(const ulong parentTicket);
bool   TryReleaseStickyHedge(const ulong parentTicket);
bool   CloseHedgePosition(const ulong hedgeTicket, const string reason);
bool   IsProfitEngineArmed(const ulong ticket);
void   SetHedgeTriggerReady(const ulong parentTicket, const bool ready);
bool   EnsureModeBFixedBrokerSL(const ulong parentTicket);
void   CloseStrayHedgesInFixedSlMode();
double GetActiveHedgeBreakEvenUSD();
bool   IsFixedSlReentryMode();
bool   IsLossCapHedgeMode();
bool   IsHedgeEngineActive();
bool   IsLossCapEngineActive();
double GetActiveHedgeTriggerUSD();
string ResolveGridLevelNameFromComment(const string comment);
string ResolveGridLevelFromClosedDeal(const ulong dealTicket, const string dealComment);
void   ProcessModeBLevelExitFromDeal(const ulong dealTicket);
string LevelBELockKey(const string comment);
bool   IsLevelBELockedThisH4(const string comment);
void   MarkLevelBELockedThisH4(const string comment);
void   ClearAllLevelBELocksThisH4();
int    GetLevelActivationCountThisH4(const string comment);
int    MaxLevelActivationsThisH4();
bool   LevelHasLivePositionThisH4(const string comment);
int    CancelPendingOrdersForLevel(const string comment);
void   IncrementLevelActivationThisH4(const string comment);
void   ClearAllLevelActivationCountsThisH4();
bool   IsLevelActivationExhaustedThisH4(const string comment);
void   MarkLevelActivationExhaustedThisH4(const string comment);
void   LogPriceThroughOnce(const string comment, const string reason);
string ResolveGridLevelCommentFromTicket(const ulong ticket);
void   ShowManualLotWarning();
void   SetFillingMode();
bool   IsGoldChartSymbol();
bool   IsMarketValidationMode();
bool   IsSymbolTradeSessionOpen();
bool   ValidationMarketDealCheck(const ENUM_ORDER_TYPE orderType, const double lots);
bool   RunMarketValidationTradeOnce();
void   SynchronizePersistentState(const string reason);
void   SynchronizeGridLevelStates(const string reason);
void   SeedHedgeMonitorForParent(const ulong parentTicket);
void   TryUnlockHedgeAfterRecovery(const ulong parentTicket);
void   ApplyHedgeRecycleCooldown(const ulong parentTicket, const int lifeSec);
void   HealStaleHedgeLock(const ulong parentTicket);
void   ProcessBasketTakeProfit();
double GetTotalBotGridParentVolume();
double GetReferenceLotForBasketScaling();
double GetEffectiveBasketTpTarget();
bool   HasBasketPrematureWinners();
void   EnforceTrendBleedProtect();
bool   HasWinningSideArmed(const ENUM_POSITION_TYPE side);
bool   IsOppositeBleedPaused(const ENUM_POSITION_TYPE sideToRestrict);
int    CountOpenGridParents(const ENUM_POSITION_TYPE sideFilter = (ENUM_POSITION_TYPE)-1);
bool   R376_AllowGridSideThisH4(const ENUM_POSITION_TYPE side, const double pivot, const double prevClose);
int    DeleteBotPendingsOfType(const ENUM_ORDER_TYPE orderType);
bool   IsHedgeReturnArmed(const ulong hedgeTicket);
void   MarkHedgeReturnArmed(const ulong hedgeTicket);
void   ClearHedgeReturnArmed(const ulong hedgeTicket);
bool   IsPriceBackAtHedgeEntry(const ulong hedgeTicket);
void   ManageLiveHedge(const ulong hedgeTicket);
void   ResetAllGridLevelStates();
bool   PositionMatchesGridComment(const ulong positionTicket, const string comment);
ulong  FindGridPositionTicketByCommentThisH4(const string comment, const datetime currentH4);
ulong  FindGridPendingTicketByComment(const string comment);
bool   PendingCommentMatchesLevel(const string orderComment, const string levelComment);
int    CancelDuplicatePendingsAtSamePrice();
bool   GetPositionOpeningComments(const ulong positionTicket, string &dealCommentOut, string &orderCommentOut);
bool   WasOpenedAsGridLimit(const ulong positionTicket);
bool   IsOurBotMagicPosition(const ulong ticket);
bool   IsOurBotGridParent(const ulong ticket);
bool   IsForeignOrManualPosition(const ulong ticket);
bool   IsBotHedgePosition(const ulong ticket, const string comment);
ulong  StrictHedgeParentTicket(const ulong hedgeTicket, const string comment);
ulong  ResolveHedgeParentTicket(const ulong hedgeTicket, const string comment);
ulong  FindParentForLinkedHedge(const ulong hedgeTicket);
bool   IsProfitEngineArmed(const ulong ticket);
bool   IsPartialClosedBeRunner(const ulong ticket);
void   MarkPartialClosedBeRunner(const ulong ticket);
void   LogPhase28A(const string eventName, const ulong ticket, const string detail);
double GetPositionProfitPips(const ulong ticket);
double GetPositionLossPips(const ulong ticket);
double GetTicketNetMoney(const ulong ticket);
bool   StripPositionTakeProfit(const ulong ticket, const string reason);
bool   StripPositionStopLoss(const ulong ticket, const string reason);
void   RememberParentPendingSL(const ulong ticket);
bool   RestoreParentPendingSL(const ulong ticket, const string reason);
void   CloseHedgesForParent(const ulong parentTicket, const string reason);
void   ProcessParentExitCloseHedges(const ulong dealTicket);
bool   ApplyBreakEvenSlNoTp(const ulong ticket, const double beSL, const string reason);
double GetPositionProfitUSD(const ulong ticket);
void   ClearGridLevelState(const string comment);
void   SaveGridH4BarTime(const datetime barTime);
void   CleanDeadGlobalVariables();
void   RebindOrphanHedgeLinks();
void   AssignOrphanHedgesToParents();

//+------------------------------------------------------------------+
//| Expert initialization                                            |
//+------------------------------------------------------------------+
int OnInit()
  {
   if(ATR_Period < 1)
     {
      Print("The Gold Mind: ATR_Period must be >= 1.");
      return INIT_PARAMETERS_INCORRECT;
     }
   if(SL_ATR_Multiplier <= 0.0)
     {
      Print("The Gold Mind: SL_ATR_Multiplier must be > 0.");
      return INIT_PARAMETERS_INCORRECT;
     }
   if(TP_ATR_Multiplier <= 0.0)
     {
      Print("The Gold Mind: TP_ATR_Multiplier must be > 0.");
      return INIT_PARAMETERS_INCORRECT;
     }
   if(Enable_PartialClose && (PartialClose_Percent <= 0.0 || PartialClose_Percent >= 100.0))
     {
      Print("The Gold Mind: PartialClose_Percent must be between 0 and 100 (exclusive).");
      return INIT_PARAMETERS_INCORRECT;
     }
   if(Max_Floating_DD_Percent <= 0.0 || Max_Floating_DD_Percent > 50.0)
     {
      Print("The Gold Mind: Max_Floating_DD_Percent must be between 0 and 50.");
      return INIT_PARAMETERS_INCORRECT;
     }
   if(Max_Lot_Size < 0.0)
     {
      Print("The Gold Mind: Max_Lot_Size must be >= 0 (0 = no EA cap).");
      return INIT_PARAMETERS_INCORRECT;
     }
   if(InpFixedStopLossUSD <= 0.0)
     {
      Print("The Gold Mind: InpFixedStopLossUSD must be > 0 (fixed $ SL / ATR fallback).");
      return INIT_PARAMETERS_INCORRECT;
     }
   if(Enable_Triple_Protection &&
      (Emergency_Close_DD_Percent <= Max_Floating_DD_Percent || Emergency_Close_DD_Percent > 40.0))
     {
      Print("The Gold Mind: Emergency_Close_DD_Percent must be > Max_Floating_DD_Percent and <= 40.");
      return INIT_PARAMETERS_INCORRECT;
     }
   if(Enable_Triple_Protection &&
      (Max_Daily_Loss_Percent <= 0.0 || Max_Daily_Loss_Percent > 40.0))
     {
      Print("The Gold Mind: Max_Daily_Loss_Percent must be between 0 and 40.");
      return INIT_PARAMETERS_INCORRECT;
     }
   if(PHASE18_ENABLE_DD_GOVERNOR)
     {
      if(PHASE18_DD_HARD_LIMIT_PERCENT <= 0.0 || PHASE18_DD_HARD_LIMIT_PERCENT > 90.0)
        {
         Print("The Gold Mind: PHASE18_DD_HARD_LIMIT_PERCENT must be between 0 and 90.");
         return INIT_PARAMETERS_INCORRECT;
        }
      if(PHASE18_DD_FREEZE_PERCENT >= PHASE18_DD_HARD_LIMIT_PERCENT ||
         PHASE18_DD_RISK_REDUCTION_PERCENT >= PHASE18_DD_FREEZE_PERCENT ||
         PHASE18_DD_RISK_REDUCTION_PERCENT <= 0.0)
        {
         Print("The Gold Mind: PHASE18 DD levels must satisfy 0 < RiskReduction < Freeze < HardLimit.");
         return INIT_PARAMETERS_INCORRECT;
        }
     }
   if(PHASE18_ENABLE_DAILY_PROFIT_LOCK && (PHASE18_DAILY_PROFIT_LOCK_PERCENT <= 0.0 || PHASE18_DAILY_PROFIT_LOCK_PERCENT > 50.0))
     {
      Print("The Gold Mind: PHASE18_DAILY_PROFIT_LOCK_PERCENT must be between 0 and 50.");
      return INIT_PARAMETERS_INCORRECT;
     }
   if(PHASE18_ENABLE_H4_RANGE_FILTER && PHASE18_MAX_H4_RANGE_PIPS <= 0.0)
     {
      Print("The Gold Mind: PHASE18_MAX_H4_RANGE_PIPS must be > 0 when H4 range filter is enabled.");
      return INIT_PARAMETERS_INCORRECT;
     }
   if(PHASE18_MAX_LEVEL_ACTIVATIONS_H4 < 1)
     {
      Print("The Gold Mind: PHASE18_MAX_LEVEL_ACTIVATIONS_H4 must be >= 1.");
      return INIT_PARAMETERS_INCORRECT;
     }

   if(RiskMode == RISK_MANUAL_LOT && ShouldRenderUI())
      ShowManualLotWarning();

   InitBrokerPointModifier();

   g_trade.SetExpertMagicNumber(EXPERT_MAGIC);
   g_trade.SetDeviationInPoints((ulong)MathRound(TGM_BASE_DEVIATION_PTS * point_modifier));
   SetFillingMode();

   g_atrHandle = iATR(_Symbol, PERIOD_H4, ATR_Period);
   if(g_atrHandle == INVALID_HANDLE)
     {
      Print("The Gold Mind: Failed to create iATR(TP) handle. GetLastError=", GetLastError());
      return INIT_FAILED;
     }
   g_atrSlHandle = INVALID_HANDLE; // R392: no ATR/fixed broker SL

   double initAtrTp = 0.0;
   if(GetLiveATR(initAtrTp))
     {
      const int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
      const double riskDist = GetConfiguredStopDistance();
      PrintFormat("The Gold Mind: H4 ATR-TP(%d)=%.*f | sharedSL last±%.0fpip | hedge=OFF | any H4 range OK",
                  ATR_Period, digits, initAtrTp,
                  TGM_SHARED_SL_BEYOND_LAST_PIPS);
     }

   if(ShouldRenderUI())
     {
      DestroyAllChartDashboardUI();
      InitDashboard();
      EnableDashboardChartEvents();
      RefreshGridChartLinesFromH4();
      EventSetTimer(TGM_DASHBOARD_TIMER_SEC);
     }

   DeleteLegacyAiPanelObjects(); // wipe leftover Phase11E chart panel
   Phase17_OnInit();

   // R380: tester must start clean so consecutive runs are comparable.
   if(IsStrategyTester())
      ClearResearchRuntimeGuards();

   if(!IsStrategyTester())
     {
      RecordEaBuildSerial();
      Print("The Gold Mind: EA started - open positions and pendings preserved on reload.");
     }

   g_historyCacheH4Start = 0;
   g_historyCacheSelectOk = false;

   g_lastH4BarTime = LoadGridH4BarTime();
   SynchronizePersistentState("OnInit");
   if(!IsMarketValidationMode() && IsGoldChartSymbol())
     {
      if(IsNewH4GridPeriod())
         RefreshGridOnNewH4Bar("OnInit-Fresh");
      else if(IsGridPlacementAllowed())
        {
         if(!MaybeForceRebuildCurrentH4IfEmpty("OnInit-EmptySameH4"))
            ExecuteH4GridStrategy();
        }
     }
   else if(!IsMarketValidationMode())
      Print("The Gold Mind: Non-Gold symbol (", _Symbol, ") - grid/trading disabled. Use XAUUSD on H4.");

   if(!IsStrategyTester() && IsWeekendOrMarketClosed())
     {
      g_serverTradePausedUntil = TimeCurrent() + TGM_SERVER_PAUSE_SEC;
      g_lastServerPauseReason = "Market closed (weekend / session)";
      Print("The Gold Mind: Market closed (session break) - trade ops paused until quotes resume.");
     }

   if(!IsStrategyTester())
     {
      const string block = GetAutoTradeBlockReason();
      if(block != "")
         Print("The Gold Mind: Trade blocked - ", block);
     }

   Print("The Gold Mind v2.131 (build ", TGM_BUILD_SERIAL, "): Initialized on ", _Symbol, " (", _Digits, " digits).");
   PrintFormat("TGM: Max activations/level/H4=%d (ONE shot — no re-arm).",
               MaxLevelActivationsThisH4());
   PrintFormat("TGM [R416]: H4 range lock OFF | hedge OFF | lots=BALANCE | +30=FULL book.");
   PrintFormat("TGM [OWNERSHIP]: Magic=%d ONLY — manual/foreign trades are invisible (no manage, no DD, no block).", EXPERT_MAGIC);
   Print("TGM [H4-POLICY]: Each H4 -> 3 BUY + 3 SELL (any range) | shared SL last±50pip on all 3 levels.");
   Print("TGM [METHOD]: Profit +30pip FULL book | Loss: broker shared SL only (no hedge).");
   PrintFormat("TGM [LOT]: Max_Lot_Size=%.2f | AutoRisk=%.0f%% BALANCE | conservative L1 distance.",
               Max_Lot_Size, TGM_RISK_PER_TRADE_FRACTION * 100.0);
   if(InpTrailingStopUSD > 3.01 || InpTrailingStopUSD < 2.99)
      PrintFormat("TGM [WARN]: InpTrailingStopUSD=%.2f (expected 3.00). Set Inputs trail to 3.", InpTrailingStopUSD);
   return INIT_SUCCEEDED;
  }

//+------------------------------------------------------------------+
//| Expert deinitialization                                          |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   EventKillTimer();

   if(g_atrHandle != INVALID_HANDLE)
     {
      IndicatorRelease(g_atrHandle);
      g_atrHandle = INVALID_HANDLE;
     }
   if(g_atrSlHandle != INVALID_HANDLE)
     {
      IndicatorRelease(g_atrSlHandle);
      g_atrSlHandle = INVALID_HANDLE;
     }

   // NOTE: we intentionally do NOT close positions / delete pendings here.
   //  * On REASON_REMOVE / CHARTCLOSE the terminal has already disabled trading
   //    for this instance, so any trade call fails ("program is stopped, trading
   //    is disabled") and the futile round-trips make OnDeinit overrun its ~2.5s
   //    budget -> MT5 kills the handler -> "Abnormal termination" in the log.
   //  * The design is that the system manages its own trades; leaving them in
   //    place (grid pendings + open positions with their broker SL / hedge) is
   //    safer than blind market-closing everything the instant the EA is pulled.
   if(reason == REASON_REMOVE || reason == REASON_CHARTCLOSE)
      Print("The Gold Mind: EA removed - trades & pendings left intact (managed exits only).");

   if(reason != REASON_CHARTCHANGE)
     {
      LogPairedNetSummary();
      Phase17_LogSummary();
      CleanupEAChartVisuals();
     }
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   // Market validation: place immediate tester trades once, then unlock the
   // full grid/hedge engine for the remainder of a long backtest.
   static bool validation_completed = false;
   if(!validation_completed && IsMarketValidationMode())
     {
      if(RunMarketValidationTradeOnce())
        {
         validation_completed = true;
         g_marketValidationCompleted = true;
         // Fall through into the main strategy on this same tick.
        }
      else
         return; // Still waiting for the next validation bar/session.
     }

   if(!IsGoldChartSymbol())
     {
      return;
     }

   static datetime lastStateSync = 0;
   const datetime nowSync = TimeCurrent();
   if(nowSync != lastStateSync)
     {
      SynchronizePersistentState("OnTick");
      lastStateSync = nowSync;
     }

   static int warmupTicks = 0;
   if(warmupTicks < 5)
     {
      warmupTicks++;
      if(warmupTicks == 5)
         ShowAutoTradeSetupWarningIfNeeded();
     }

   MonitorServerTradeRecovery();
   Phase17_OnTickUpdate(); // DD / daily lock / H4 range diagnostics (gates placement separately)
   if(Phase17_ConsumePendingCancelRequest())
     {
      EnsureAllBotPendingDeletedForced();
      Print("TGM [P17B]: Bot pendings cancelled after DD freeze (open positions untouched).");
     }

   if(IsGridOpsAllowed())
     {
      if(IsNewH4GridPeriod()) RefreshGridOnNewH4Bar("OnTick");
      else if(!MaybeForceRebuildCurrentH4IfEmpty("OnTick-EmptySameH4"))
         ExecuteH4GridStrategy(); // same-H4 refill after SL (level active until profit BE)
     }

   if(IsPositionMgmtAllowed() || HasOpenBotPositions())
     {
      RunAccountProtectionEngine();
      if(IsHedgeEngineActive())
        {
         SyncHedgeOrphanPositions();
         EnforceMandatoryHedgeCoverage();
        }
     }

   CleanDeadGlobalVariables();

   if(ShouldRenderUI())
      UpdateDashboard();
  }

void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
  {
   if(IsMarketValidationMode() || !IsGoldChartSymbol())
      return;

   if((trans.type == TRADE_TRANSACTION_DEAL_ADD || trans.type == TRADE_TRANSACTION_HISTORY_ADD) && trans.deal > 0)
     {
      ProcessModeBLevelExitFromDeal(trans.deal);
      if(IsHedgeEngineActive())
        {
         ProcessParentExitCloseHedges(trans.deal);
         ProcessHedgeFillBindFromDeal(trans.deal);
         ProcessHedgeExitRehedgeFromDeal(trans.deal);
        }

      if(IsHedgeEngineActive() &&
         HistoryDealSelect(trans.deal) &&
         HistoryDealGetInteger(trans.deal, DEAL_ENTRY) == DEAL_ENTRY_IN &&
         !IsHedgePositionComment(HistoryDealGetString(trans.deal, DEAL_COMMENT)) &&
         !IsTrackedHedgeTicket((ulong)HistoryDealGetInteger(trans.deal, DEAL_POSITION_ID)))
        {
         const ulong filled = (ulong)HistoryDealGetInteger(trans.deal, DEAL_POSITION_ID);
         if(filled > 0)
            EnsureHedgeProtectArmed(filled);
        }
     }

   if(trans.type == TRADE_TRANSACTION_ORDER_ADD ||
      trans.type == TRADE_TRANSACTION_ORDER_UPDATE ||
      trans.type == TRADE_TRANSACTION_ORDER_DELETE ||
      trans.type == TRADE_TRANSACTION_DEAL_ADD ||
      trans.type == TRADE_TRANSACTION_HISTORY_ADD ||
      trans.type == TRADE_TRANSACTION_POSITION)
      SynchronizePersistentState("OnTradeTransaction");
  }

//+------------------------------------------------------------------+
//| Interactive Chart Events (Drag / Drop & Buttons Engine)          |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
  {
   if(!ShouldRenderUI())
      return;

   const long chartId = ChartID();
   const string btnMinName = UI_PREFIX + "BtnMin";

   if(id == CHARTEVENT_CHART_CHANGE)
     {
      EnableDashboardChartEvents();
      EnsureDashboardPresent();
      RenderDashboardLayout();
      return;
     }

   if(id == CHARTEVENT_OBJECT_CLICK)
     {
      if(sparam == btnMinName)
        {
         ObjectSetInteger(chartId, btnMinName, OBJPROP_STATE, false);
         g_uiMinimized = !g_uiMinimized;
         RenderDashboardLayout();
         UpdateDashboard(true);
         ChartRedraw(chartId);
        }
      return;
     }

   if(id == CHARTEVENT_MOUSE_MOVE)
     {
      const int mouseX = (int)lparam;
      const int mouseY = (int)dparam;
      const int mouseState = (sparam == "" ? 0 : (int)StringToInteger(sparam));
      const bool leftButtonDown = ((mouseState & 1) == 1);

      if(leftButtonDown)
        {
         if(!g_isDragging)
           {
            if(IsPointInsideDashboardHeader(mouseX, mouseY) && !IsPointInsideMinButton(mouseX, mouseY))
              {
               g_isDragging = true;
               g_dragOffsetX = mouseX - g_uiX;
               g_dragOffsetY = mouseY - g_uiY;
               ChartSetInteger(chartId, CHART_MOUSE_SCROLL, false);
              }
           }
         else
           {
            g_uiX = mouseX - g_dragOffsetX;
            g_uiY = mouseY - g_dragOffsetY;
            if(g_uiX < 0) g_uiX = 0;
            if(g_uiY < 0) g_uiY = 0;
            RenderDashboardLayout();
           }
        }
      else if(g_isDragging)
        {
         g_isDragging = false;
         ChartSetInteger(chartId, CHART_MOUSE_SCROLL, true);
         ChartRedraw(chartId);
        }
     }
  }

void OnTimer()
  {
   if(!ShouldRenderUI())
      return;

   EnsureDashboardPresent();
   UpdateDashboard(true);
   MonitorServerTradeRecovery();
  }

//+------------------------------------------------------------------+
//| Tester helpers & trade error logging                             |
//+------------------------------------------------------------------+
bool IsStrategyTester() { return (bool)MQLInfoInteger(MQL_TESTER); }
bool ShouldRenderUI()   { return !IsStrategyTester(); }

bool IsMarketValidationMode()
  {
   // Active only while Strategy Tester still needs the Market validation
   // trades. After those complete, return false so long backtests run normally.
   return (IsStrategyTester() && !g_marketValidationCompleted);
  }

bool IsSymbolTradeSessionOpen()
  {
   const datetime now = TimeCurrent();
   MqlDateTime dt;
   TimeToStruct(now, dt);
   const datetime dayStart = now - (dt.hour * 3600 + dt.min * 60 + dt.sec);

   datetime sessFrom = 0;
   datetime sessTo = 0;
   for(uint i = 0; SymbolInfoSessionTrade(_Symbol, (ENUM_DAY_OF_WEEK)dt.day_of_week, i, sessFrom, sessTo); i++)
     {
      datetime fromTime = dayStart + sessFrom;
      datetime toTime   = dayStart + sessTo;
      if(sessTo < sessFrom)
         toTime += 86400;
      if(now >= fromTime && now < toTime)
         return true;
     }
   return false;
  }

bool ValidationMarketDealCheck(const ENUM_ORDER_TYPE orderType, const double lots)
  {
   MqlTradeRequest req = {};
   MqlTradeCheckResult res = {};
   req.action    = TRADE_ACTION_DEAL;
   req.symbol    = _Symbol;
   req.volume    = lots;
   req.type      = orderType;
   req.price     = (orderType == ORDER_TYPE_BUY)
                   ? SymbolInfoDouble(_Symbol, SYMBOL_ASK)
                   : SymbolInfoDouble(_Symbol, SYMBOL_BID);
   req.deviation = (ulong)TGM_BASE_DEVIATION_PTS;
   req.magic     = EXPERT_MAGIC;

   long filling = SymbolInfoInteger(_Symbol, SYMBOL_FILLING_MODE);
   if((filling & SYMBOL_FILLING_IOC) == SYMBOL_FILLING_IOC)
      req.type_filling = ORDER_FILLING_IOC;
   else if((filling & SYMBOL_FILLING_FOK) == SYMBOL_FILLING_FOK)
      req.type_filling = ORDER_FILLING_FOK;
   else
      req.type_filling = ORDER_FILLING_RETURN;

   if(!OrderCheck(req, res))
      return false;
   return (res.retcode == TRADE_RETCODE_DONE || res.retcode == 0);
  }

// Returns true when Market validation is finished (BUY+SELL done, or not needed).
// Returns false while still waiting for the next validation step/bar.
bool RunMarketValidationTradeOnce()
  {
   static int phase = 0;
   static datetime lastBarTime = 0;

   if(phase >= 2)
      return true;
   if(!IsStrategyTester())
      return true;

   const datetime barTime = iTime(_Symbol, PERIOD_CURRENT, 0);
   if(barTime == 0 || barTime == lastBarTime)
      return false;
   if(!IsSymbolTradeSessionOpen())
      return false;

   const double lots = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   if(lots <= 0.0)
      return false;

   g_trade.SetExpertMagicNumber(EXPERT_MAGIC);
   SetFillingMode();

   if(phase == 0)
     {
      if(!ValidationMarketDealCheck(ORDER_TYPE_BUY, lots))
         return false;
      if(g_trade.Buy(lots, _Symbol, 0, 0, 0, "TGM_MarketValidation"))
        {
         lastBarTime = barTime;
         phase = 1;
        }
      return false; // Need the SELL leg before validation is complete.
     }

   if(phase == 1)
     {
      if(!ValidationMarketDealCheck(ORDER_TYPE_SELL, lots))
         return false;
      if(g_trade.Sell(lots, _Symbol, 0, 0, 0, "TGM_MarketValidation"))
        {
         lastBarTime = barTime;
         phase = 2;
         return true; // BUY + SELL done — unlock main strategy.
        }
     }

   return false;
  }

bool IsGoldChartSymbol()
  {
   const string sym = _Symbol;
   if(sym == "XAUUSD" || sym == "XAUUSDm" || sym == "GOLD")
      return true;

   if(StringFind(sym, "XAUUSD") == 0)
      return true;

   string upper = sym;
   StringToUpper(upper);
   if(upper == "GOLD" || StringFind(upper, "XAUUSD") == 0)
      return true;

   return false;
  }

void LogTradeFailure(const string operation, const string context, const uint retcode, const string hint = "")
  {
   const datetime now = TimeCurrent();
   if(retcode == 10026 && (now - g_lastRetcode10026LogTime) < TGM_AUTOTRADE_COOLDOWN_SEC)
      return;
   if(retcode == 10026)
      g_lastRetcode10026LogTime = now;

   const string ctx = (context == "" ? "" : " | " + context);
   if(hint != "")
      PrintFormat("The Gold Mind | %s FAILED | retcode=%u (%s) | %s%s",
                  operation, retcode, g_trade.ResultRetcodeDescription(), hint, ctx);
   else
      PrintFormat("The Gold Mind | %s FAILED | retcode=%u (%s) | GetLastError=%d%s",
                  operation, retcode, g_trade.ResultRetcodeDescription(), GetLastError(), ctx);
   ResetLastError();
  }

string GetAutoTradeBlockReason()
  {
   if(IsStrategyTester())
      return "";

   if(IsServerTradePaused())
      return g_lastServerPauseReason;

   if(IsWeekendOrMarketClosed())
      return "Market closed (weekend / session)";

   if(TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) == 0)
      return "MT5 Algo Trading button is OFF (toolbar)";

   if(MQLInfoInteger(MQL_TRADE_ALLOWED) == 0)
      return "This chart EA: Properties > Common > Allow Algo Trading is OFF";

   if(AccountInfoInteger(ACCOUNT_TRADE_ALLOWED) == 0)
      return "Account trading is disabled";

   const long tradeMode = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_MODE);
   if(tradeMode == SYMBOL_TRADE_MODE_DISABLED)
      return StringFormat("%s trading is disabled", _Symbol);
   if(tradeMode == SYMBOL_TRADE_MODE_CLOSEONLY)
      return StringFormat("%s is close-only", _Symbol);

   return "";
  }

datetime SessionBoundaryForToday(const datetime sessionTime, const datetime now)
  {
   MqlDateTime nowDt, sessDt;
   TimeToStruct(now, nowDt);
   TimeToStruct(sessionTime, sessDt);
   nowDt.hour = sessDt.hour;
   nowDt.min  = sessDt.min;
   nowDt.sec  = sessDt.sec;
   return StructToTime(nowDt);
  }

bool IsSymbolTradeSessionOpenNow()
  {
   const datetime now = TimeTradeServer();
   MqlDateTime dt;
   TimeToStruct(now, dt);

   datetime from = 0, to = 0;
   for(uint session = 0; session < 32; session++)
     {
      if(!SymbolInfoSessionTrade(_Symbol, (ENUM_DAY_OF_WEEK)dt.day_of_week, session, from, to))
         break;

      datetime sessFrom = SessionBoundaryForToday(from, now);
      datetime sessTo   = SessionBoundaryForToday(to, now);
      if(sessTo < sessFrom)
         sessTo += 86400;

      if(now >= sessFrom && now <= sessTo)
         return true;
     }
   return false;
  }

bool IsWeekendOrMarketClosed()
  {
   if(IsStrategyTester())
      return false;

   return !IsSymbolTradeSessionOpenNow();
  }

bool IsDashboardMarketClosed()
  {
   if(IsStrategyTester())
      return false;

   if(!IsSymbolTradeSessionOpenNow())
      return true;

   // Broker session can still read "open" during daily breaks — confirm with live quotes.
   const datetime lastM1 = iTime(_Symbol, PERIOD_M1, 0);
   if(lastM1 <= 0)
      return true;

   const int maxQuotePauseSec = 1800; // 30 min without a new M1 bar
   return ((TimeTradeServer() - lastM1) > maxQuotePauseSec);
  }

string GetDashboardClosedStatusLabel()
  {
   MqlDateTime dt;
   TimeToStruct(TimeTradeServer(), dt);
   if(dt.day_of_week == 0 || dt.day_of_week == 6)
      return "WEEKEND";
   return "CLOSED";
  }

bool IsServerTradePaused()
  {
   return (!IsStrategyTester() && TimeCurrent() < g_serverTradePausedUntil);
  }

bool IsModifyTradeOperation(const string operation)
  {
   if(StringFind(operation, "PositionModify") >= 0)
      return true;
   if(StringFind(operation, "PositionClosePartial") >= 0)
      return true;
   if(StringFind(operation, "EmergencyParentSL") >= 0)
      return true;
   return false;
  }

bool IsProtectionTradeOperation(const string operation)
  {
   if(IsModifyTradeOperation(operation))
      return true;
   if(StringFind(operation, "Hedge") >= 0)
      return true;
   if(StringFind(operation, "EmergencyClose") >= 0)
      return true;
   return false;
  }

ulong ParseTicketFromTradeContext(const string context)
  {
   const int pos = StringFind(context, "ticket=");
   if(pos < 0)
      return 0;
   return (ulong)StringToInteger(StringSubstr(context, pos + 7));
  }

bool IsNearSessionBreak(const int warningSec = 300)
  {
   if(IsStrategyTester())
      return false;

   datetime sessFrom = 0, sessTo = 0;
   bool sessionOpen = false;
   if(!GetTradeSessionWindow(sessFrom, sessTo, sessionOpen) || !sessionOpen)
      return false;

   const datetime now = TimeTradeServer();
   return (sessTo > now && (sessTo - now) <= warningSec);
  }

void RegisterServerTradePause(const uint retcode, const string operation)
  {
   if(retcode != TGM_RETCODE_MARKET_CLOSED &&
      retcode != TGM_RETCODE_FROZEN &&
      retcode != 10017 &&
      retcode != 10019 &&
      retcode != 10026)
      return;

   if(IsProtectionTradeOperation(operation) &&
      (retcode == TGM_RETCODE_FROZEN || retcode == TGM_RETCODE_MARKET_CLOSED))
     {
      g_modifyPausedUntil = TimeCurrent() + TGM_MODIFY_RETRY_SEC;
      const datetime now = TimeCurrent();
      if((now - g_lastServerPauseLogTime) >= TGM_TRADE_WARN_INTERVAL_SEC)
        {
         g_lastServerPauseLogTime = now;
         PrintFormat("The Gold Mind: Protection retry in %d sec (%s | retcode %u).",
                     TGM_MODIFY_RETRY_SEC, operation, retcode);
        }
      return;
     }

   g_serverTradePausedUntil = TimeCurrent() + TGM_SERVER_PAUSE_SEC;

   if(retcode == TGM_RETCODE_MARKET_CLOSED)
      g_lastServerPauseReason = "Market closed - broker rejected trade (retcode 10018)";
   else if(retcode == TGM_RETCODE_FROZEN)
      g_lastServerPauseReason = "Market frozen - broker rejected modify/order (retcode 10029)";
   else if(retcode == 10017)
      g_lastServerPauseReason = "Trading disabled by broker (retcode 10017)";
   else if(retcode == 10026)
      g_lastServerPauseReason = "Auto-trading disabled by server (retcode 10026)";
   else
      g_lastServerPauseReason = StringFormat("Broker rejected %s (retcode %u)", operation, retcode);

   const datetime now = TimeCurrent();
   if((now - g_lastServerPauseLogTime) >= TGM_TRADE_WARN_INTERVAL_SEC)
     {
      g_lastServerPauseLogTime = now;
      PrintFormat("The Gold Mind: Trade ops paused for %d min - %s", TGM_SERVER_PAUSE_SEC / 60, g_lastServerPauseReason);
     }
  }

void MonitorServerTradeRecovery()
  {
   if(IsStrategyTester() || g_serverTradePausedUntil == 0)
      return;

   if(TimeCurrent() >= g_serverTradePausedUntil && !IsWeekendOrMarketClosed())
     {
      g_serverTradePausedUntil = 0;
      g_lastServerPauseReason = "";
      Print("The Gold Mind: Broker session available again - grid/trade ops resumed.");
     }

   if(g_modifyPausedUntil > 0 && TimeCurrent() >= g_modifyPausedUntil)
      g_modifyPausedUntil = 0;
  }

bool IsPositionMgmtAllowed()
  {
   if(IsStrategyTester())
      return true;

   if(IsWeekendOrMarketClosed())
      return false;

   if(TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) == 0)
      return false;

   if(MQLInfoInteger(MQL_TRADE_ALLOWED) == 0)
      return false;

   if(AccountInfoInteger(ACCOUNT_TRADE_ALLOWED) == 0)
      return false;

   const long tradeMode = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_MODE);
   if(tradeMode == SYMBOL_TRADE_MODE_DISABLED || tradeMode == SYMBOL_TRADE_MODE_CLOSEONLY)
      return false;

   return true;
  }

bool IsGridOpsAllowed()
  {
   if(IsKillSwitchActiveToday())
      return false;
   if(!IsPositionMgmtAllowed())
      return false;
   if(IsServerTradePaused())
      return false;
   return true;
  }

bool IsTradeOpsAllowed()
  {
   return IsGridOpsAllowed();
  }

bool IsTradeModifyCooldownActive()
  {
   return (!IsStrategyTester() && TimeCurrent() < g_autotradeCooldownUntil);
  }

void WarnAutoTradeBlocked(const string operation)
  {
   const string reason = GetAutoTradeBlockReason();
   if(reason == "")
      return;

   const datetime now = TimeCurrent();
   if((now - g_lastTradeBlockWarnTime) < TGM_TRADE_WARN_INTERVAL_SEC)
      return;

   g_lastTradeBlockWarnTime = now;
   PrintFormat("The Gold Mind: Trade ops skipped (%s) - %s", operation, reason);
  }

bool PreTradeGuard(const string operation)
  {
   if(IsPositionMgmtAllowed())
      return true;
   WarnAutoTradeBlocked(operation);
   return false;
  }

bool PreProtectionTradeGuard(const string operation)
  {
   if(IsStrategyTester())
      return true;

   if(TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) == 0)
     {
      WarnAutoTradeBlocked(operation);
      return false;
     }

   if(MQLInfoInteger(MQL_TRADE_ALLOWED) == 0)
     {
      WarnAutoTradeBlocked(operation);
      return false;
     }

   if(AccountInfoInteger(ACCOUNT_TRADE_ALLOWED) == 0)
     {
      WarnAutoTradeBlocked(operation);
      return false;
     }

   const long tradeMode = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_MODE);
   if(tradeMode == SYMBOL_TRADE_MODE_DISABLED || tradeMode == SYMBOL_TRADE_MODE_CLOSEONLY)
     {
      WarnAutoTradeBlocked(operation);
      return false;
     }

   return true;
  }

bool HasOpenBotPositions()
  {
   CPositionInfo pos;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(!pos.SelectByIndex(i))
         continue;
      if(pos.Symbol() != _Symbol || pos.Magic() != (ulong)EXPERT_MAGIC)
         continue;
      return true;
     }
   return false;
  }

void ShowAutoTradeSetupWarningIfNeeded()
  {
   if(IsPositionMgmtAllowed())
     {
      g_autotradeBoxShown = false;
      return;
     }

   if(g_autotradeBoxShown)
      return;

   g_autotradeBoxShown = true;
   MessageBox("Auto-trading is NOT enabled.\n\n" + GetAutoTradeBlockReason(),
              "The Gold Mind - Setup Required",
              (int)(MB_OK | MB_ICONWARNING));
  }

bool IsSLAlreadyAtTarget(const double liveSL, const double targetSL, const double point)
  {
   if(liveSL <= 0.0)
      return false;
   return (MathAbs(liveSL - targetSL) <= point);
  }

bool ExecuteTradeOp(const string operation, const bool success, const string context = "")
  {
   if(!success)
     {
      const uint retcode = g_trade.ResultRetcode();
      RegisterServerTradePause(retcode, operation);

      if(StringFind(operation, "BE-") >= 0)
        {
         const ulong ticket = ParseTicketFromTradeContext(context);
         if(ticket > 0)
            MarkBreakEvenPending(ticket);
        }

      if(retcode == 10026)
        {
         g_autotradeCooldownUntil = TimeCurrent() + TGM_AUTOTRADE_COOLDOWN_SEC;
         LogTradeFailure(operation, context, retcode,
                         "Auto-trading disabled - enable Algo Trading on toolbar and EA properties.");
        }
      else if(retcode == TGM_RETCODE_MARKET_CLOSED)
        {
         if((TimeCurrent() - g_lastServerPauseLogTime) >= TGM_TRADE_WARN_INTERVAL_SEC)
            PrintFormat("The Gold Mind | %s blocked | retcode=10018 (market closed) | %s",
                        operation, context);
        }
      else
         LogTradeFailure(operation, context, retcode);
     }
   return success;
  }

//--- Never send PositionModify with ticket 0 / closed / wrong-side SL-TP (fixes journal #0 errors).
bool SafePositionModify(const ulong ticket, const double sl, const double tp, const string operation)
  {
   if(ticket == 0)
     {
      PrintFormat("TGM [SAFE]: %s blocked — ticket #0 (invalid).", operation);
      return false;
     }

   CPositionInfo pos;
   if(!pos.SelectByTicket(ticket))
      return false;
   if(pos.Symbol() != _Symbol || pos.Magic() != (ulong)EXPERT_MAGIC)
      return false;

   const int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   const double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   const double nSL = (sl > 0.0) ? NormalizeDouble(sl, digits) : 0.0;
   const double nTP = (tp > 0.0) ? NormalizeDouble(tp, digits) : 0.0;

   // No-op modify → broker still returns invalid stops if live SL is already wrong-side.
   const double liveSL = pos.StopLoss();
   const double liveTP = pos.TakeProfit();
   if(MathAbs(liveSL - nSL) <= point && MathAbs(liveTP - nTP) <= point)
      return true;

   const double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   const double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   // Hard reject wrong-side SL (HedgeBE spam: BUY SL above bid → retcode 10016).
   if(nSL > 0.0)
     {
      if(pos.PositionType() == POSITION_TYPE_BUY && nSL >= bid - 1e-12)
        {
         // silent — caller retries every tick otherwise floods Journal
         return false;
        }
      if(pos.PositionType() == POSITION_TYPE_SELL && nSL <= ask + 1e-12)
         return false;
      if(!IsBrokerStopDistanceOK(pos.PositionType(),
                                 (pos.PositionType() == POSITION_TYPE_BUY) ? bid : ask,
                                 nSL))
         return false;
     }

   // Reject inverted SL/TP which brokers refuse (seen as Invalid parameters).
   if(nSL > 0.0 && nTP > 0.0)
     {
      if(pos.PositionType() == POSITION_TYPE_BUY && nSL >= nTP)
        {
         PrintFormat("TGM [SAFE]: %s blocked #%I64u — BUY SL>=TP (sl=%.*f tp=%.*f).",
                     operation, ticket, digits, nSL, digits, nTP);
         return false;
        }
      if(pos.PositionType() == POSITION_TYPE_SELL && nSL <= nTP)
        {
         PrintFormat("TGM [SAFE]: %s blocked #%I64u — SELL SL<=TP (sl=%.*f tp=%.*f).",
                     operation, ticket, digits, nSL, digits, nTP);
         return false;
        }
     }

   return ExecuteTradeOp(operation, g_trade.PositionModify(ticket, nSL, nTP),
                         StringFormat("ticket=%I64u sl=%.*f tp=%.*f", ticket, digits, nSL, digits, nTP));
  }

//--- Parent broker SL: R391 keeps NO fixed SL (hedge owns loss control).
bool EnsureParentHasBrokerSL(const ulong ticket)
  {
#ifdef TGM_NO_FIXED_BROKER_SL
   return true; // intentionally naked of fixed SL
#else
   if(!IsOurBotGridParent(ticket))
      return false;

   CPositionInfo pos;
   if(!pos.SelectByTicket(ticket))
      return false;
   if(pos.StopLoss() > 0.0)
      return true; // already protected by broker SL

   const int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   const double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   if(point <= 0.0)
      return false;

   double slDist = GetConfiguredStopDistance();
   if(slDist <= 0.0)
      slDist = StrategyPointsToPriceDistance(Emergency_Parent_SL_Points);

   const double stops = GetSymbolStopsPrice();
   const double open = pos.PriceOpen();
   const double liveTP = pos.TakeProfit();
   double targetSL = 0.0;

   if(pos.PositionType() == POSITION_TYPE_BUY)
     {
      targetSL = NormalizeDouble(open - slDist, digits);
      const double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      const double maxValid = NormalizeDouble(bid - stops - point, digits);
      if(targetSL > maxValid)
         targetSL = maxValid;
      if(targetSL >= bid)
         return false;
     }
   else
     {
      targetSL = NormalizeDouble(open + slDist, digits);
      const double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      const double minValid = NormalizeDouble(ask + stops + point, digits);
      if(targetSL < minValid)
         targetSL = minValid;
      if(targetSL <= ask)
         return false;
     }

   if(!SafePositionModify(ticket, targetSL, liveTP, "ParentSLRestore"))
      return false;

   PrintFormat("TGM [SL-RESTORE]: Parent #%I64u had NO SL — restored %.*f (dist≈$%.2f).",
               ticket, digits, targetSL, slDist);
   return true;
#endif
  }

//--- LOSS CAP: once 1:1 hedge is live, tighten parent broker SL to InpLossCapUSD from open.
//    This is what stops ATR-sized account blowups. Profit-side trail/BE untouched.
bool ApplyParentHardLossCap(const ulong parentTicket)
  {
   if(!IsLossCapEngineActive() || !Enable_ParentHardCapSL)
      return false;
   if(InpLossCapUSD <= 0.0)
      return false;
   if(!IsOurBotGridParent(parentTicket))
      return false;
   if(!HasFullHedgeCoverage(parentTicket))
      return false;

   CPositionInfo pos;
   if(!pos.SelectByTicket(parentTicket))
      return false;

   const int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   const double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   if(point <= 0.0)
      return false;

   const double open = pos.PriceOpen();
   const double stops = GetSymbolStopsPrice();
   const double liveTP = pos.TakeProfit();
   const double liveSL = pos.StopLoss();
   double targetSL = 0.0;

   if(pos.PositionType() == POSITION_TYPE_BUY)
     {
      targetSL = NormalizeDouble(open - InpLossCapUSD, digits);
      const double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      const double maxValid = NormalizeDouble(bid - stops - point, digits);
      if(targetSL > maxValid)
         targetSL = maxValid;
      // Already tighter or equal → done
      if(liveSL > 0.0 && liveSL + point >= targetSL)
         return true;
      if(targetSL >= bid)
         return false;
     }
   else
     {
      targetSL = NormalizeDouble(open + InpLossCapUSD, digits);
      const double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      const double minValid = NormalizeDouble(ask + stops + point, digits);
      if(targetSL < minValid)
         targetSL = minValid;
      if(liveSL > 0.0 && liveSL - point <= targetSL)
         return true;
      if(targetSL <= ask)
         return false;
     }

   if(!SafePositionModify(parentTicket, targetSL, liveTP, "ParentHardLossCap"))
      return false;

   PrintFormat("TGM [LOSS-CAP]: Parent #%I64u SL capped at %.*f (max adverse ≈ $%.2f) | 1:1 hedge locked.",
               parentTicket, digits, targetSL, InpLossCapUSD);
   return true;
  }

//--- Close sticky hedge only when parent is actually in profit (profit method owns it).
bool TryReleaseStickyHedge(const ulong parentTicket)
  {
   if(!IsHedgeEngineActive())
      return false;

   if(GetPositionProfitPips(parentTicket) <= 0.0)
      return false;

   CancelHedgeProtectStopsForParent(parentTicket, "ParentRecovered");

   if(!HasHedge(parentTicket))
      return false;

   ulong hedges[];
   const int n = CollectHedgesForParent(parentTicket, hedges);
   bool any = false;
   for(int i = 0; i < n; i++)
     {
      if(CloseHedgePosition(hedges[i], "ParentRecovered"))
         any = true;
     }
   if(any)
      PrintFormat("TGM [HEDGE]: Parent #%I64u in profit — hedge released.", parentTicket);
   return any;
  }

void InitBrokerPointModifier()
  {
   const int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   point_modifier = (digits == 3 || digits == 5) ? 10.0 : 1.0;
  }

double StrategyPointsToBrokerPoints(const double strategyPoints)
  {
   return strategyPoints * point_modifier;
  }

double StrategyPointsToPriceDistance(const double strategyPoints)
  {
   const double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   if(point <= 0.0) return 0.0;
   return StrategyPointsToBrokerPoints(strategyPoints) * point;
  }

double PriceMoveToBrokerPoints(const double priceMove, const double point)
  {
   if(point <= 0.0) return 0.0;
   return priceMove / point;
  }

//+------------------------------------------------------------------+
//| Core mechanics                                                   |
//+------------------------------------------------------------------+
void ShowManualLotWarning()
  {
   MessageBox("WARNING: Manual Lot Size Active.", "The Gold Mind", (int)(MB_OK | MB_ICONWARNING));
  }

void SetFillingMode()
  {
   ENUM_ORDER_TYPE_FILLING fill = ORDER_FILLING_FOK;
   long filling = SymbolInfoInteger(_Symbol, SYMBOL_FILLING_MODE);
   if((filling & SYMBOL_FILLING_IOC) == SYMBOL_FILLING_IOC) fill = ORDER_FILLING_IOC;
   else if((filling & SYMBOL_FILLING_FOK) == SYMBOL_FILLING_FOK) fill = ORDER_FILLING_FOK;
   else fill = ORDER_FILLING_RETURN;
   g_trade.SetTypeFilling(fill);
  }

int CountPendingOrders()
  {
   int count = 0;
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      const ulong ticket = OrderGetTicket(i);
      if(ticket > 0 && IsBotGridPendingOrder(ticket))
         count++;
     }
   return count;
  }

bool IsBotGridPendingOrder(const ulong orderTicket)
  {
   if(orderTicket == 0 || !OrderSelect(orderTicket))
      return false;
   if(OrderGetString(ORDER_SYMBOL) != _Symbol)
      return false;
   if((long)OrderGetInteger(ORDER_MAGIC) != EXPERT_MAGIC)
      return false;
   if(!IsPendingOrderType((ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE)))
      return false;

   const string comment = OrderGetString(ORDER_COMMENT);
   return IsGridPositionComment(comment);
  }

int CountGridOpenPositions()
  {
   CPositionInfo pos;
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(!pos.SelectByIndex(i))
         continue;
      if(pos.Symbol() != _Symbol || pos.Magic() != (ulong)EXPERT_MAGIC)
         continue;
      if(!WasOpenedAsGridLimit(pos.Ticket()))
         continue;
      count++;
     }
   return count;
  }

int CountBotOpenPositions()
  {
   CPositionInfo pos; int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
      if(pos.SelectByIndex(i) && pos.Symbol() == _Symbol && pos.Magic() == (ulong)EXPERT_MAGIC) count++;
   return count;
  }

bool IsPendingOrderType(const ENUM_ORDER_TYPE type)
  {
   return (type == ORDER_TYPE_BUY_LIMIT || type == ORDER_TYPE_SELL_LIMIT || type == ORDER_TYPE_BUY_STOP || type == ORDER_TYPE_SELL_STOP);
  }

string GridH4BarStateKey() { return StringFormat("TGM_GridH4_%s_%u_%I64d", _Symbol, EXPERT_MAGIC, AccountInfoInteger(ACCOUNT_LOGIN)); }
datetime GetCurrentH4BarOpenTime() { return iTime(_Symbol, PERIOD_H4, 0); }
datetime LoadGridH4BarTime() { string key = GridH4BarStateKey(); return GlobalVariableCheck(key) ? (datetime)GlobalVariableGet(key) : 0; }
string GridLevelStateKey(const string comment) { return StringFormat("TGM_GridState_%I64u_%s_%s", (ulong)AccountInfoInteger(ACCOUNT_LOGIN), _Symbol, comment); }
string GridLevelTicketKey(const string comment) { return StringFormat("TGM_GridTicket_%I64u_%s_%s", (ulong)AccountInfoInteger(ACCOUNT_LOGIN), _Symbol, comment); }
double GetGridLevelState(const string comment) { return GlobalVariableCheck(GridLevelStateKey(comment)) ? GlobalVariableGet(GridLevelStateKey(comment)) : TGM_GRID_LEVEL_IDLE; }
ulong GetGridLevelTicket(const string comment) { return GlobalVariableCheck(GridLevelTicketKey(comment)) ? (ulong)GlobalVariableGet(GridLevelTicketKey(comment)) : 0; }
void ClearGridLevelState(const string comment)
  {
   const string stateKey = GridLevelStateKey(comment);
   const string ticketKey = GridLevelTicketKey(comment);
   if(GlobalVariableCheck(stateKey)) GlobalVariableDel(stateKey);
   if(GlobalVariableCheck(ticketKey)) GlobalVariableDel(ticketKey);
  }
void SetGridLevelState(const string comment, const double state, const ulong ticket = 0)
  {
   GlobalVariableSet(GridLevelStateKey(comment), state);
   if(ticket > 0)
      GlobalVariableSet(GridLevelTicketKey(comment), (double)ticket);
   else
     {
      const string ticketKey = GridLevelTicketKey(comment);
      if(GlobalVariableCheck(ticketKey))
         GlobalVariableDel(ticketKey);
     }
  }
void ResetAllGridLevelStates()
  {
   string comments[6] = {"GM_BL1","GM_BL2","GM_BL3","GM_SL1","GM_SL2","GM_SL3"};
   for(int i = 0; i < 6; i++)
      ClearGridLevelState(comments[i]);
   ClearAllLevelBELocksThisH4();
   ClearAllLevelActivationCountsThisH4();
  }

bool IsFixedSlReentryMode()
  {
   return false; // R391: no fixed broker SL
  }

bool IsLossCapHedgeMode()
  {
   return false; // R416: no hedge loss-control
  }

bool IsHedgeEngineActive()
  {
   return Enable_Hedge_Protection; // R391: hedge at -30pip loss
  }

bool IsLossCapEngineActive()
  {
   return false; // hard $ loss-cap SL stays OFF (no fixed SL)
  }

//--- Live ATR-14 H4 value (price units).
bool GetLiveAtrSl(double &atrOut)
  {
   atrOut = 0.0;
   if(g_atrSlHandle == INVALID_HANDLE)
      return false;
   double buf[];
   ArraySetAsSeries(buf, true);
   if(CopyBuffer(g_atrSlHandle, 0, 1, 1, buf) < 1)
     {
      Print("The Gold Mind: CopyBuffer(iATR SL-14) failed. GetLastError=", GetLastError());
      return false;
     }
   atrOut = buf[0];
   return (atrOut > 0.0);
  }

//--- Live ATR-14 H4 SL distance (price). Fallback: fixed InpFixedStopLossUSD.
double GetLiveAtrStopDistance()
  {
   double atr = 0.0;
   if(GetLiveAtrSl(atr) && atr > 0.0 && SL_ATR_Multiplier > 0.0)
      return atr * SL_ATR_Multiplier;
   if(GetLiveATR(atr) && atr > 0.0 && SL_ATR_Multiplier > 0.0)
      return atr * SL_ATR_Multiplier;
   return (InpFixedStopLossUSD > 0.0) ? InpFixedStopLossUSD : 3.0;
  }

//--- Risk distance for lot sizing (30pip). Broker SL is NOT attached in R391.
double GetConfiguredStopDistance()
  {
   const double pip = Phase17_GetPipSize();
   if(pip > 0.0)
      return TGM_RISK_DIST_PIPS * pip;
   return (InpFixedStopLossUSD > 0.0) ? InpFixedStopLossUSD : 3.0;
  }

//--- Shared SL for side: last grid level +/-50pip (buy3 / sell3).
bool GetSharedGridSideStopLoss(const ENUM_POSITION_TYPE side, double &slOut)
  {
   slOut = 0.0;
   double high1, low1, pivot, buy1, buy2, buy3, sell1, sell2, sell3;
   if(!CalculateH4GridLevels(high1, low1, pivot, buy1, buy2, buy3, sell1, sell2, sell3))
      return false;
   const double pip = Phase17_GetPipSize();
   if(pip <= 0.0)
      return false;
   const int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   if(side == POSITION_TYPE_BUY)
      slOut = NormalizeDouble(buy3 - (TGM_SHARED_SL_BEYOND_LAST_PIPS * pip), digits);
   else
      slOut = NormalizeDouble(sell3 + (TGM_SHARED_SL_BEYOND_LAST_PIPS * pip), digits);
   return (slOut > 0.0);
  }

bool GetFixedStopLossForParent(const ulong ticket, double &slOut)
  {
   slOut = 0.0;
   return false; // R391: no fixed broker SL
  }

//--- Mode B: SL distance for lot/heal math.
double GetActiveHedgeTriggerUSD()
  {
   // Price-distance trigger ≈ 30 pip (GetPositionLossUSD uses price units).
   const double pip = Phase17_GetPipSize();
   if(pip > 0.0)
      return TGM_LOSS_HEDGE_PIPS * pip;
   return (InpHedgeTriggerUSD > 0.0) ? InpHedgeTriggerUSD : 3.0;
  }

double GetActiveHedgeBreakEvenUSD()
  {
   return (InpHedgeBreakEvenUSD > 0.0) ? InpHedgeBreakEvenUSD : 1.0;
  }

//--- R392: never restore a fixed broker SL (loss control = hedge cycle + hedge BE).
bool EnsureModeBFixedBrokerSL(const ulong parentTicket)
  {
   return true;
  }

//--- Never leave GM_HEDGE leftovers open (legacy Mode A spam cleanup).
void CloseStrayHedgesInFixedSlMode()
  {
   CPositionInfo pos;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(!pos.SelectByIndex(i))
         continue;
      if(pos.Symbol() != _Symbol || pos.Magic() != (ulong)EXPERT_MAGIC)
         continue;
      if(!IsBotHedgePosition(pos.Ticket(), pos.Comment()))
         continue;
      CloseHedgePosition(pos.Ticket(), "ModeBNoHedge");
     }
  }

string ResolveGridLevelNameFromComment(const string comment)
  {
   if(comment == "")
      return "";
   string names[6] = {"GM_BL1","GM_BL2","GM_BL3","GM_SL1","GM_SL2","GM_SL3"};
   for(int i = 0; i < 6; i++)
     {
      if(StringFind(comment, names[i]) >= 0)
         return names[i];
     }
   return "";
  }

int MaxLevelActivationsThisH4()
  {
   // R382: each level activates once per H4 — SL or TP ends the level (no re-arm).
   return TGM_MAX_LEVEL_ACTS_H4_HARD;
  }

bool LevelHasLivePositionThisH4(const string comment)
  {
   const datetime h4 = GetCurrentH4BarOpenTime();
   if(h4 <= 0)
      return false;
   return (FindGridPositionTicketByCommentThisH4(comment, h4) > 0);
  }

int CancelPendingOrdersForLevel(const string comment)
  {
   int n = 0;
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      const ulong ticket = OrderGetTicket(i);
      if(ticket == 0 || !OrderSelect(ticket))
         continue;
      if(OrderGetString(ORDER_SYMBOL) != _Symbol)
         continue;
      if((long)OrderGetInteger(ORDER_MAGIC) != EXPERT_MAGIC)
         continue;
      if(!PendingCommentMatchesLevel(OrderGetString(ORDER_COMMENT), comment))
         continue;
      if(ExecuteTradeOp("OrderDelete", g_trade.OrderDelete(ticket),
                        StringFormat("2nd-SL cancel %s ticket=%I64u", comment, ticket)))
         n++;
     }
   if(n > 0)
      ClearGridLevelState(comment);
   return n;
  }

string ResolveGridLevelFromClosedDeal(const ulong dealTicket, const string dealComment)
  {
   string level = ResolveGridLevelNameFromComment(dealComment);
   if(level != "")
      return level;

   const ulong closeOrder = (ulong)HistoryDealGetInteger(dealTicket, DEAL_ORDER);
   if(closeOrder > 0 && HistoryOrderSelect(closeOrder))
     {
      level = ResolveGridLevelNameFromComment(HistoryOrderGetString(closeOrder, ORDER_COMMENT));
      if(level != "")
         return level;
     }

   const ulong posId = (ulong)HistoryDealGetInteger(dealTicket, DEAL_POSITION_ID);
   if(posId == 0 || !HistorySelectByPosition((long)posId))
      return "";

   const int n = HistoryDealsTotal();
   for(int d = 0; d < n; d++)
     {
      const ulong t = HistoryDealGetTicket(d);
      if(t == 0)
         continue;
      const long entry = HistoryDealGetInteger(t, DEAL_ENTRY);
      if(entry != DEAL_ENTRY_IN && entry != DEAL_ENTRY_INOUT)
         continue;
      level = ResolveGridLevelNameFromComment(HistoryDealGetString(t, DEAL_COMMENT));
      if(level != "")
         break;
      const ulong inOrder = (ulong)HistoryDealGetInteger(t, DEAL_ORDER);
      if(inOrder > 0 && HistoryOrderSelect(inOrder))
        {
         level = ResolveGridLevelNameFromComment(HistoryOrderGetString(inOrder, ORDER_COMMENT));
         if(level != "")
            break;
        }
     }

   HistorySelect(0, TimeCurrent());
   HistoryDealSelect(dealTicket);
   return level;
  }

void LogPriceThroughOnce(const string comment, const string reason)
  {
   static string logged[6];
   static datetime loggedH4 = 0;
   const datetime h4 = GetCurrentH4BarOpenTime();
   string names[6] = {"GM_BL1","GM_BL2","GM_BL3","GM_SL1","GM_SL2","GM_SL3"};
   int idx = -1;
   for(int i = 0; i < 6; i++)
      if(names[i] == comment) { idx = i; break; }
   if(idx < 0)
      return;
   if(loggedH4 != h4)
     {
      for(int j = 0; j < 6; j++)
         logged[j] = "";
      loggedH4 = h4;
     }
   if(logged[idx] == "PRICE_THROUGH")
      return;
   logged[idx] = "PRICE_THROUGH";
   PrintFormat("TGM [P28-EXEC]: PRICE_THROUGH | %s | %s | acts=%d | h4=%s",
               comment, reason, GetLevelActivationCountThisH4(comment),
               TimeToString(h4, TIME_DATE|TIME_MINUTES));
  }

//--- Mode B: profit full-exit locks level; 2nd SL/loss also ends level; 1st SL allows one re-entry.
void ProcessModeBLevelExitFromDeal(const ulong dealTicket)
  {
   if(!IsFixedSlReentryMode() || dealTicket == 0)
      return;

   if(!HistoryDealSelect(dealTicket))
     {
      HistorySelect(0, TimeCurrent());
      if(!HistoryDealSelect(dealTicket))
         return;
     }
   if(HistoryDealGetString(dealTicket, DEAL_SYMBOL) != _Symbol)
      return;
   const long magic = HistoryDealGetInteger(dealTicket, DEAL_MAGIC);
   if(magic != 0 && magic != EXPERT_MAGIC)
      return;

   const long entry = HistoryDealGetInteger(dealTicket, DEAL_ENTRY);
   if(entry != DEAL_ENTRY_OUT && entry != DEAL_ENTRY_OUT_BY)
      return;

   string dealComment = HistoryDealGetString(dealTicket, DEAL_COMMENT);
   if(IsHedgePositionComment(dealComment))
      return;

   string level = ResolveGridLevelFromClosedDeal(dealTicket, dealComment);
   if(!HistoryDealSelect(dealTicket))
     {
      HistorySelect(0, TimeCurrent());
      HistoryDealSelect(dealTicket);
     }
   if(level == "")
      return;

   ENUM_POSITION_TYPE closedSide = (ENUM_POSITION_TYPE)-1;
   const bool hasClosedSide = ResolveGridLevelSide(level, closedSide);

   static ulong seen[32];
   static int seenN = 0;
   for(int s = 0; s < seenN && s < 32; s++)
      if(seen[s] == dealTicket)
         return;
   if(seenN < 32)
      seen[seenN++] = dealTicket;
   else
      seen[dealTicket % 32] = dealTicket;

   // Partial still open: remaining volume larger than this OUT deal.
   const datetime h4 = GetCurrentH4BarOpenTime();
   const ulong liveTicket = (h4 > 0) ? FindGridPositionTicketByCommentThisH4(level, h4) : 0;
   if(liveTicket > 0 && PositionSelectByTicket(liveTicket))
     {
      const double posVol = PositionGetDouble(POSITION_VOLUME);
      const double dealVol = HistoryDealGetDouble(dealTicket, DEAL_VOLUME);
      if(posVol > dealVol + 1e-8)
         return;
     }

   const ulong posId = (ulong)HistoryDealGetInteger(dealTicket, DEAL_POSITION_ID);
   const datetime dealTime = (datetime)HistoryDealGetInteger(dealTicket, DEAL_TIME);
   const double net = HistoryDealGetDouble(dealTicket, DEAL_PROFIT)
                    + HistoryDealGetDouble(dealTicket, DEAL_SWAP)
                    + HistoryDealGetDouble(dealTicket, DEAL_COMMISSION);

   // Profit path: BE/partial was armed OR final deal is profit → lock level (no more re-entry this H4).
   if(net > 0.0 || (posId > 0 && IsProfitEngineArmed(posId)))
     {
      if(IsPartialClosedBeRunner(posId) || IsProfitEngineArmed(posId))
         LogPhase28A("RUNNER_SL_CLOSE", posId,
                     StringFormat("level=%s net=%.2f deal_comment=%s", level, net, dealComment));
      if(hasClosedSide)
         ResetDirectionalLossCountToday(closedSide, dealTime);
      MarkLevelBELockedThisH4(level);
      PrintFormat("TGM [MODE-B]: Level %s profit-exit lock (deal net $%.2f).", level, net);
      return;
     }

   // Loss path — do NOT cancel sibling pendings (R380: independent 3+3 levels).
   if(hasClosedSide)
      RecordDirectionalLossAndMaybePause(closedSide, dealTime, level, net);

   const int acts = GetLevelActivationCountThisH4(level);
   const int maxActs = MaxLevelActivationsThisH4();
   if(acts >= maxActs)
     {
      MarkLevelActivationExhaustedThisH4(level);
      const int cancelled = CancelPendingOrdersForLevel(level);
      PrintFormat("TGM [P28-EXEC]: LEVEL_SL_LOCK | %s | acts=%d/%d | PENDING_CANCELLED=%d | NO_MORE_REARM",
                  level, acts, maxActs, cancelled);
      return;
     }

   // First SL: clear slot so same-H4 OnTick refill can place this level again (2nd activation).
   if(!LevelHasLivePositionThisH4(level))
      ClearGridLevelState(level);
   PrintFormat("TGM [R380]: FIRST_SL | %s | acts=%d/%d | RE-ARM allowed this H4 | deal=%s",
               level, acts, maxActs, dealComment);
   LogPhase28A("FIRST_SL_REARM", posId,
               StringFormat("%s acts=%d/%d", level, acts, maxActs));
  }

bool ResolveGridLevelSide(const string level, ENUM_POSITION_TYPE &sideOut)
  {
   if(StringFind(level, "GM_BL") == 0)
     {
      sideOut = POSITION_TYPE_BUY;
      return true;
     }
   if(StringFind(level, "GM_SL") == 0)
     {
      sideOut = POSITION_TYPE_SELL;
      return true;
     }
   return false;
  }

datetime GetTradeDayStart(const datetime when)
  {
   MqlDateTime dt;
   TimeToStruct(when, dt);
   dt.hour = 0;
   dt.min = 0;
   dt.sec = 0;
   return StructToTime(dt);
  }

datetime GetNextTradeDayStart(const datetime when)
  {
   return (GetTradeDayStart(when) + 24 * 60 * 60);
  }

string DirectionalLossCountKey(const ENUM_POSITION_TYPE side, const datetime when)
  {
   return StringFormat("TGM_SideLoss_%I64u_%s_%s_%I64d",
                       (ulong)AccountInfoInteger(ACCOUNT_LOGIN),
                       _Symbol,
                       (side == POSITION_TYPE_BUY) ? "BUY" : "SELL",
                       (long)GetTradeDayStart(when));
  }

string DirectionalPauseKey(const ENUM_POSITION_TYPE side)
  {
   return StringFormat("TGM_SidePause_%I64u_%s_%s",
                       (ulong)AccountInfoInteger(ACCOUNT_LOGIN),
                       _Symbol,
                       (side == POSITION_TYPE_BUY) ? "BUY" : "SELL");
  }

string ExtremeH4ShockUntilKey()
  {
   return StringFormat("TGM_ShockUntil_%I64u_%s",
                       (ulong)AccountInfoInteger(ACCOUNT_LOGIN),
                       _Symbol);
  }

string ExtremeH4ShockBarKey()
  {
   return StringFormat("TGM_ShockBar_%I64u_%s",
                       (ulong)AccountInfoInteger(ACCOUNT_LOGIN),
                       _Symbol);
  }

int GetDirectionalLossCountToday(const ENUM_POSITION_TYPE side, const datetime when)
  {
   const string key = DirectionalLossCountKey(side, when);
   return GlobalVariableCheck(key) ? (int)GlobalVariableGet(key) : 0;
  }

void ResetDirectionalLossCountToday(const ENUM_POSITION_TYPE side, const datetime when)
  {
   const string key = DirectionalLossCountKey(side, when);
   if(GlobalVariableCheck(key))
      GlobalVariableDel(key);
  }

void RecordDirectionalLossAndMaybePause(const ENUM_POSITION_TYPE side, const datetime eventTime, const string level, const double net)
  {
   const string key = DirectionalLossCountKey(side, eventTime);
   const int streak = GetDirectionalLossCountToday(side, eventTime) + 1;
   GlobalVariableSet(key, (double)streak);
   if(streak < TGM_SIDE_LOSS_STREAK_LIMIT)
      return;

   const datetime pauseUntil = GetNextTradeDayStart(eventTime);
   GlobalVariableSet(DirectionalPauseKey(side), (double)pauseUntil);
   PrintFormat("TGM [R378]: %s paused until %s after %d same-side losses. level=%s net=%.2f",
               (side == POSITION_TYPE_BUY) ? "BUY" : "SELL",
               TimeToString(pauseUntil, TIME_DATE|TIME_MINUTES),
               streak, level, net);
  }

bool IsDirectionalPauseActive(const ENUM_POSITION_TYPE side, string &reasonOut)
  {
   const string key = DirectionalPauseKey(side);
   if(!GlobalVariableCheck(key))
      return false;

   const datetime pauseUntil = (datetime)GlobalVariableGet(key);
   if(TimeCurrent() >= pauseUntil)
     {
      GlobalVariableDel(key);
      return false;
     }

   reasonOut = StringFormat("%s paused after %d same-side losses until %s",
                            (side == POSITION_TYPE_BUY) ? "BUY" : "SELL",
                            TGM_SIDE_LOSS_STREAK_LIMIT,
                            TimeToString(pauseUntil, TIME_DATE|TIME_MINUTES));
   return true;
  }

void UpdateExtremeH4ShockCooldown()
  {
   const datetime lastClosedH4 = iTime(_Symbol, PERIOD_H4, 1);
   if(lastClosedH4 <= 0)
      return;

   const string lastBarKey = ExtremeH4ShockBarKey();
   if(GlobalVariableCheck(lastBarKey) && (datetime)GlobalVariableGet(lastBarKey) == lastClosedH4)
      return;
   GlobalVariableSet(lastBarKey, (double)lastClosedH4);

   const double pip = Phase17_GetPipSize();
   if(pip <= 0.0)
      return;

   const double h = iHigh(_Symbol, PERIOD_H4, 1);
   const double l = iLow(_Symbol, PERIOD_H4, 1);
   const double o = iOpen(_Symbol, PERIOD_H4, 1);
   const double c = iClose(_Symbol, PERIOD_H4, 1);
   if(h <= l || o <= 0.0 || c <= 0.0)
      return;

   const double rangePips = (h - l) / pip;
   const double bodyPips  = MathAbs(c - o) / pip;
   if(rangePips + 1e-9 < TGM_EXTREME_H4_RANGE_PIPS || bodyPips + 1e-9 < TGM_EXTREME_H4_BODY_PIPS)
      return;

   const datetime pauseUntil = lastClosedH4 + (4 * 60 * 60) + (TGM_EXTREME_H4_COOLDOWN_HOURS * 60 * 60);
   const string cooldownKey = ExtremeH4ShockUntilKey();
   const datetime existingUntil = GlobalVariableCheck(cooldownKey) ? (datetime)GlobalVariableGet(cooldownKey) : 0;
   if(pauseUntil > existingUntil)
      GlobalVariableSet(cooldownKey, (double)pauseUntil);

   PrintFormat("TGM [R378]: EXTREME_H4_SHOCK range=%.1f body=%.1f -> pause new grid until %s",
               rangePips, bodyPips, TimeToString(pauseUntil, TIME_DATE|TIME_MINUTES));
  }

bool IsExtremeH4ShockCooldownActive(string &reasonOut)
  {
#ifdef TGM_R380_DISABLE_SHOCK_COOLDOWN
   reasonOut = "";
   return false; // R380: never pause grid for extreme H4 candles
#else
   UpdateExtremeH4ShockCooldown();

   const string key = ExtremeH4ShockUntilKey();
   if(!GlobalVariableCheck(key))
      return false;

   const datetime pauseUntil = (datetime)GlobalVariableGet(key);
   if(TimeCurrent() >= pauseUntil)
     {
      GlobalVariableDel(key);
      return false;
     }

   reasonOut = StringFormat("EXTREME_H4_SHOCK cooldown until %s",
                            TimeToString(pauseUntil, TIME_DATE|TIME_MINUTES));
   return true;
#endif
  }

int CancelPendingOrdersForSide(const ENUM_POSITION_TYPE side)
  {
   const ENUM_ORDER_TYPE wantType = (side == POSITION_TYPE_BUY) ? ORDER_TYPE_BUY_LIMIT
                                                                : ORDER_TYPE_SELL_LIMIT;
   int n = 0;
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      const ulong ticket = OrderGetTicket(i);
      if(ticket == 0 || !OrderSelect(ticket))
         continue;
      if(OrderGetString(ORDER_SYMBOL) != _Symbol)
         continue;
      if((long)OrderGetInteger(ORDER_MAGIC) != EXPERT_MAGIC)
         continue;
      if(!IsBotGridPendingOrder(ticket))
         continue;
      if((ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE) != wantType)
         continue;

      const string comment = OrderGetString(ORDER_COMMENT);
      if(ExecuteTradeOp("OrderDelete", g_trade.OrderDelete(ticket),
                        StringFormat("ticket=%I64u sideCancel", ticket)))
        {
         ClearGridLevelState(comment);
         MarkLevelActivationExhaustedThisH4(comment);
         n++;
        }
     }
   return n;
  }

void ClearResearchRuntimeGuards()
  {
   // Wipe directional pause / shock / loss counters so each tester run starts fresh.
   string prefixes[13];
   prefixes[0] = "TGM_SideLoss_";
   prefixes[1] = "TGM_SidePause_";
   prefixes[2] = "TGM_ShockUntil_";
   prefixes[3] = "TGM_ShockBar_";
   prefixes[4] = "R389_OrigVol_";
   prefixes[5] = "R389_Stage1_";
   prefixes[6] = "R389_Stage2_";
   prefixes[7] = "R389_Stage3_";
   prefixes[8] = "TGM_P28A_Runner_";
   prefixes[9] = "TGM_HedgeBar_";
   prefixes[10] = "TGM_HedgeCnt_";
   prefixes[11] = "TGM_HedgeCyc_";
   prefixes[12] = "TGM_HedgeCD_";

   for(int i = GlobalVariablesTotal() - 1; i >= 0; i--)
     {
      const string name = GlobalVariableName(i);
      for(int p = 0; p < 13; p++)
        {
         if(StringFind(name, prefixes[p]) == 0)
           {
            GlobalVariableDel(name);
            break;
           }
        }
     }
   Print("TGM [R380]: Cleared research runtime guards for clean tester start.");
  }

string LevelBELockKey(const string comment)
  {
   return StringFormat("TGM_LvlBE_%I64u_%s_%I64d_%s",
                       (ulong)AccountInfoInteger(ACCOUNT_LOGIN),
                       _Symbol,
                       (long)GetCurrentH4BarOpenTime(),
                       comment);
  }

string LevelActCountKey(const string comment)
  {
   return StringFormat("TGM_LvlAct_%I64u_%s_%I64d_%s",
                       (ulong)AccountInfoInteger(ACCOUNT_LOGIN),
                       _Symbol,
                       (long)GetCurrentH4BarOpenTime(),
                       comment);
  }

string LevelActExhaustKey(const string comment)
  {
   return StringFormat("TGM_LvlAx_%I64u_%s_%I64d_%s",
                       (ulong)AccountInfoInteger(ACCOUNT_LOGIN),
                       _Symbol,
                       (long)GetCurrentH4BarOpenTime(),
                       comment);
  }

int GetLevelActivationCountThisH4(const string comment)
  {
   const string key = LevelActCountKey(comment);
   return GlobalVariableCheck(key) ? (int)GlobalVariableGet(key) : 0;
  }

void IncrementLevelActivationThisH4(const string comment)
  {
   if(comment == "")
      return;
   const int next = GetLevelActivationCountThisH4(comment) + 1;
   GlobalVariableSet(LevelActCountKey(comment), (double)next);
   PrintFormat("TGM [MODE-B]: Level %s activation #%d / %d this H4.",
               comment, next, MaxLevelActivationsThisH4());
   LogPhase28A("POSITION_ENTRY", 0,
               StringFormat("%s activation=%d/%d h4=%s",
                            comment, next, MaxLevelActivationsThisH4(),
                            TimeToString(GetCurrentH4BarOpenTime(), TIME_DATE|TIME_MINUTES)));
  }

void ClearAllLevelActivationCountsThisH4()
  {
   string comments[6] = {"GM_BL1","GM_BL2","GM_BL3","GM_SL1","GM_SL2","GM_SL3"};
   for(int i = 0; i < 6; i++)
     {
      const string ck = LevelActCountKey(comments[i]);
      const string ek = LevelActExhaustKey(comments[i]);
      if(GlobalVariableCheck(ck)) GlobalVariableDel(ck);
      if(GlobalVariableCheck(ek)) GlobalVariableDel(ek);
     }
  }

bool IsLevelActivationExhaustedThisH4(const string comment)
  {
   return (GlobalVariableCheck(LevelActExhaustKey(comment)) &&
           GlobalVariableGet(LevelActExhaustKey(comment)) > 0.5);
  }

void MarkLevelActivationExhaustedThisH4(const string comment)
  {
   if(comment == "")
      return;
   GlobalVariableSet(LevelActExhaustKey(comment), 1.0);
   SetGridLevelState(comment, TGM_GRID_LEVEL_SPENT);
  }

bool IsLevelBELockedThisH4(const string comment)
  {
   return (GlobalVariableCheck(LevelBELockKey(comment)) &&
           GlobalVariableGet(LevelBELockKey(comment)) > 0.5);
  }

void MarkLevelBELockedThisH4(const string comment)
  {
   if(comment == "")
      return;
   GlobalVariableSet(LevelBELockKey(comment), 1.0);
   SetGridLevelState(comment, TGM_GRID_LEVEL_SPENT);
   PrintFormat("TGM [MODE-B]: Level %s LOCKED for this H4 (profit BE hit) — no more re-entries.", comment);
  }

void ClearAllLevelBELocksThisH4()
  {
   string comments[6] = {"GM_BL1","GM_BL2","GM_BL3","GM_SL1","GM_SL2","GM_SL3"};
   for(int i = 0; i < 6; i++)
     {
      const string key = LevelBELockKey(comments[i]);
      if(GlobalVariableCheck(key))
         GlobalVariableDel(key);
     }
  }

string ResolveGridLevelCommentFromTicket(const ulong ticket)
  {
   CPositionInfo pos;
   if(pos.SelectByTicket(ticket) && IsGridPositionComment(pos.Comment()))
      return pos.Comment();

   string dealComment = "";
   string orderComment = "";
   if(GetPositionOpeningComments(ticket, dealComment, orderComment))
     {
      if(IsGridPositionComment(dealComment))
         return dealComment;
      if(IsGridPositionComment(orderComment))
         return orderComment;
     }
   return "";
  }

void SaveGridH4BarTime(const datetime barTime)
  {
   // Phase28/27: do NOT reset level state here — callers reset BEFORE placement.
   // Resetting after ExecuteH4GridStrategy wiped PENDING flags (Issue 1B).
   g_lastH4BarTime = barTime;
   g_historyCacheH4Start = 0;
   GlobalVariableSet(GridH4BarStateKey(), (double)barTime);
  }
bool IsNewH4GridPeriod() { datetime currentH4 = GetCurrentH4BarOpenTime(); if(currentH4 <= 0) return false; if(g_lastH4BarTime <= 0) g_lastH4BarTime = LoadGridH4BarTime(); return (g_lastH4BarTime != currentH4); }

int CountBotPendingByComment(const string comment)
  {
   int count = 0;
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      ulong ticket = OrderGetTicket(i);
      if(ticket == 0 || !OrderSelect(ticket))
         continue;
      if(OrderGetString(ORDER_SYMBOL) != _Symbol)
         continue;
      if((long)OrderGetInteger(ORDER_MAGIC) != EXPERT_MAGIC)
         continue;
      if(!IsPendingOrderType((ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE)))
         continue;
      if(PendingCommentMatchesLevel(OrderGetString(ORDER_COMMENT), comment))
         count++;
     }
   return count;
  }

bool IsCommentActiveInPositions(const string comment)
  {
   CPositionInfo pos;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(pos.SelectByIndex(i) && pos.Symbol() == _Symbol && pos.Magic() == (ulong)EXPERT_MAGIC)
        {
         if(StringFind(pos.Comment(), comment) >= 0) return true;
        }
     }
   return false;
  }

bool IsLevelAlreadySpentInCurrentH4Bar(const string comment)
  {
   // Mode B: spent on profit lock OR after max 2 activations (2nd SL ends level).
   if(IsFixedSlReentryMode())
      return (IsLevelBELockedThisH4(comment) || IsLevelActivationExhaustedThisH4(comment) ||
              GetLevelActivationCountThisH4(comment) >= MaxLevelActivationsThisH4());

   datetime currentH4Start = GetCurrentH4BarOpenTime();
   if(currentH4Start <= 0) return false;

   g_historyCacheH4Start  = currentH4Start;
   g_historyCacheSelectOk = HistorySelect(currentH4Start, TimeCurrent());
   if(!g_historyCacheSelectOk) return false;

   int totalDeals = HistoryDealsTotal();
   for(int i = 0; i < totalDeals; i++)
     {
      ulong ticket = HistoryDealGetTicket(i);
      if(ticket > 0)
        {
         if(HistoryDealGetString(ticket, DEAL_SYMBOL) == _Symbol && 
            HistoryDealGetInteger(ticket, DEAL_MAGIC) == EXPERT_MAGIC)
           {
            string dealComment = HistoryDealGetString(ticket, DEAL_COMMENT);
            if(StringFind(dealComment, comment) >= 0) return true; 
           }
        }
     }
   return false;
  }

void CloseAllBotPositionsForced(const string reason)
  {
   CPositionInfo pos;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(IsStopped()) return;
      if(!pos.SelectByIndex(i)) continue;
      if(pos.Symbol() != _Symbol || pos.Magic() != (ulong)EXPERT_MAGIC) continue;

      const ulong ticket = pos.Ticket();
      const double pts = GetTicketProfitPoints(ticket, SymbolInfoDouble(_Symbol, SYMBOL_POINT));
      PrintFormat("The Gold Mind: Force-close #%I64u (%s) reason=%s | profit=%.0f broker pts",
                  ticket,
                  (pos.PositionType() == POSITION_TYPE_BUY) ? "BUY" : "SELL",
                  reason,
                  pts);
      ExecuteTradeOp("PositionClose", g_trade.PositionClose(ticket), StringFormat("ticket=%I64u reason=%s", ticket, reason));
     }
  }

void CloseAllBotPositions(const string reason)
  {
   if(!PreTradeGuard("PositionClose"))
      return;

   CloseAllBotPositionsForced(reason);
  }

//--- Sum open grid-parent volume (excludes hedges) for basket scaling.
double GetTotalBotGridParentVolume()
  {
   double total = 0.0;
   CPositionInfo pos;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(!pos.SelectByIndex(i))
         continue;
      if(pos.Symbol() != _Symbol || pos.Magic() != (ulong)EXPERT_MAGIC)
         continue;
      if(!IsOurBotGridParent(pos.Ticket()))
         continue;
      total += pos.Volume();
     }
   return total;
  }

//--- Reference lot for basket target scaling (manual lot or broker minimum).
double GetReferenceLotForBasketScaling()
  {
   if(RiskMode == RISK_MANUAL_LOT && Manual_Lot_Size > 0.0)
      return Manual_Lot_Size;
   const double vmin = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   return (vmin > 0.0) ? vmin : 0.01;
  }

//--- Scale basket target with total open volume so large auto lots do not
//    trigger a $500 lock after only ~1.0 price unit (~10pip on XAUUSD).
double GetEffectiveBasketTpTarget()
  {
   if(Basket_TP_Amount <= 0.0)
      return 0.0;
   const double totalVol = GetTotalBotGridParentVolume();
   const double refVol   = GetReferenceLotForBasketScaling();
   if(totalVol <= 0.0 || refVol <= 0.0)
      return Basket_TP_Amount;
   const double scale = MathMax(1.0, totalVol / refVol);
   return Basket_TP_Amount * scale;
  }

//--- Block basket close while any winner is still below the profit-engine floor.
bool HasBasketPrematureWinners()
  {
   CPositionInfo pos;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(!pos.SelectByIndex(i))
         continue;
      if(pos.Symbol() != _Symbol || pos.Magic() != (ulong)EXPERT_MAGIC)
         continue;
      if(!IsOurBotGridParent(pos.Ticket()))
         continue;
      const double profitUSD = GetPositionProfitUSD(pos.Ticket());
      if(profitUSD > 0.0 && profitUSD < InpProfitBE)
         return true;
     }
   return false;
  }

//--- Global Basket Take Profit: when Equity >= Balance + target, hard-lock
//    floating profit into Balance by closing ALL bot positions + pendings.
void ProcessBasketTakeProfit()
  {
   if(!Enable_Basket_TP || Basket_TP_Amount <= 0.0)
      return;
   if(IsMarketValidationMode())
      return;
   if(!IsGoldChartSymbol())
      return;

   // Mode B: shared Live ATR-14 H4 SL + ATR TP per trade. Basket TP stays Mode A only.
   if(IsFixedSlReentryMode())
      return;

   const double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   const double equity  = AccountInfoDouble(ACCOUNT_EQUITY);
   const double floating = equity - balance;
   const double target   = GetEffectiveBasketTpTarget();
   if(floating < target)
      return;
   if(HasBasketPrematureWinners())
      return;

   // Avoid re-entry on the same second while closes settle.
   static datetime lastBasketTpSec = 0;
   const datetime now = TimeCurrent();
   if(now == lastBasketTpSec)
      return;
   lastBasketTpSec = now;

   PrintFormat("TGM [BASKET-TP]: Equity $%.2f >= Balance $%.2f + $%.2f (floating $%.2f, target $%.2f) -> close ALL + reset grid.",
               equity, balance, target, floating, target);

   CloseAllBotPositionsForced("BasketTP");
   EnsureAllBotPendingDeletedForced();
   ResetAllGridLevelStates();

   if(IsGridOpsAllowed() && IsGridPlacementAllowed())
     {
      ExecuteH4GridStrategy();
      SaveGridH4BarTime(GetCurrentH4BarOpenTime());
     }

   PrintFormat("TGM [BASKET-TP]: Locked. New Balance≈$%.2f Equity≈$%.2f | grid reset.",
               AccountInfoDouble(ACCOUNT_BALANCE), AccountInfoDouble(ACCOUNT_EQUITY));
  }

bool HasWinningSideArmed(const ENUM_POSITION_TYPE side)
  {
   CPositionInfo pos;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(!pos.SelectByIndex(i))
         continue;
      if(pos.Symbol() != _Symbol || pos.Magic() != (ulong)EXPERT_MAGIC)
         continue;
      if(pos.PositionType() != side)
         continue;
      if(IsBotHedgePosition(pos.Ticket(), pos.Comment()))
         continue;
      if(!WasOpenedAsGridLimit(pos.Ticket()))
         continue;
      // Profit engine armed = BE + partial done, trailing active.
      if(IsProfitEngineArmed(pos.Ticket()) && GetPositionProfitUSD(pos.Ticket()) >= 0.0)
         return true;
     }
   return false;
  }

int CountOpenGridParents(const ENUM_POSITION_TYPE sideFilter = (ENUM_POSITION_TYPE)-1)
  {
   CPositionInfo pos;
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(!pos.SelectByIndex(i))
         continue;
      if(pos.Symbol() != _Symbol || pos.Magic() != (ulong)EXPERT_MAGIC)
         continue;
      if(!IsOurBotGridParent(pos.Ticket()))
         continue;
      if(sideFilter != (ENUM_POSITION_TYPE)-1 && pos.PositionType() != sideFilter)
         continue;
      count++;
     }
   return count;
  }

bool R376_AllowGridSideThisH4(const ENUM_POSITION_TYPE side, const double pivot, const double prevClose)
  {
   if(!R376_ENABLE_H4_DIRECTION_FILTER)
      return true;
   if(pivot <= 0.0 || prevClose <= 0.0)
      return true;

   // R379: require TWO closed H4 candles on the same side of pivot.
   // Mixed / chop / one-bar flip -> block both sides (no new grid).
   const double close2 = iClose(_Symbol, PERIOD_H4, 2);
   if(close2 <= 0.0)
      return false;

   const bool bull1 = (prevClose > pivot + 1e-9);
   const bool bear1 = (prevClose < pivot - 1e-9);
   const bool bull2 = (close2 > pivot + 1e-9);
   const bool bear2 = (close2 < pivot - 1e-9);

   if(bull1 && bull2)
      return (side == POSITION_TYPE_BUY);
   if(bear1 && bear2)
      return (side == POSITION_TYPE_SELL);
   return false;
  }

// sideToRestrict = the losing / opposite side we want to pause.
bool IsOppositeBleedPaused(const ENUM_POSITION_TYPE sideToRestrict)
  {
   if(!Enable_TrendBleedProtect)
      return false;

   if(sideToRestrict == POSITION_TYPE_SELL)
      return HasWinningSideArmed(POSITION_TYPE_BUY);   // buys winning -> pause sells
   if(sideToRestrict == POSITION_TYPE_BUY)
      return HasWinningSideArmed(POSITION_TYPE_SELL);  // sells winning -> pause buys
   return false;
  }

int DeleteBotPendingsOfType(const ENUM_ORDER_TYPE orderType)
  {
   int deleted = 0;
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      const ulong ticket = OrderGetTicket(i);
      if(ticket == 0 || !OrderSelect(ticket))
         continue;
      if(OrderGetString(ORDER_SYMBOL) != _Symbol)
         continue;
      if((long)OrderGetInteger(ORDER_MAGIC) != EXPERT_MAGIC)
         continue;
      if(!IsBotGridPendingOrder(ticket))
         continue;
      if((ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE) != orderType)
         continue;

      const string comment = OrderGetString(ORDER_COMMENT);
      if(ExecuteTradeOp("OrderDelete", g_trade.OrderDelete(ticket),
                        StringFormat("ticket=%I64u bleedProtect", ticket)))
        {
         ClearGridLevelState(comment);
         deleted++;
        }
     }
   return deleted;
  }

void EnforceTrendBleedProtect()
  {
   if(!Enable_TrendBleedProtect || IsMarketValidationMode())
      return;

   static datetime lastLogSec = 0;
   const datetime now = TimeCurrent();

   if(HasWinningSideArmed(POSITION_TYPE_BUY))
     {
      const int n = DeleteBotPendingsOfType(ORDER_TYPE_SELL_LIMIT);
      if(n > 0 && now != lastLogSec)
        {
         lastLogSec = now;
         PrintFormat("TGM [BLEED-PROTECT]: BUY side BE/trailing - removed %d opposite SELL limit(s).", n);
        }
     }

   if(HasWinningSideArmed(POSITION_TYPE_SELL))
     {
      const int n = DeleteBotPendingsOfType(ORDER_TYPE_BUY_LIMIT);
      if(n > 0 && now != lastLogSec)
        {
         lastLogSec = now;
         PrintFormat("TGM [BLEED-PROTECT]: SELL side BE/trailing - removed %d opposite BUY limit(s).", n);
        }
     }
  }

//--- Fast shutdown used ONLY from OnDeinit(REASON_REMOVE/CHARTCLOSE).
//    OnDeinit has a hard ~2.5s budget; the normal synchronous loops
//    (per-order round-trips + Sleep()) blow past it and MT5 reports
//    "Abnormal termination". Here we fire every delete/close in ASYNC
//    mode (single pass, no waiting, no Sleep) so the handler returns
//    instantly while the terminal still forwards the requests.
void ShutdownCloseAllBotAsync()
  {
   g_trade.SetAsyncMode(true);

   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      const ulong ticket = OrderGetTicket(i);
      if(ticket > 0 && IsBotGridPendingOrder(ticket))
         g_trade.OrderDelete(ticket);
     }

   CPositionInfo pos;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(!pos.SelectByIndex(i)) continue;
      if(pos.Symbol() != _Symbol || pos.Magic() != (ulong)EXPERT_MAGIC) continue;
      g_trade.PositionClose(pos.Ticket());
     }

   g_trade.SetAsyncMode(false);
  }

string EaBuildVersionKey()
  {
   return StringFormat("TGM_Build_%I64u_%s",
                       (ulong)AccountInfoInteger(ACCOUNT_LOGIN),
                       _Symbol);
  }

void RecordEaBuildSerial()
  {
   const string key = EaBuildVersionKey();
   const int prevBuild = GlobalVariableCheck(key) ? (int)GlobalVariableGet(key) : 0;
   GlobalVariableSet(key, (double)TGM_BUILD_SERIAL);
   if(prevBuild > 0 && prevBuild != TGM_BUILD_SERIAL)
      PrintFormat("The Gold Mind: Build %d -> %d (existing trades NOT closed).", prevBuild, TGM_BUILD_SERIAL);
  }

bool IsGridEntryPriceBlocked(const double entryPrice)
  {
   const int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   const double normEntry = NormalizeDouble(entryPrice, digits);
   const double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   if(point <= 0.0) return false;
   // Gold / 3-digit brokers: block same entry within a few points (duplicate Buy Limit race).
   const double tolerance = point * 10.0;

   CPositionInfo pos;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(!pos.SelectByIndex(i)) continue;
      if(pos.Symbol() != _Symbol || pos.Magic() != (ulong)EXPERT_MAGIC) continue;
      if(MathAbs(pos.PriceOpen() - normEntry) <= tolerance) return true;
     }

   for(int j = OrdersTotal() - 1; j >= 0; j--)
     {
      ulong ticket = OrderGetTicket(j);
      if(ticket == 0 || !OrderSelect(ticket)) continue;
      if(OrderGetString(ORDER_SYMBOL) != _Symbol || (long)OrderGetInteger(ORDER_MAGIC) != EXPERT_MAGIC) continue;
      if(!IsPendingOrderType((ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE))) continue;
      if(MathAbs(OrderGetDouble(ORDER_PRICE_OPEN) - normEntry) <= tolerance) return true;
     }

   return false;
  }

bool PendingCommentMatchesLevel(const string orderComment, const string levelComment)
  {
   if(levelComment == "")
      return false;
   if(orderComment == levelComment)
      return true;
   if(orderComment != "" && StringFind(orderComment, levelComment) >= 0)
      return true;
   // Broker may rewrite comment; resolve GM_BLx / GM_SLx token.
   return (ResolveGridLevelNameFromComment(orderComment) == levelComment);
  }

// Keep oldest pending at a price; delete younger duplicates (same magic/symbol).
int CancelDuplicatePendingsAtSamePrice()
  {
   const int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   const double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   if(point <= 0.0)
      return 0;
   const double tolerance = point * 10.0;
   int removed = 0;

   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      const ulong ticketA = OrderGetTicket(i);
      if(ticketA == 0 || !OrderSelect(ticketA))
         continue;
      if(OrderGetString(ORDER_SYMBOL) != _Symbol)
         continue;
      if((long)OrderGetInteger(ORDER_MAGIC) != EXPERT_MAGIC)
         continue;
      if(!IsPendingOrderType((ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE)))
         continue;
      if(!IsGridPositionComment(OrderGetString(ORDER_COMMENT)) &&
         ResolveGridLevelNameFromComment(OrderGetString(ORDER_COMMENT)) == "")
         continue;

      const double priceA = NormalizeDouble(OrderGetDouble(ORDER_PRICE_OPEN), digits);
      const ENUM_ORDER_TYPE typeA = (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);

      for(int j = i - 1; j >= 0; j--)
        {
         const ulong ticketB = OrderGetTicket(j);
         if(ticketB == 0 || !OrderSelect(ticketB))
            continue;
         if(OrderGetString(ORDER_SYMBOL) != _Symbol)
            continue;
         if((long)OrderGetInteger(ORDER_MAGIC) != EXPERT_MAGIC)
            continue;
         if(!IsPendingOrderType((ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE)))
            continue;
         if((ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE) != typeA)
            continue;
         const double priceB = NormalizeDouble(OrderGetDouble(ORDER_PRICE_OPEN), digits);
         if(MathAbs(priceA - priceB) > tolerance)
            continue;

         // Delete the newer ticket (higher id); keep older.
         const ulong kill = (ticketA > ticketB) ? ticketA : ticketB;
         const string killComment = OrderSelect(kill) ? OrderGetString(ORDER_COMMENT) : "";
         if(ExecuteTradeOp("OrderDelete", g_trade.OrderDelete(kill),
                           StringFormat("DUP_PRICE cancel ticket=%I64u @ %.*f comment=%s",
                                        kill, digits, priceA, killComment)))
           {
            removed++;
            PrintFormat("TGM [DEDUP]: Removed duplicate pending #%I64u at %.*f (kept older twin).",
                        kill, digits, priceA);
           }
         break;
        }
     }
   return removed;
  }

void DeleteLegacyAiPanelObjects()
  {
   const long chart_id = ChartID();
   for(int i = ObjectsTotal(chart_id, 0, -1) - 1; i >= 0; i--)
     {
      const string name = ObjectName(chart_id, i, 0, -1);
      if(StringFind(name, TGM_AI_PANEL_PREFIX) == 0)
         ObjectDelete(chart_id, name);
     }
  }

void CleanupEAChartVisuals()
  {
   DeleteLegacyAiPanelObjects();
   DeleteAllGridChartObjects();
   DestroyAllChartDashboardUI();
   Comment("");
   ChartRedraw(ChartID());
  }

bool HasBotPendingByComment(const string comment) { return (CountBotPendingByComment(comment) > 0); }

ulong FindGridPendingTicketByComment(const string comment)
  {
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      const ulong ticket = OrderGetTicket(i);
      if(ticket == 0 || !OrderSelect(ticket))
         continue;
      if(OrderGetString(ORDER_SYMBOL) != _Symbol)
         continue;
      if((long)OrderGetInteger(ORDER_MAGIC) != EXPERT_MAGIC)
         continue;
      if(!IsPendingOrderType((ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE)))
         continue;
      if(PendingCommentMatchesLevel(OrderGetString(ORDER_COMMENT), comment))
         return ticket;
     }
   return 0;
  }

bool PositionMatchesGridComment(const ulong positionTicket, const string comment)
  {
   CPositionInfo pos;
   if(!pos.SelectByTicket(positionTicket))
      return false;
   if(pos.Symbol() != _Symbol || pos.Magic() != (ulong)EXPERT_MAGIC)
      return false;
   if(!WasOpenedAsGridLimit(positionTicket))
      return false;
   if(pos.Comment() == comment)
      return true;

   string dealComment = "";
   string orderComment = "";
   if(!GetPositionOpeningComments(positionTicket, dealComment, orderComment))
      return false;
   return (dealComment == comment || orderComment == comment);
  }

ulong FindGridPositionTicketByCommentThisH4(const string comment, const datetime currentH4)
  {
   CPositionInfo pos;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(!pos.SelectByIndex(i))
         continue;
      if(pos.Symbol() != _Symbol || pos.Magic() != (ulong)EXPERT_MAGIC)
         continue;
      if((datetime)pos.Time() < currentH4)
         continue;
      if(PositionMatchesGridComment(pos.Ticket(), comment))
         return pos.Ticket();
     }
   return 0;
  }

void SynchronizeGridLevelStates(const string reason)
  {
   const datetime currentH4 = GetCurrentH4BarOpenTime();
   if(currentH4 <= 0)
      return;

   // Heal any same-price duplicate Buy/Sell Limits left by race / reconnect.
   CancelDuplicatePendingsAtSamePrice();

   bool anyChange = false;
   string comments[6] = {"GM_BL1","GM_BL2","GM_BL3","GM_SL1","GM_SL2","GM_SL3"};
   for(int i = 0; i < 6; i++)
     {
      const string comment = comments[i];
      const double oldState = GetGridLevelState(comment);
      const ulong oldTicket = GetGridLevelTicket(comment);
      const ulong pendingTicket = FindGridPendingTicketByComment(comment);
      if(pendingTicket > 0)
        {
         if(oldState != TGM_GRID_LEVEL_PENDING || oldTicket != pendingTicket)
            anyChange = true;
         SetGridLevelState(comment, TGM_GRID_LEVEL_PENDING, pendingTicket);
         continue;
        }

      // In-flight claim: PENDING with ticket 0 means OrderSend started — do NOT clear
      // or ExecuteH4GridStrategy will place a second order at the same price.
      if(oldState == TGM_GRID_LEVEL_PENDING && oldTicket == 0)
         continue;

      const ulong liveTicket = FindGridPositionTicketByCommentThisH4(comment, currentH4);
      if(liveTicket > 0)
        {
         if(oldState != TGM_GRID_LEVEL_LIVE || oldTicket != liveTicket)
           {
            anyChange = true;
            // Mode B: count each fill as one activation (max 2 per H4).
            if(IsFixedSlReentryMode() &&
               (oldState != TGM_GRID_LEVEL_LIVE || oldTicket != liveTicket))
               IncrementLevelActivationThisH4(comment);
            SetGridLevelState(comment, TGM_GRID_LEVEL_LIVE, liveTicket);
            SeedHedgeMonitorForParent(liveTicket);
           }
         continue;
        }

      if(IsLevelAlreadySpentInCurrentH4Bar(comment))
        {
         if(oldState != TGM_GRID_LEVEL_SPENT)
            anyChange = true;
         SetGridLevelState(comment, TGM_GRID_LEVEL_SPENT);
         continue;
        }

      if(oldState != TGM_GRID_LEVEL_IDLE || oldTicket != 0)
         anyChange = true;
      ClearGridLevelState(comment);
     }

   if(anyChange || reason == "OnInit")
      PrintFormat("TGM [SYNC]: Grid state healed (%s) for H4 bar %s.",
                  reason, TimeToString(currentH4, TIME_DATE|TIME_MINUTES));
  }

void SynchronizePersistentState(const string reason)
  {
   if(!IsGoldChartSymbol())
      return;

   CleanDeadGlobalVariables();
   RebindOrphanHedgeLinks();
   AssignOrphanHedgesToParents();

   CPositionInfo pos;
   for(int i = 0; i < PositionsTotal(); i++)
     {
      if(!pos.SelectByIndex(i))
         continue;
      if(pos.Symbol() != _Symbol || pos.Magic() != (ulong)EXPERT_MAGIC)
         continue;
      if(!WasOpenedAsGridLimit(pos.Ticket()))
         continue;

      const double parentLoss = GetPositionLossUSD(pos.Ticket());
      if(!GlobalVariableCheck(PositionHedgeTriggerReadyKey(pos.Ticket())))
         SeedHedgeMonitorForParent(pos.Ticket());
     }

   SynchronizeGridLevelStates(reason);
  }

void ForceRebuildCurrentGrid(const string trigger)
  {
   if(!EnsureAllBotPendingDeleted()) return;
   ResetAllGridLevelStates();
   ExecuteH4GridStrategy(true);
   SaveGridH4BarTime(GetCurrentH4BarOpenTime());
  }

bool MaybeForceRebuildCurrentH4IfEmpty(const string trigger)
  {
   const datetime currentH4 = GetCurrentH4BarOpenTime();
   if(currentH4 <= 0)
      return false;
   if(g_lastEmptyGridRebuildH4 == currentH4)
      return false;
   if(CountPendingOrders() > 0 || HasOpenBotPositions())
      return false;

   g_lastEmptyGridRebuildH4 = currentH4;
   PrintFormat("TGM [SYNC]: Empty bot book on current H4 -> force rebuild (%s).", trigger);
   ForceRebuildCurrentGrid(trigger);
   return true;
  }

bool EnsureAllBotPendingDeletedForced()
  {
   int safetyIterations = 0;
   while(CountPendingOrders() > 0)
     {
      if(safetyIterations++ > CLEANUP_MAX_ITERATIONS)
        {
         Print("The Gold Mind: Forced pending-order cleanup exceeded max iterations. GetLastError=", GetLastError());
         return false;
        }
      if(IsStopped()) return false;

      bool deletedAny = false;
      for(int i = OrdersTotal() - 1; i >= 0; i--)
        {
         const ulong ticket = OrderGetTicket(i);
         if(ticket > 0 && IsBotGridPendingOrder(ticket))
           {
            const string comment = OrderGetString(ORDER_COMMENT);
            if(ExecuteTradeOp("OrderDelete", g_trade.OrderDelete(ticket), StringFormat("ticket=%I64u", ticket)))
              {
               ClearGridLevelState(comment);
               deletedAny = true;
              }
           }
        }

      if(!deletedAny && CountPendingOrders() > 0)
         break;

      if(!IsStrategyTester())
         Sleep(CLEANUP_SLEEP_MS);
     }
   return (CountPendingOrders() == 0);
  }

bool EnsureAllBotPendingDeleted()
  {
   if(!PreTradeGuard("OrderDelete"))
      return false;

   int safetyIterations = 0;
   while(CountPendingOrders() > 0)
     {
      if(safetyIterations++ > CLEANUP_MAX_ITERATIONS)
        {
         Print("The Gold Mind: Pending-order cleanup exceeded max iterations. GetLastError=", GetLastError());
         return false;
        }
      if(IsStopped()) return false;

      for(int i = OrdersTotal() - 1; i >= 0; i--)
        {
         const ulong ticket = OrderGetTicket(i);
         if(ticket > 0 && OrderSelect(ticket) && OrderGetString(ORDER_SYMBOL) == _Symbol && (long)OrderGetInteger(ORDER_MAGIC) == EXPERT_MAGIC)
           {
            if(!IsBotGridPendingOrder(ticket))
               continue;
            const string comment = OrderGetString(ORDER_COMMENT);
            if(!ExecuteTradeOp("OrderDelete", g_trade.OrderDelete(ticket), StringFormat("ticket=%I64u", ticket)))
              {
               const uint retcode = g_trade.ResultRetcode();
               if(retcode == TGM_RETCODE_MARKET_CLOSED || retcode == 10026 || IsServerTradePaused() || IsWeekendOrMarketClosed())
                  return false;
               break;
              }
            ClearGridLevelState(comment);
           }
        }
      if(!IsStrategyTester())
         Sleep(CLEANUP_SLEEP_MS);
     }
   return true;
  }

void RefreshGridOnNewH4Bar(const string trigger) { if(!EnsureAllBotPendingDeleted()) return; ResetAllGridLevelStates(); LogPhase28A("H4_RESET", 0, StringFormat("trigger=%s acts=0 first_sl=false second_sl=false", trigger)); ExecuteH4GridStrategy(true); SaveGridH4BarTime(GetCurrentH4BarOpenTime()); }

bool CreateOrUpdateGridHLine(const long chart_id, const string object_name, const double price, const color line_color)
  {
   if(price <= 0.0) return false;
   if(ObjectFind(chart_id, object_name) < 0)
     {
      ObjectCreate(chart_id, object_name, OBJ_HLINE, 0, 0, price);
      ObjectSetInteger(chart_id, object_name, OBJPROP_COLOR, line_color);
      ObjectSetInteger(chart_id, object_name, OBJPROP_STYLE, STYLE_DOT);
     }
   ObjectSetDouble(chart_id, object_name, OBJPROP_PRICE, price);
   ObjectSetInteger(chart_id, object_name, OBJPROP_TIMEFRAMES, 0);
   return true;
  }

void DeleteAllGridChartObjects()
  {
   long chart_id = ChartID();
   for(int i = ObjectsTotal(chart_id, 0, -1) - 1; i >= 0; i--)
     {
      string name = ObjectName(chart_id, i, 0, -1);
      if(StringFind(name, GRID_LINE_PREFIX) == 0) ObjectDelete(chart_id, name);
     }
   ChartRedraw(chart_id);
  }

void UpdateGridChartLines(const double high1, const double low1, const double pivot, const double buy1, const double buy2, const double buy3, const double sell1, const double sell2, const double sell3)
  {
   long chart_id = ChartID(); string p = GRID_LINE_PREFIX;
   CreateOrUpdateGridHLine(chart_id, p + "HIGH",  high1, clrSilver);
   CreateOrUpdateGridHLine(chart_id, p + "LOW",   low1,  clrSilver);
   CreateOrUpdateGridHLine(chart_id, p + "PIVOT", pivot, clrGold);
   CreateOrUpdateGridHLine(chart_id, p + "BUY1",  buy1,  clrDodgerBlue);
   CreateOrUpdateGridHLine(chart_id, p + "BUY2",  buy2,  clrDodgerBlue);
   CreateOrUpdateGridHLine(chart_id, p + "BUY3",  buy3,  clrDodgerBlue);
   CreateOrUpdateGridHLine(chart_id, p + "SELL1", sell1, clrOrangeRed);
   CreateOrUpdateGridHLine(chart_id, p + "SELL2", sell2, clrOrangeRed);
   CreateOrUpdateGridHLine(chart_id, p + "SELL3", sell3, clrOrangeRed);
   ChartRedraw(chart_id);
  }

bool CalculateH4GridLevels(double &high1, double &low1, double &pivot, double &buy1, double &buy2, double &buy3, double &sell1, double &sell2, double &sell3)
  {
   high1 = iHigh(_Symbol, PERIOD_H4, 1); low1 = iLow(_Symbol, PERIOD_H4, 1);
   if(high1 <= 0.0 || low1 <= 0.0 || high1 <= low1) return false;
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   double diff = high1 - low1; pivot = NormalizeDouble((high1 + low1) / 2.0, digits);
   // Excel Gold Level Strategy: BUY=High-diff*m | SELL=Low+diff*m
   buy1  = NormalizeDouble(high1 - (diff * 0.20), digits);
   buy2  = NormalizeDouble(high1 - (diff * 0.58), digits);
   buy3  = NormalizeDouble(high1 - (diff * 0.92), digits);
   sell1 = NormalizeDouble(low1  + (diff * 0.20), digits);
   sell2 = NormalizeDouble(low1  + (diff * 0.58), digits);
   sell3 = NormalizeDouble(low1  + (diff * 0.92), digits);
   return true;
  }

bool CalculateExcelGridSLTP(const double buy1, const double buy2, const double buy3, const double sell1, const double sell2, const double sell3, const double atrValue, double &buySL, double &sellSL, double &buyTP1, double &buyTP2, double &buyTP3, double &sellTP1, double &sellTP2, double &sellTP3)
  {
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   const double pip = Phase17_GetPipSize();
   if(pip <= 0.0)
      return false;

   // Shared SL for all 3 levels: 50pip beyond the LAST level.
   buySL  = NormalizeDouble(buy3  - (TGM_SHARED_SL_BEYOND_LAST_PIPS * pip), digits);
   sellSL = NormalizeDouble(sell3 + (TGM_SHARED_SL_BEYOND_LAST_PIPS * pip), digits);

   const double tpDist = atrValue * TP_ATR_Multiplier;
   if(atrValue <= 0.0 || tpDist <= 0.0)
      return false;

   buyTP1  = NormalizeDouble(buy1 + tpDist, digits);
   buyTP2  = NormalizeDouble(buy2 + tpDist, digits);
   buyTP3  = NormalizeDouble(buy3 + tpDist, digits);

   sellTP1 = NormalizeDouble(sell1 - tpDist, digits);
   sellTP2 = NormalizeDouble(sell2 - tpDist, digits);
   sellTP3 = NormalizeDouble(sell3 - tpDist, digits);

   return (buySL > 0.0 && sellSL > 0.0);
  }

void RefreshGridChartLinesFromH4()
  {
   double high1, low1, pivot, buy1, buy2, buy3, sell1, sell2, sell3;
   if(CalculateH4GridLevels(high1, low1, pivot, buy1, buy2, buy3, sell1, sell2, sell3))
      UpdateGridChartLines(high1, low1, pivot, buy1, buy2, buy3, sell1, sell2, sell3);
  }

int ExecuteH4GridStrategy(const bool freshH4Cycle = false)
  {
   if(!IsGridPlacementAllowed(freshH4Cycle))
      return 0;
   // Prevent OnTick + OnTradeTransaction (or nested SL re-arm) from placing twice.
   if(g_gridStrategyBusy)
      return 0;
   g_gridStrategyBusy = true;

   int placedCount = 0;
   double atrValue = 0.0;
   if(!GetLiveATR(atrValue))
     {
      g_gridStrategyBusy = false;
      return 0;
     }

   double high1, low1, pivot, buy1, buy2, buy3, sell1, sell2, sell3;
   if(!CalculateH4GridLevels(high1, low1, pivot, buy1, buy2, buy3, sell1, sell2, sell3))
     {
      g_gridStrategyBusy = false;
      return 0;
     }
   if(ShouldRenderUI())
      UpdateGridChartLines(high1, low1, pivot, buy1, buy2, buy3, sell1, sell2, sell3);

   double buySL, sellSL, buyTP1, buyTP2, buyTP3, sellTP1, sellTP2, sellTP3;
   if(!CalculateExcelGridSLTP(buy1, buy2, buy3, sell1, sell2, sell3, atrValue, buySL, sellSL, buyTP1, buyTP2, buyTP3, sellTP1, sellTP2, sellTP3))
     {
      g_gridStrategyBusy = false;
      return 0;
     }

   const double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   const double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   // R382: always allow both sides — no trend bias.
   const bool allowBuySide  = true;
   const bool allowSellSide = true;

   if(CountOpenGridParents() >= R376_MAX_OPEN_GRID_TOTAL)
     {
      g_gridStrategyBusy = false;
      return 0;
     }

   // Shared SL last+/-50pip: ALL buy levels use |buy1->sharedSL| for lots.
   const double buyLotDist  = MathAbs(buy1 - buySL);
   const double sellLotDist = MathAbs(sellSL - sell1);
   double buyEntries[3] = {buy1, buy2, buy3};
   double buyTPs[3]     = {buyTP1, buyTP2, buyTP3};
   string buyComments[3]= {"GM_BL1", "GM_BL2", "GM_BL3"};

   for(int b = 0; b < 3; b++)
     {
      if(!allowBuySide)
         break;
      if(CountOpenGridParents(POSITION_TYPE_BUY) >= R376_MAX_OPEN_GRID_PER_SIDE)
         break;
      if(IsOppositeBleedPaused(POSITION_TYPE_BUY))
         break;

      const double entry_price   = buyEntries[b];
      const double calculated_SL = buySL; // SAME shared SL on all 3 BUY levels
      const double tp            = buyTPs[b];
      const string comment       = buyComments[b];
      const double slDistLots    = buyLotDist;

      const double levelState = GetGridLevelState(comment);
      if(HasBotPendingByComment(comment) || levelState == TGM_GRID_LEVEL_PENDING) continue;
      if(levelState == TGM_GRID_LEVEL_LIVE && LevelHasLivePositionThisH4(comment)) continue;
      if(levelState == TGM_GRID_LEVEL_SPENT) continue;
      if(IsLevelBELockedThisH4(comment) || IsLevelActivationExhaustedThisH4(comment)) continue;
      if(GetLevelActivationCountThisH4(comment) >= MaxLevelActivationsThisH4()) continue;
      if(!Phase17_AllowReArm(GetLevelActivationCountThisH4(comment))) continue;
      if(IsGridEntryPriceBlocked(entry_price)) continue;
      if(calculated_SL >= entry_price) continue;
      if(slDistLots <= 0.0) continue;

      if(ask > entry_price)
        {
         if(PlaceBuyLimit(entry_price, calculated_SL, tp, slDistLots, b, comment)) placedCount++;
        }
      else
        {
         LogPriceThroughOnce(comment,
            StringFormat("LIMIT_INVALID_PRICE_THROUGH BUY ask=%.3f <= level=%.3f WAIT_FOR_VALID_LIMIT",
                         ask, entry_price));
        }
     }

   double sellEntries[3] = {sell1, sell2, sell3};
   double sellTPs[3]     = {sellTP1, sellTP2, sellTP3};
   string sellComments[3]= {"GM_SL1", "GM_SL2", "GM_SL3"};

   for(int s = 0; s < 3; s++)
     {
      if(!allowSellSide)
         break;
      if(CountOpenGridParents(POSITION_TYPE_SELL) >= R376_MAX_OPEN_GRID_PER_SIDE)
         break;
      if(IsOppositeBleedPaused(POSITION_TYPE_SELL))
         break;

      const double entry_price   = sellEntries[s];
      const double calculated_SL = sellSL; // SAME shared SL on all 3 SELL levels
      const double tp            = sellTPs[s];
      const string comment       = sellComments[s];
      const double slDistLots    = sellLotDist;

      const double levelState = GetGridLevelState(comment);
      if(HasBotPendingByComment(comment) || levelState == TGM_GRID_LEVEL_PENDING) continue;
      if(levelState == TGM_GRID_LEVEL_LIVE && LevelHasLivePositionThisH4(comment)) continue;
      if(levelState == TGM_GRID_LEVEL_SPENT) continue;
      if(IsLevelBELockedThisH4(comment) || IsLevelActivationExhaustedThisH4(comment)) continue;
      if(GetLevelActivationCountThisH4(comment) >= MaxLevelActivationsThisH4()) continue;
      if(!Phase17_AllowReArm(GetLevelActivationCountThisH4(comment))) continue;
      if(IsGridEntryPriceBlocked(entry_price)) continue;
      if(calculated_SL <= entry_price) continue;
      if(slDistLots <= 0.0) continue;

      if(bid < entry_price)
        {
         if(PlaceSellLimit(entry_price, calculated_SL, tp, slDistLots, s, comment)) placedCount++;
        }
      else
        {
         LogPriceThroughOnce(comment,
            StringFormat("LIMIT_INVALID_PRICE_THROUGH SELL bid=%.3f >= level=%.3f WAIT_FOR_VALID_LIMIT",
                         bid, entry_price));
        }
     }

   g_gridStrategyBusy = false;
   return placedCount;
  }

bool GetLiveATR(double &atrOut)
  {
   double buf[];
   ArraySetAsSeries(buf, true);
   if(CopyBuffer(g_atrHandle, 0, 0, 1, buf) != 1)
     {
      Print("The Gold Mind: CopyBuffer(iATR) failed. GetLastError=", GetLastError());
      return false;
     }
   atrOut = buf[0];
   return (atrOut > 0.0);
  }

//+------------------------------------------------------------------+
//| Auto lot: 2% of BALANCE (R415 — not equity, stops float feedback loop) |
//+------------------------------------------------------------------+
double GetLotSizingCapital()
  {
   double cap = AccountInfoDouble(ACCOUNT_BALANCE);
   if(cap > 0.0)
      return cap;
   return AccountInfoDouble(ACCOUNT_EQUITY);
  }

double CalculateAutoLotSize(const double slDistancePrice, const int levelIndex)
  {
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   if(point <= 0.0 || slDistancePrice <= 0.0) return 0.01;

   double slPoints = slDistancePrice / point;
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);

   if(slPoints <= 0.0 || tickSize <= 0.0 || tickValue <= 0.0) return 0.01;

   double equity = GetLotSizingCapital();
   if(equity <= 0.0)
      return 0.01;

   const double riskAmount = equity * TGM_RISK_PER_TRADE_FRACTION;
   double pointsValue = (point / tickSize) * tickValue;

   double lots = riskAmount / (slPoints * pointsValue);
   if(Max_Lot_Size > 0.0 && lots > Max_Lot_Size)
      lots = Max_Lot_Size;
   return NormalizeVolume(lots);
  }

double GetTradeVolume(const double slDistancePrice, const int levelIndex)
  {
   double lots = (RiskMode == RISK_MANUAL_LOT) ? NormalizeVolume(Manual_Lot_Size) : CalculateAutoLotSize(slDistancePrice, levelIndex);
   lots *= Phase17_GetLotExposureMultiplier();
   if(Max_Lot_Size > 0.0 && lots > Max_Lot_Size)
      lots = Max_Lot_Size;
   return NormalizeVolume(lots);
  }

double NormalizeVolume(double volume) 
  { 
   double vmin = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN); 
   double vmax = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX); 
   double vstep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   // EA hard cap: account growth must never push lots above Max_Lot_Size (default 5).
   if(Max_Lot_Size > 0.0 && Max_Lot_Size < vmax)
      vmax = Max_Lot_Size;
   volume = MathFloor(volume / vstep) * vstep; 
   return NormalizeDouble(MathMax(vmin, MathMin(vmax, volume)), 2); 
  }

void LogLotCalculationDetail(const string tag, const string comment, const int levelIndex, const double slDistancePrice, const double finalLots)
  {
   const double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   const double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   const double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double equity = GetLotSizingCapital();

   double slPoints = 0.0;
   double pointsValue = 0.0;
   double rawLots = 0.0;
   if(point > 0.0 && tickSize > 0.0 && tickValue > 0.0 && slDistancePrice > 0.0)
     {
      slPoints = slDistancePrice / point;
      pointsValue = (point / tickSize) * tickValue;
      if(slPoints > 0.0 && pointsValue > 0.0 && equity > 0.0)
         rawLots = (equity * TGM_RISK_PER_TRADE_FRACTION) / (slPoints * pointsValue);
     }

   const double ddMult = Phase17_GetLotExposureMultiplier();
   const double ddLots = NormalizeVolume(rawLots * ddMult);
   const double slPips = slDistancePrice / 0.10;
   const double riskAmount = equity * TGM_RISK_PER_TRADE_FRACTION;
   PrintFormat("TGM [LOTDBG]: %s %s L%d | equity=%.2f risk$=%.2f sl_price=%.3f sl_pips=%.1f raw=%.4f dd_mult=%.2f dd_lots=%.2f final=%.2f",
               tag, comment, levelIndex + 1, equity, riskAmount, slDistancePrice, slPips, rawLots, ddMult, ddLots, finalLots);
  }

bool PlaceBuyLimit(const double price, const double sl, const double tp, const double slDistForLots, const int levelIndex, const string comment)
  {
   if(!PreTradeGuard("BuyLimit"))
      return false;
   // Hard stop: never open a second pending/position at the same entry price.
   if(IsGridEntryPriceBlocked(price) || HasBotPendingByComment(comment) ||
      GetGridLevelState(comment) == TGM_GRID_LEVEL_PENDING)
     {
      PrintFormat("TGM [DEDUP]: Skip BuyLimit %s @ %s — level/price already armed.",
                  comment, DoubleToString(price, (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS)));
      return false;
     }

   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   double lots = GetTradeVolume(slDistForLots, levelIndex);
   // Shared SL (last±50) + ATR TP on pending. Profit method strips TP; loss method strips SL.
   const bool attachSL = (sl > 0.0);
   double orderSL = attachSL ? NormalizeDouble(sl, digits) : 0.0;
   double orderTP = NormalizeDouble(tp, digits);
   LogLotCalculationDetail("BuyLimit", comment, levelIndex, slDistForLots, lots);
   // Claim slot BEFORE OrderSend so sync/re-entry cannot place a twin.
   SetGridLevelState(comment, TGM_GRID_LEVEL_PENDING, 0);
   bool ok = g_trade.BuyLimit(lots, price, _Symbol, orderSL, orderTP, ORDER_TIME_GTC, 0, comment);
   const bool placed = ExecuteTradeOp("BuyLimit", ok, StringFormat("comment=%s lots=%.2f price=%.*f", comment, lots, digits, price));
   if(placed)
      SetGridLevelState(comment, TGM_GRID_LEVEL_PENDING, g_trade.ResultOrder());
   else
      ClearGridLevelState(comment);
   return placed;
  }

bool PlaceBuyStop(const double price, const double sl, const double tp, const double slDistForLots, const int levelIndex, const string comment)
  {
   if(!PreTradeGuard("BuyStop"))
      return false;
   if(IsGridEntryPriceBlocked(price) || HasBotPendingByComment(comment) ||
      GetGridLevelState(comment) == TGM_GRID_LEVEL_PENDING)
      return false;

   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   double lots = GetTradeVolume(slDistForLots, levelIndex);
   const bool attachSL = (sl > 0.0);
   double orderSL = attachSL ? NormalizeDouble(sl, digits) : 0.0;
   double orderTP = NormalizeDouble(tp, digits);
   LogLotCalculationDetail("BuyStop", comment, levelIndex, slDistForLots, lots);
   SetGridLevelState(comment, TGM_GRID_LEVEL_PENDING, 0);
   bool ok = g_trade.BuyStop(lots, price, _Symbol, orderSL, orderTP, ORDER_TIME_GTC, 0, comment);
   const bool placed = ExecuteTradeOp("BuyStop", ok, StringFormat("comment=%s lots=%.2f price=%.*f REARM", comment, lots, digits, price));
   if(placed)
     {
      SetGridLevelState(comment, TGM_GRID_LEVEL_PENDING, g_trade.ResultOrder());
      PrintFormat("TGM [REARM]: BUY STOP %s @ %.*f (price was at/below level after SL).", comment, digits, price);
     }
   else
      ClearGridLevelState(comment);
   return placed;
  }

bool PlaceSellLimit(const double price, const double sl, const double tp, const double slDistForLots, const int levelIndex, const string comment)
  {
   if(!PreTradeGuard("SellLimit"))
      return false;
   if(IsGridEntryPriceBlocked(price) || HasBotPendingByComment(comment) ||
      GetGridLevelState(comment) == TGM_GRID_LEVEL_PENDING)
     {
      PrintFormat("TGM [DEDUP]: Skip SellLimit %s @ %s — level/price already armed.",
                  comment, DoubleToString(price, (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS)));
      return false;
     }

   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   double lots = GetTradeVolume(slDistForLots, levelIndex);
   const bool attachSL = (sl > 0.0);
   double orderSL = attachSL ? NormalizeDouble(sl, digits) : 0.0;
   double orderTP = NormalizeDouble(tp, digits);
   LogLotCalculationDetail("SellLimit", comment, levelIndex, slDistForLots, lots);
   SetGridLevelState(comment, TGM_GRID_LEVEL_PENDING, 0);
   bool ok = g_trade.SellLimit(lots, price, _Symbol, orderSL, orderTP, ORDER_TIME_GTC, 0, comment);
   const bool placed = ExecuteTradeOp("SellLimit", ok, StringFormat("comment=%s lots=%.2f price=%.*f", comment, lots, digits, price));
   if(placed)
      SetGridLevelState(comment, TGM_GRID_LEVEL_PENDING, g_trade.ResultOrder());
   else
      ClearGridLevelState(comment);
   return placed;
  }

bool PlaceSellStop(const double price, const double sl, const double tp, const double slDistForLots, const int levelIndex, const string comment)
  {
   if(!PreTradeGuard("SellStop"))
      return false;
   if(IsGridEntryPriceBlocked(price) || HasBotPendingByComment(comment) ||
      GetGridLevelState(comment) == TGM_GRID_LEVEL_PENDING)
      return false;

   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   double lots = GetTradeVolume(slDistForLots, levelIndex);
   const bool attachSL = (sl > 0.0);
   double orderSL = attachSL ? NormalizeDouble(sl, digits) : 0.0;
   double orderTP = NormalizeDouble(tp, digits);
   LogLotCalculationDetail("SellStop", comment, levelIndex, slDistForLots, lots);
   SetGridLevelState(comment, TGM_GRID_LEVEL_PENDING, 0);
   bool ok = g_trade.SellStop(lots, price, _Symbol, orderSL, orderTP, ORDER_TIME_GTC, 0, comment);
   const bool placed = ExecuteTradeOp("SellStop", ok, StringFormat("comment=%s lots=%.2f price=%.*f REARM", comment, lots, digits, price));
   if(placed)
     {
      SetGridLevelState(comment, TGM_GRID_LEVEL_PENDING, g_trade.ResultOrder());
      PrintFormat("TGM [REARM]: SELL STOP %s @ %.*f (price was at/above level after SL).", comment, digits, price);
     }
   else
      ClearGridLevelState(comment);
   return placed;
  }

bool ExecutePartialClose(const ulong ticket, const double partialPercent)
  {
   if(!PreProtectionTradeGuard("PositionClosePartial"))
      return false;

   if(IsTicketPartialCloseDone(ticket))
     {
      LogPhase28A("DUPLICATE_TRIGGER_BLOCKED", ticket, "partial_already_done");
      return false;
     }

   CPositionInfo pos;
   if(!pos.SelectByTicket(ticket) || pos.Symbol() != _Symbol || pos.Magic() != (ulong)EXPERT_MAGIC)
      return false;

   const double currentLot = pos.Volume();
   const double volMin  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   const double volStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   if(currentLot <= volMin + 1e-12 || volStep <= 0.0)
     {
      LogPhase28A("PARTIAL_CLOSE_REQUEST", ticket,
                  StringFormat("REJECT volume_too_small current=%.2f min=%.2f", currentLot, volMin));
      return false;
     }

   // Close ~partialPercent but never leave an invalid remainder and never close 100%.
   double closeLot = NormalizeVolume(currentLot * (partialPercent / 100.0));
   double remainLot = NormalizeDouble(currentLot - closeLot, 8);
   if(remainLot < volMin - 1e-12)
     {
      // Reduce close so at least volMin remains.
      closeLot = NormalizeVolume(currentLot - volMin);
      remainLot = NormalizeDouble(currentLot - closeLot, 8);
     }
   if(closeLot < volMin - 1e-12 || closeLot >= currentLot - 1e-12 || remainLot < volMin - 1e-12)
     {
      LogPhase28A("PARTIAL_CLOSE_REQUEST", ticket,
                  StringFormat("REJECT broker_volume close=%.2f remain=%.2f current=%.2f min=%.2f",
                               closeLot, remainLot, currentLot, volMin));
      return false;
     }

   LogPhase28A("PARTIAL_CLOSE_REQUEST", ticket,
               StringFormat("close=%.2f of %.2f (%.0f%%) expect_remain=%.2f",
                            closeLot, currentLot, partialPercent, remainLot));

   const ENUM_POSITION_TYPE posType = pos.PositionType();
   const string opLabel = (posType == POSITION_TYPE_BUY) ? "PositionClosePartial(BUY)" : "PositionClosePartial(SELL)";

   if(!ExecuteTradeOp(opLabel, g_trade.PositionClosePartial(ticket, closeLot),
                      StringFormat("ticket=%I64u closeLot=%.2f of %.2f", ticket, closeLot, currentLot)))
     {
      LogPhase28A("PARTIAL_CLOSE_REQUEST", ticket, "REJECT OrderSend_failed");
      return false;
     }

   if(!pos.SelectByTicket(ticket))
     {
      // Unexpected full close — do NOT mark runner complete.
      LogPhase28A("PARTIAL_CLOSE_REQUEST", ticket, "REJECT fully_closed_no_runner");
      PrintFormat("TGM [PARTIAL]: Position #%I64u fully closed after partial on %s — runner state NOT marked.",
                  ticket, _Symbol);
      return false;
     }

   const double remainingLot = pos.Volume();
   if(remainingLot >= currentLot - 0.0000001)
     {
      LogPhase28A("PARTIAL_CLOSE_REQUEST", ticket, "REJECT volume_unchanged");
      PrintFormat("TGM [PARTIAL]: Volume unchanged on #%I64u - partial not confirmed.", ticket);
      return false;
     }

   MarkTicketPartialCloseDone(ticket);
   LogPhase28A("PARTIAL_CLOSE_CONFIRMED", ticket,
               StringFormat("closed=%.2f remaining=%.2f", closeLot, remainingLot));
   LogPhase28A("REMAINING_VOLUME", ticket, StringFormat("%.2f", remainingLot));
   PrintFormat("TGM [PARTIAL]: Closed %.0f%% (%.2f lots) on %s #%I64u | Remaining: %.2f.",
               partialPercent,
               closeLot,
               (posType == POSITION_TYPE_BUY) ? "BUY" : "SELL",
               ticket,
               remainingLot);
   return true;
  }

string PositionPartialCloseKey(const ulong ticket)
  {
   return StringFormat("TGM_Part_%I64u_%s_%I64u",
                       (ulong)AccountInfoInteger(ACCOUNT_LOGIN),
                       _Symbol,
                       ticket);
  }

string PositionPeakProfitKey(const ulong ticket)
  {
   return StringFormat("TGM_Peak_%I64u_%s_%I64u",
                       (ulong)AccountInfoInteger(ACCOUNT_LOGIN),
                       _Symbol,
                       ticket);
  }

void UpdatePeakProfitPoints(const ulong ticket, const double pointsInProfit)
  {
   const string key = PositionPeakProfitKey(ticket);
   if(!GlobalVariableCheck(key) || GlobalVariableGet(key) < pointsInProfit)
      GlobalVariableSet(key, pointsInProfit);
  }

double GetPeakProfitPoints(const ulong ticket)
  {
   const string key = PositionPeakProfitKey(ticket);
   return GlobalVariableCheck(key) ? GlobalVariableGet(key) : 0.0;
  }

string PositionHedgePeakProfitKey(const ulong hedgeTicket)
  {
   return StringFormat("TGM_HedgePk_%I64u_%s_%I64u",
                       (ulong)AccountInfoInteger(ACCOUNT_LOGIN),
                       _Symbol,
                       hedgeTicket);
  }

void UpdateHedgePeakProfitPoints(const ulong hedgeTicket, const double pointsInProfit)
  {
   const string key = PositionHedgePeakProfitKey(hedgeTicket);
   if(!GlobalVariableCheck(key) || GlobalVariableGet(key) < pointsInProfit)
      GlobalVariableSet(key, pointsInProfit);
  }

double GetHedgePeakProfitPoints(const ulong hedgeTicket)
  {
   const string key = PositionHedgePeakProfitKey(hedgeTicket);
   return GlobalVariableCheck(key) ? GlobalVariableGet(key) : 0.0;
  }

void ClearHedgePeakProfitPoints(const ulong hedgeTicket)
  {
   const string key = PositionHedgePeakProfitKey(hedgeTicket);
   if(GlobalVariableCheck(key))
      GlobalVariableDel(key);
  }

bool ShouldCloseHedgeOnMarketReturn(const ulong hedgeTicket, const ulong parentTicket, const double point, const double closeBrokerPts, const double triggerBrokerPts)
  {
   CPositionInfo parent;
   if(parent.SelectByTicket(parentTicket))
     {
      const double parentLossPts = GetTicketLossPoints(parentTicket, point);
      // Parent still needs protection — never close hedge during deep parent loss.
      if(parentLossPts >= triggerBrokerPts)
         return false;
     }

   const double hedgeProfitPts = GetTicketProfitPoints(hedgeTicket, point);
   UpdateHedgePeakProfitPoints(hedgeTicket, hedgeProfitPts);
   const double hedgePeakPts = GetHedgePeakProfitPoints(hedgeTicket);
   const double hedgeLossPts   = GetTicketLossPoints(hedgeTicket, point);

   if(hedgeProfitPts > 0.0)
      return false;

   if(hedgePeakPts < closeBrokerPts)
      return false;

   if(hedgeLossPts < closeBrokerPts)
      return false;

   return true;
  }

double CalcTrailSLFromPeak(const ENUM_POSITION_TYPE posType, const double openPrice, const double peakBrokerPts, const double trailGapPrice, const double beSL, const int digits)
  {
   const double peakMovePrice = peakBrokerPts * SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   if(posType == POSITION_TYPE_BUY)
      return NormalizeDouble(MathMax(openPrice + peakMovePrice - trailGapPrice, beSL), digits);

   return NormalizeDouble(MathMin(openPrice - peakMovePrice + trailGapPrice, beSL), digits);
  }

double GetTicketProfitPoints(const ulong ticket, const double point)
  {
   if(point <= 0.0)
      return 0.0;

   CPositionInfo pos;
   if(!pos.SelectByTicket(ticket))
      return 0.0;

   const double openPrice = pos.PriceOpen();
   if(pos.PositionType() == POSITION_TYPE_BUY)
     {
      const double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      return PriceMoveToBrokerPoints(bid - openPrice, point);
     }
   if(pos.PositionType() == POSITION_TYPE_SELL)
     {
      const double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      return PriceMoveToBrokerPoints(openPrice - ask, point);
     }
   return 0.0;
  }

bool IsTicketAtBreakEven(const double openPrice, const double currentSL, const int digits)
  {
   if(currentSL == 0.0)
      return false;

   const double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   const double beSL = NormalizeDouble(openPrice, digits);
   return (MathAbs(currentSL - beSL) <= point);
  }

bool IsTradeProfitZoneSecured(const ulong ticket)
  {
   CPositionInfo pos;
   if(!pos.SelectByTicket(ticket))
      return false;

   if(IsTicketPartialCloseDone(ticket))
      return true;

   const int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   return IsTicketAtBreakEven(pos.PriceOpen(), pos.StopLoss(), digits);
  }

string PositionBreakEvenPendingKey(const ulong ticket)
  {
   return StringFormat("TGM_BEPend_%I64u_%s_%I64u",
                       (ulong)AccountInfoInteger(ACCOUNT_LOGIN),
                       _Symbol,
                       ticket);
  }

void MarkBreakEvenPending(const ulong ticket)
  {
   GlobalVariableSet(PositionBreakEvenPendingKey(ticket), (double)TimeCurrent());
  }

void ClearBreakEvenPending(const ulong ticket)
  {
   const string key = PositionBreakEvenPendingKey(ticket);
   if(GlobalVariableCheck(key))
      GlobalVariableDel(key);
  }

bool IsBreakEvenPending(const ulong ticket)
  {
   return GlobalVariableCheck(PositionBreakEvenPendingKey(ticket));
  }

bool TryApplyBreakEvenAndPartial(const ulong ticket, const bool forceAttempt = false)
  {
   if(!Enable_BreakEven && !Enable_PartialClose)
      return IsTradeProfitZoneSecured(ticket);

   CPositionInfo pos;
   if(!pos.SelectByTicket(ticket))
     {
      ClearBreakEvenPending(ticket);
      return false;
     }
   if(pos.Symbol() != _Symbol || pos.Magic() != (ulong)EXPERT_MAGIC)
      return false;
   if(IsHedgePositionComment(pos.Comment()))
      return false;

   if(IsTradeProfitZoneSecured(ticket))
     {
      ClearBreakEvenPending(ticket);
      return true;
     }

   const int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   const double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   if(point <= 0.0)
      return false;

   const double openPrice     = pos.PriceOpen();
   const double currentSL     = pos.StopLoss();
   const double currentTP     = pos.TakeProfit();
   const ENUM_POSITION_TYPE posType = pos.PositionType();
   const double stopsLevel    = (double)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * point;
   const double unlockBrokerPts = StrategyPointsToBrokerPoints(TGM_BE_STRATEGY_POINTS);
   const double pointsInProfit  = GetTicketProfitPoints(ticket, point);

   UpdatePeakProfitPoints(ticket, pointsInProfit);
   const double peakProfitPts = GetPeakProfitPoints(ticket);

   const bool pendingBE = IsBreakEvenPending(ticket);
   const bool nearBreak = IsNearSessionBreak();
   if(peakProfitPts < unlockBrokerPts && !pendingBE && !forceAttempt)
      return false;

   const double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   const double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   const double beSL = NormalizeDouble(openPrice, digits);

   bool inProfitZone = false;
   if(posType == POSITION_TYPE_BUY)
      inProfitZone = ((bid - openPrice) > stopsLevel);
   else if(posType == POSITION_TYPE_SELL)
      inProfitZone = ((openPrice - ask) > stopsLevel);

   if(!inProfitZone)
     {
      if(peakProfitPts >= unlockBrokerPts || pendingBE)
         MarkBreakEvenPending(ticket);
      return false;
     }

   if(nearBreak && peakProfitPts >= unlockBrokerPts)
      PrintFormat("TGM [BE-PRIORITY]: Session break soon - securing #%I64u before rollover.", ticket);

   if(Enable_BreakEven && !IsTicketAtBreakEven(openPrice, currentSL, digits))
     {
      const string beOp = (posType == POSITION_TYPE_BUY) ? "PositionModify(BE-BUY)" : "PositionModify(BE-SELL)";
      if(SafePositionModify(ticket, beSL, currentTP, beOp))
         PrintFormat("TGM [BE]: %s #%I64u secured at entry (peak %.0f broker pts, now %.0f).",
                     (posType == POSITION_TYPE_BUY) ? "BUY" : "SELL", ticket, peakProfitPts, pointsInProfit);
      else
         return false;
     }

   if(Enable_PartialClose)
      ExecutePartialClose(ticket, PartialClose_Percent);

   if(IsTradeProfitZoneSecured(ticket))
     {
      ClearBreakEvenPending(ticket);
      return true;
     }

   if(peakProfitPts >= unlockBrokerPts)
      MarkBreakEvenPending(ticket);
   return false;
  }

void ProcessBreakEvenPriorityQueue()
  {
   if(!Enable_BreakEven && !Enable_PartialClose)
      return;

   if(!IsStrategyTester() && TimeCurrent() < g_modifyPausedUntil)
      return;

   ulong tickets[];
   ArrayResize(tickets, 0);

   CPositionInfo pos;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(!pos.SelectByIndex(i))
         continue;
      if(pos.Symbol() != _Symbol || pos.Magic() != (ulong)EXPERT_MAGIC)
         continue;
      if(IsHedgePositionComment(pos.Comment()))
         continue;
      if(!IsGridPositionComment(pos.Comment()))
         continue;

      const int n = ArraySize(tickets);
      ArrayResize(tickets, n + 1);
      tickets[n] = pos.Ticket();
     }

   for(int p = 0; p < ArraySize(tickets); p++)
     {
      if(IsStopped())
         return;
      if(IsBreakEvenPending(tickets[p]))
         TryApplyBreakEvenAndPartial(tickets[p], true);
     }

   const bool preRollForce = IsNearSessionBreak();
   for(int t = 0; t < ArraySize(tickets); t++)
     {
      if(IsStopped())
         return;
      TryApplyBreakEvenAndPartial(tickets[t], preRollForce);
     }
  }

bool IsTicketPartialCloseDone(const ulong ticket)
  {
   return GlobalVariableCheck(PositionPartialCloseKey(ticket));
  }

void MarkTicketPartialCloseDone(const ulong ticket)
  {
   GlobalVariableSet(PositionPartialCloseKey(ticket), 1.0);
  }

string PositionHedgeLinkKey(const ulong parentTicket)
  {
   return StringFormat("TGM_Hedge_%I64u_%s_%I64u",
                       (ulong)AccountInfoInteger(ACCOUNT_LOGIN),
                       _Symbol,
                       parentTicket);
  }

bool IsHedgePositionComment(const string comment)
  {
   return (StringFind(comment, TGM_HEDGE_COMMENT) == 0);
  }

bool IsGridPositionComment(const string comment)
  {
   if(IsHedgePositionComment(comment))
      return false;
   return (StringFind(comment, "GM_BL") == 0 || StringFind(comment, "GM_SL") == 0);
  }

//--- Robust hedge check. The broker (Exness) frequently REPLACES a position's
//    comment when a pending order fills or after a partial close, so we cannot
//    rely on the comment alone. A ticket is also a hedge when it is registered
//    in the hedge-link GlobalVariable table (set when the hedge is opened).
bool IsTrackedHedgeTicket(const ulong ticket)
  {
   const string prefix = StringFormat("TGM_Hedge_%I64u_%s_",
                                      (ulong)AccountInfoInteger(ACCOUNT_LOGIN),
                                      _Symbol);
   for(int i = GlobalVariablesTotal() - 1; i >= 0; i--)
     {
      const string name = GlobalVariableName(i);
      if(StringFind(name, prefix) != 0)
         continue;
      if((ulong)GlobalVariableGet(name) == ticket)
         return true;
     }
   return false;
  }

//--- A position is our HEDGE only with GM_HEDGE comment (live or opening deal).
//    NEVER treat "any market fill" as a hedge — that double-counted coverage
//    and DuplicateCleanup closed the real hedge (tester: covered 0.06 parent 0.03).
bool IsBotHedgePosition(const ulong ticket, const string comment)
  {
   if(WasOpenedAsGridLimit(ticket))
      return false;
   if(IsGridPositionComment(comment))
      return false;
   if(IsHedgePositionComment(comment))
      return true;
   // Exness often strips GM_HEDGE comment after fill — GV link still marks it.
   if(IsTrackedHedgeTicket(ticket))
      return true;
   if(HasHedgeOpeningEvidence(ticket))
      return true;
   return false;
  }

//--- The EA only ever opens grid + hedge positions under EXPERT_MAGIC. Therefore
//    ANY magic-matched position that is not a hedge is a grid trade -- even if
//    the broker stripped/replaced the original GM_BL/GM_SL comment on fill or
//    after a partial close. Callers must have already verified EXPERT_MAGIC.
bool IsBotGridPosition(const ulong ticket, const string comment)
  {
   return !IsBotHedgePosition(ticket, comment);
  }

//--- HARD ownership gate: manual / other-EA trades are invisible (magic != ours).
bool IsOurBotMagicPosition(const ulong ticket)
  {
   CPositionInfo pos;
   if(!pos.SelectByTicket(ticket))
      return false;
   if(pos.Symbol() != _Symbol)
      return false;
   if(pos.Magic() != (ulong)EXPERT_MAGIC)
      return false;
   return true;
  }

bool IsForeignOrManualPosition(const ulong ticket)
  {
   CPositionInfo pos;
   if(!pos.SelectByTicket(ticket))
      return true;
   if(pos.Symbol() != _Symbol)
      return true;
   return (pos.Magic() != (ulong)EXPERT_MAGIC);
  }

//--- Only OUR grid parents may receive hedges / BE / trail / basket logic.
bool IsOurBotGridParent(const ulong ticket)
  {
   if(!IsOurBotMagicPosition(ticket))
      return false; // manual or foreign EA → blind

   CPositionInfo pos;
   if(!pos.SelectByTicket(ticket))
      return false;
   if(IsBotHedgePosition(ticket, pos.Comment()))
      return false;
   return true;
  }

ulong ParseHedgeParentTicket(const string comment)
  {
   const string prefix = TGM_HEDGE_COMMENT + "_";
   if(StringFind(comment, prefix) != 0)
      return 0;
   return (ulong)StringToInteger(StringSubstr(comment, StringLen(prefix)));
  }

string BuildHedgeComment(const ulong parentTicket)
  {
   return StringFormat("%s_%I64u", TGM_HEDGE_COMMENT, parentTicket);
  }

//--- Read opening deal/order metadata for a live position. Exness often strips
//    DEAL_MAGIC on history deals, so magic=0 is accepted when the position
//    itself still carries EXPERT_MAGIC.
bool GetPositionOpeningInfo(const ulong positionTicket,
                            ENUM_ORDER_TYPE &orderTypeOut,
                            string &dealCommentOut,
                            string &orderCommentOut)
  {
   orderTypeOut    = ORDER_TYPE_BUY;
   dealCommentOut  = "";
   orderCommentOut = "";

   CPositionInfo pos;
   if(!pos.SelectByTicket(positionTicket))
      return false;
   if(pos.Symbol() != _Symbol || pos.Magic() != (ulong)EXPERT_MAGIC)
      return false;

   const long positionId = (long)pos.Identifier();
   if(positionId == 0 || !HistorySelectByPosition(positionId))
      return false;

   const int dealsTotal = HistoryDealsTotal();
   for(int d = 0; d < dealsTotal; d++)
     {
      const ulong dealTicket = HistoryDealGetTicket(d);
      if(dealTicket == 0)
         continue;
      if(HistoryDealGetString(dealTicket, DEAL_SYMBOL) != _Symbol)
         continue;

      const long dealMagic = HistoryDealGetInteger(dealTicket, DEAL_MAGIC);
      if(dealMagic != 0 && dealMagic != EXPERT_MAGIC)
         continue;

      const long entry = HistoryDealGetInteger(dealTicket, DEAL_ENTRY);
      if(entry != DEAL_ENTRY_IN && entry != DEAL_ENTRY_INOUT)
         continue;

      dealCommentOut = HistoryDealGetString(dealTicket, DEAL_COMMENT);
      const ulong orderTicket = (ulong)HistoryDealGetInteger(dealTicket, DEAL_ORDER);
      if(orderTicket != 0 && HistoryOrderSelect(orderTicket))
        {
         orderCommentOut = HistoryOrderGetString((long)orderTicket, ORDER_COMMENT);
         orderTypeOut    = (ENUM_ORDER_TYPE)HistoryOrderGetInteger(orderTicket, ORDER_TYPE);
        }
      else
        {
         orderTypeOut = (ENUM_ORDER_TYPE)HistoryDealGetInteger(dealTicket, DEAL_TYPE);
        }
      return true;
     }
   return false;
  }

bool GetPositionOpeningComments(const ulong positionTicket, string &dealCommentOut, string &orderCommentOut)
  {
   ENUM_ORDER_TYPE ot = ORDER_TYPE_BUY;
   return GetPositionOpeningInfo(positionTicket, ot, dealCommentOut, orderCommentOut);
  }

//--- Grid trades are ALWAYS Buy/Sell LIMIT pendings (GM_BL/GM_SL).
//    Hedge protect uses BUY_STOP/SELL_STOP — those are HEDGES, never grid.
//    (R410: old STOP-as-grid bug left hedge fills as "parents" with no profit book.)
bool WasOpenedAsGridLimit(const ulong positionTicket)
  {
   // Manual / foreign positions are NEVER treated as our grid parents.
   if(IsForeignOrManualPosition(positionTicket))
      return false;

   CPositionInfo pos;
   if(pos.SelectByTicket(positionTicket))
     {
      if(IsGridPositionComment(pos.Comment()))
         return true;
      if(IsHedgePositionComment(pos.Comment()))
         return false;
     }

   ENUM_ORDER_TYPE orderType = ORDER_TYPE_BUY;
   string dealComment = "";
   string orderComment = "";
   if(!GetPositionOpeningInfo(positionTicket, orderType, dealComment, orderComment))
     {
      // Unknown history but OUR magic + not hedge comment → still our grid parent.
      if(pos.SelectByTicket(positionTicket) && !IsHedgePositionComment(pos.Comment()))
         return true;
      return false;
     }

   if(IsGridPositionComment(dealComment) || IsGridPositionComment(orderComment))
      return true;
   if(IsHedgePositionComment(dealComment) || IsHedgePositionComment(orderComment))
      return false;

   // ONLY limits are grid. STOP fills = hedge protect (or foreign) — not grid.
   return (orderType == ORDER_TYPE_BUY_LIMIT || orderType == ORDER_TYPE_SELL_LIMIT);
  }

bool WasOpenedAsMarketHedge(const ulong positionTicket)
  {
   if(WasOpenedAsGridLimit(positionTicket))
      return false;

   ENUM_ORDER_TYPE orderType = ORDER_TYPE_BUY;
   string dealComment = "";
   string orderComment = "";
   if(!GetPositionOpeningInfo(positionTicket, orderType, dealComment, orderComment))
      return false;

   if(IsHedgePositionComment(dealComment) || IsHedgePositionComment(orderComment))
      return true;
   return (orderType == ORDER_TYPE_BUY || orderType == ORDER_TYPE_SELL);
  }

//--- When comment/GV parent id is missing, bind hedge to the grid parent with
//    the same lot size, opposite direction, and no other live hedge yet.
ulong InferHedgeParentTicket(const ulong hedgeTicket)
  {
   CPositionInfo hedge;
   if(!hedge.SelectByTicket(hedgeTicket))
      return 0;
   if(!IsOurBotMagicPosition(hedgeTicket))
      return 0; // never infer against foreign/manual
   if(WasOpenedAsGridLimit(hedgeTicket))
      return 0;

   const ENUM_POSITION_TYPE parentType = (hedge.PositionType() == POSITION_TYPE_SELL)
                                         ? POSITION_TYPE_BUY : POSITION_TYPE_SELL;
   const double hedgeVol = hedge.Volume();

   ulong   bestParent = 0;
   double  bestLoss   = -1.0;
   datetime bestOpen  = 0;

   CPositionInfo pos;
   for(int i = 0; i < PositionsTotal(); i++)
     {
      if(!pos.SelectByIndex(i))
         continue;
      if(pos.Ticket() == hedgeTicket)
         continue;
      // JAIL: only OUR grid parents — manual trades are invisible here.
      if(!IsOurBotGridParent(pos.Ticket()))
         continue;
      if(pos.PositionType() != parentType)
         continue;
      if(MathAbs(pos.Volume() - hedgeVol) > 0.0001)
         continue;

      // R394: never steal a parent that already has another live hedge link.
      ulong linked = 0;
      if(GetLinkedHedgeTicket(pos.Ticket(), linked) && linked != hedgeTicket)
         continue;

      // Strict comment match: another GM_HEDGE_<parent> already open?
      const string expect = BuildHedgeComment(pos.Ticket());
      bool otherHedge = false;
      CPositionInfo hp;
      for(int j = 0; j < PositionsTotal(); j++)
        {
         if(!hp.SelectByIndex(j))
            continue;
         if(hp.Ticket() == hedgeTicket)
            continue;
         if(hp.Symbol() != _Symbol || hp.Magic() != (ulong)EXPERT_MAGIC)
            continue;
         if(hp.Comment() == expect || ParseHedgeParentTicket(hp.Comment()) == pos.Ticket())
           {
            otherHedge = true;
            break;
           }
        }
      if(otherHedge)
         continue;

      const double loss = GetPositionLossUSD(pos.Ticket());
      if(loss > bestLoss || (MathAbs(loss - bestLoss) < 1e-9 && pos.Time() > bestOpen))
        {
         bestLoss   = loss;
         bestParent = pos.Ticket();
         bestOpen   = pos.Time();
        }
     }
   return bestParent;
  }

bool HasHedgeOpeningEvidence(const ulong ticket)
  {
   string dealComment = "";
   string orderComment = "";
   if(!GetPositionOpeningComments(ticket, dealComment, orderComment))
      return false;
   if(IsHedgePositionComment(dealComment) || IsHedgePositionComment(orderComment))
      return true;
   return (ParseHedgeParentTicket(dealComment) > 0 || ParseHedgeParentTicket(orderComment) > 0);
  }

//--- Comment / deal / GV link only — NEVER Infer (prevents cross-parent hedge theft).
ulong StrictHedgeParentTicket(const ulong hedgeTicket, const string comment)
  {
   ulong parentTicket = ParseHedgeParentTicket(comment);
   if(parentTicket == 0)
      parentTicket = FindParentForLinkedHedge(hedgeTicket);

   if(parentTicket == 0)
     {
      string dealComment = "";
      string orderComment = "";
      if(GetPositionOpeningComments(hedgeTicket, dealComment, orderComment))
        {
         parentTicket = ParseHedgeParentTicket(dealComment);
         if(parentTicket == 0)
            parentTicket = ParseHedgeParentTicket(orderComment);
        }
     }

   if(parentTicket > 0 && !IsOurBotGridParent(parentTicket))
      return 0;
   return parentTicket;
  }

ulong ResolveHedgeParentTicket(const ulong hedgeTicket, const string comment)
  {
   // R395: comment / deal / GV only. Infer is forbidden — it bound foreign lots
   // onto the deepest-loss parent and DuplicateCleanup killed the real hedge.
   return StrictHedgeParentTicket(hedgeTicket, comment);
  }

ulong GetOpenedPositionIdFromTrade()
  {
   const ulong deal = g_trade.ResultDeal();
   if(deal == 0)
      return 0;
   if(!HistoryDealSelect(deal))
      return 0;
   return (ulong)HistoryDealGetInteger(deal, DEAL_POSITION_ID);
  }

void RebindOrphanHedgeLinks()
  {
   CPositionInfo pos;
   for(int i = 0; i < PositionsTotal(); i++)
     {
      if(!pos.SelectByIndex(i))
         continue;
      if(pos.Symbol() != _Symbol || pos.Magic() != (ulong)EXPERT_MAGIC)
         continue;
      if(!IsBotHedgePosition(pos.Ticket(), pos.Comment()))
         continue;

      const ulong parentTicket = ResolveHedgeParentTicket(pos.Ticket(), pos.Comment());
      // Resolve already rejects manual/foreign parents (returns 0).
      if(parentTicket == 0 || !IsOurBotGridParent(parentTicket))
         continue;

      ulong linked = 0;
      if(!GetLinkedHedgeTicket(parentTicket, linked))
         SetLinkedHedgeTicket(parentTicket, pos.Ticket());
     }
  }

void AssignOrphanHedgesToParents()
  {
   CPositionInfo pos;
   for(int i = 0; i < PositionsTotal(); i++)
     {
      if(!pos.SelectByIndex(i))
         continue;
      if(pos.Symbol() != _Symbol || pos.Magic() != (ulong)EXPERT_MAGIC)
         continue;
      if(!IsBotHedgePosition(pos.Ticket(), pos.Comment()))
         continue;

      ulong parentTicket = ResolveHedgeParentTicket(pos.Ticket(), pos.Comment());
      if(parentTicket == 0 || !IsOurBotGridParent(parentTicket))
         continue;

      ulong linked = 0;
      if(GetLinkedHedgeTicket(parentTicket, linked) && linked != pos.Ticket())
         continue;

      if(!GetLinkedHedgeTicket(parentTicket, linked))
         SetLinkedHedgeTicket(parentTicket, pos.Ticket());
     }
  }

void ConsolidateAllDuplicateHedges()
  {
   // R395: OFF. False OVER-hedged counts were closing the only live hedge.
  }

bool GetLinkedHedgeTicket(const ulong parentTicket, ulong &hedgeTicketOut)
  {
   const string key = PositionHedgeLinkKey(parentTicket);
   if(!GlobalVariableCheck(key))
      return false;

   hedgeTicketOut = (ulong)GlobalVariableGet(key);
   CPositionInfo pos;
   if(!pos.SelectByTicket(hedgeTicketOut))
     {
      GlobalVariableDel(key);
      return false;
     }
   return true;
  }

void SetLinkedHedgeTicket(const ulong parentTicket, const ulong hedgeTicket)
  {
   GlobalVariableSet(PositionHedgeLinkKey(parentTicket), (double)hedgeTicket);
  }

void ClearLinkedHedgeTicket(const ulong parentTicket)
  {
   const string key = PositionHedgeLinkKey(parentTicket);
   if(GlobalVariableCheck(key))
      GlobalVariableDel(key);
  }

string PositionHedgeCooldownKey(const ulong parentTicket)
  {
   return StringFormat("TGM_HedgeCD_%I64u_%s_%I64u",
                       (ulong)AccountInfoInteger(ACCOUNT_LOGIN),
                       _Symbol,
                       parentTicket);
  }

void SetHedgeReopenCooldown(const ulong parentTicket)
  {
   ApplyHedgeRecycleCooldown(parentTicket, 0);
  }

void ApplyHedgeRecycleCooldown(const ulong parentTicket, const int lifeSec)
  {
   // 0 = instant re-hedge (parent must not sit alone after $5 loss).
   if(InpHedgeRearmMinSec <= 0)
     {
      const string key = PositionHedgeCooldownKey(parentTicket);
      if(GlobalVariableCheck(key))
         GlobalVariableDel(key);
      return;
     }
   GlobalVariableSet(PositionHedgeCooldownKey(parentTicket),
                     (double)(TimeCurrent() + InpHedgeRearmMinSec));
  }

bool IsHedgeReopenCooldownActive(const ulong parentTicket)
  {
   if(InpHedgeRearmMinSec <= 0)
      return false; // never block re-hedge when instant mode

   const string key = PositionHedgeCooldownKey(parentTicket);
   if(!GlobalVariableCheck(key))
      return false;
   if(TimeCurrent() >= (datetime)GlobalVariableGet(key))
     {
      GlobalVariableDel(key);
      return false;
     }
   return true;
  }

ulong FindOpenHedgeTicketForParent(const ulong parentTicket)
  {
   ulong tickets[];
   if(CollectHedgesForParent(parentTicket, tickets) <= 0)
      return 0;
   return tickets[0];
  }

ulong FindParentForLinkedHedge(const ulong hedgeTicket)
  {
   const string prefix = StringFormat("TGM_Hedge_%I64u_%s_",
                                      (ulong)AccountInfoInteger(ACCOUNT_LOGIN),
                                      _Symbol);
   for(int i = GlobalVariablesTotal() - 1; i >= 0; i--)
     {
      const string name = GlobalVariableName(i);
      if(StringFind(name, prefix) != 0)
         continue;
      if((ulong)GlobalVariableGet(name) != hedgeTicket)
         continue;
      const string parentStr = StringSubstr(name, StringLen(prefix));
      return (ulong)StringToInteger(parentStr);
     }
   return 0;
  }

//--- Collect hedges by comment OR GV link OR opening-deal evidence (comment strip safe).
int CollectHedgesForParent(const ulong parentTicket, ulong &hedgeTickets[])
  {
   ArrayResize(hedgeTickets, 0);
   if(parentTicket == 0)
      return 0;

   const string expected = BuildHedgeComment(parentTicket);
   bool parentAlive = false;
   ENUM_POSITION_TYPE parentType = POSITION_TYPE_BUY;
   CPositionInfo parent;
   if(parent.SelectByTicket(parentTicket) &&
      parent.Symbol() == _Symbol &&
      parent.Magic() == (ulong)EXPERT_MAGIC &&
      !IsBotHedgePosition(parentTicket, parent.Comment()))
     {
      parentAlive = true;
      parentType = parent.PositionType();
     }

   // Path A: explicit link table (survives comment wipe).
   ulong linked = 0;
   if(GetLinkedHedgeTicket(parentTicket, linked) && linked > 0 && linked != parentTicket)
     {
      CPositionInfo h;
      if(h.SelectByTicket(linked) &&
         h.Symbol() == _Symbol &&
         h.Magic() == (ulong)EXPERT_MAGIC)
        {
         if(!parentAlive || h.PositionType() != parentType)
           {
            ArrayResize(hedgeTickets, 1);
            hedgeTickets[0] = linked;
           }
        }
     }

   CPositionInfo pos;
   for(int i = 0; i < PositionsTotal(); i++)
     {
      if(!pos.SelectByIndex(i))
         continue;
      if(pos.Symbol() != _Symbol || pos.Magic() != (ulong)EXPERT_MAGIC)
         continue;
      if(pos.Ticket() == parentTicket)
         continue;

      const ulong ht = pos.Ticket();
      bool isHedge = IsHedgePositionComment(pos.Comment()) ||
                     IsTrackedHedgeTicket(ht) ||
                     HasHedgeOpeningEvidence(ht);
      if(!isHedge)
         continue;

      const ulong resolved = ResolveHedgeParentTicket(ht, pos.Comment());
      if(resolved != parentTicket &&
         pos.Comment() != expected &&
         ParseHedgeParentTicket(pos.Comment()) != parentTicket)
         continue;

      if(parentAlive && pos.PositionType() == parentType)
         continue;

      bool dup = false;
      for(int d = 0; d < ArraySize(hedgeTickets); d++)
        {
         if(hedgeTickets[d] == ht)
           {
            dup = true;
            break;
           }
        }
      if(!dup)
        {
         const int n = ArraySize(hedgeTickets);
         ArrayResize(hedgeTickets, n + 1);
         hedgeTickets[n] = ht;
        }
     }

   return ArraySize(hedgeTickets);
  }

int CountHedgesForParent(const ulong parentTicket)
  {
   ulong tickets[];
   return CollectHedgesForParent(parentTicket, tickets);
  }

//--- Sum of live hedge volumes linked to this parent (must equal parent lot for 1:1).
double GetHedgedVolumeForParent(const ulong parentTicket)
  {
   ulong hedges[];
   const int n = CollectHedgesForParent(parentTicket, hedges);
   double vol = 0.0;
   CPositionInfo h;
   for(int i = 0; i < n; i++)
     {
      if(!h.SelectByTicket(hedges[i]))
         continue;
      vol += h.Volume();
     }
   return vol;
  }

double GetHedgeVolumeShortfall(const ulong parentTicket)
  {
   if(!IsOurBotGridParent(parentTicket))
      return 0.0; // manual/foreign → zero shortfall → never hedge
   CPositionInfo parent;
   if(!parent.SelectByTicket(parentTicket))
      return 0.0;
   const double need = parent.Volume() - GetHedgedVolumeForParent(parentTicket);
   const double vmin = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   if(need < vmin - 1e-8)
      return 0.0;
   return NormalizeVolume(need);
  }

bool HasFullHedgeCoverage(const ulong parentTicket)
  {
   return (GetHedgeVolumeShortfall(parentTicket) <= 0.0);
  }

void ConsolidateDuplicateHedgesForParent(const ulong parentTicket)
  {
   // R395: never close a live hedge as "duplicate". One comment-matched hedge is the system.
  }

double GetTicketLossPoints(const ulong ticket, const double point)
  {
   const double profitPts = GetTicketProfitPoints(ticket, point);
   return (profitPts < 0.0) ? -profitPts : 0.0;
  }

//+------------------------------------------------------------------+
//| PRICE-BASED ($) PRIMITIVES                                       |
//| All distance/tracking is the raw absolute price difference.      |
//| On XAUUSD a 1.00 price move = $1.00, so no point/pip conversion. |
//+------------------------------------------------------------------+

//--- Signed open profit of a position expressed as a price difference ($).
//    BUY  -> Bid - Open ; SELL -> Open - Ask. Positive = in profit.
double GetPositionProfitUSD(const ulong ticket)
  {
   CPositionInfo p;
   if(!p.SelectByTicket(ticket))
      return 0.0;
   const double open = p.PriceOpen();
   if(p.PositionType() == POSITION_TYPE_BUY)
      return SymbolInfoDouble(_Symbol, SYMBOL_BID) - open;
   if(p.PositionType() == POSITION_TYPE_SELL)
      return open - SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   return 0.0;
  }

//--- Absolute adverse move of a position expressed as a price difference ($).
double GetPositionLossUSD(const ulong ticket)
  {
   const double pl = GetPositionProfitUSD(ticket);
   return (pl < 0.0) ? -pl : 0.0;
  }

//--- Current spread as a price value (used as the break-even broker buffer).
double GetSymbolSpreadPrice()
  {
   const double s = SymbolInfoDouble(_Symbol, SYMBOL_ASK) - SymbolInfoDouble(_Symbol, SYMBOL_BID);
   return (s > 0.0) ? s : 0.0;
  }

//--- Broker minimum stop distance as a price value (stops + freeze level).
double GetSymbolStopsPrice()
  {
   const double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   if(point <= 0.0)
      return 0.0;
   const long stopsLevel  = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   const long freezeLevel = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_FREEZE_LEVEL);
   const long level = (stopsLevel > freezeLevel ? stopsLevel : freezeLevel);
   return (double)level * point;
  }

//--- Effective hedge SL distance. 0 = sticky hedge (no death SL / no burn loop). Mode A only.
double GetEffectiveHedgeStopLossUSD()
  {
   return (InpHedgeStopLossUSD > 0.0) ? InpHedgeStopLossUSD : 0.0;
  }

//--- Effective $ trail gap. Uses InpTrailingStopUSD (default $3); never below broker stops.
double GetEffectiveTrailGapUSD()
  {
   const double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   const double minGap = GetSymbolStopsPrice() + ((point > 0.0) ? point : 0.001);
   const double want = (InpTrailingStopUSD > 0.0) ? InpTrailingStopUSD : 3.0;
   return MathMax(want, minGap);
  }

//--- True when a proposed SL is far enough from the current price for the broker.
bool IsBrokerStopDistanceOK(const ENUM_POSITION_TYPE posType, const double refPrice, const double slPrice)
  {
   const double stops = GetSymbolStopsPrice();
   const double dist  = (posType == POSITION_TYPE_BUY) ? (refPrice - slPrice) : (slPrice - refPrice);
   return (dist >= stops - 1e-9);
  }

//--- HasHedge(): true only while an OPEN hedge for this parent exists in the
//    terminal. As soon as the hedge SL hits and the position is removed, this
//    returns false, allowing the recurrent engine to open a fresh hedge.
//--- Return the live hedge ticket for a parent (first match; use CountHedgesForParent).
ulong GetOpenHedgeTicketForParent(const ulong parentTicket)
  {
   ulong hedges[];
   if(CollectHedgesForParent(parentTicket, hedges) <= 0)
      return 0;
   return hedges[0];
  }

bool HasHedge(const ulong parentTicket)
  {
   return (CountHedgesForParent(parentTicket) > 0);
  }

string PositionHedgeRearmKey(const ulong parentTicket)
  {
   return StringFormat("TGM_HedgeRearm_%I64u_%s_%I64u",
                       (ulong)AccountInfoInteger(ACCOUNT_LOGIN),
                       _Symbol,
                       parentTicket);
  }

string PositionHedgeTriggerReadyKey(const ulong parentTicket)
  {
   return StringFormat("TGM_HedgeTrigReady_%I64u_%s_%I64u",
                       (ulong)AccountInfoInteger(ACCOUNT_LOGIN),
                       _Symbol,
                       parentTicket);
  }

string PositionHedgeLiveKey(const ulong parentTicket)
  {
   return StringFormat("TGM_HedgeLive_%I64u_%s_%I64u",
                       (ulong)AccountInfoInteger(ACCOUNT_LOGIN),
                       _Symbol,
                       parentTicket);
  }

double GetHedgeRearmState(const ulong parentTicket)
  {
   const string key = PositionHedgeRearmKey(parentTicket);
   return GlobalVariableCheck(key) ? GlobalVariableGet(key) : 0.0;
  }

string PositionHedgeOpenTimeKey(const ulong parentTicket)
  {
   return StringFormat("TGM_HedgeOpen_%I64u_%s_%I64u",
                       (ulong)AccountInfoInteger(ACCOUNT_LOGIN),
                       _Symbol,
                       parentTicket);
  }

string PositionHedgeBEArmedKey(const ulong hedgeTicket)
  {
   return StringFormat("TGM_HBE_%I64u_%s_%I64u",
                       (ulong)AccountInfoInteger(ACCOUNT_LOGIN),
                       _Symbol,
                       hedgeTicket);
  }

bool IsHedgeBreakEvenArmed(const ulong hedgeTicket)
  {
   return GlobalVariableCheck(PositionHedgeBEArmedKey(hedgeTicket));
  }

void MarkHedgeBreakEvenArmed(const ulong hedgeTicket)
  {
   GlobalVariableSet(PositionHedgeBEArmedKey(hedgeTicket), 1.0);
  }

void ClearHedgeBreakEvenArmed(const ulong hedgeTicket)
  {
   const string key = PositionHedgeBEArmedKey(hedgeTicket);
   if(GlobalVariableCheck(key))
      GlobalVariableDel(key);
  }

string PositionHedgeReturnArmedKey(const ulong hedgeTicket)
  {
   return StringFormat("TGM_HRet_%I64u_%s_%I64u",
                       (ulong)AccountInfoInteger(ACCOUNT_LOGIN),
                       _Symbol,
                       hedgeTicket);
  }

bool IsHedgeReturnArmed(const ulong hedgeTicket)
  {
   return GlobalVariableCheck(PositionHedgeReturnArmedKey(hedgeTicket));
  }

void MarkHedgeReturnArmed(const ulong hedgeTicket)
  {
   GlobalVariableSet(PositionHedgeReturnArmedKey(hedgeTicket), 1.0);
  }

void ClearHedgeReturnArmed(const ulong hedgeTicket)
  {
   const string key = PositionHedgeReturnArmedKey(hedgeTicket);
   if(GlobalVariableCheck(key))
      GlobalVariableDel(key);
  }

//--- True when price has come back to the hedge open price (entry-return).
bool IsPriceBackAtHedgeEntry(const ulong hedgeTicket)
  {
   CPositionInfo pos;
   if(!pos.SelectByTicket(hedgeTicket))
      return false;

   const double open = pos.PriceOpen();
   const double tol  = MathMax(GetSymbolSpreadPrice(), SymbolInfoDouble(_Symbol, SYMBOL_POINT) * 10.0);

   if(pos.PositionType() == POSITION_TYPE_BUY)
     {
      // BUY hedge: price returned down to entry.
      return (SymbolInfoDouble(_Symbol, SYMBOL_BID) <= open + tol);
     }
   // SELL hedge: price returned up to entry.
   return (SymbolInfoDouble(_Symbol, SYMBOL_ASK) >= open - tol);
  }

void MarkHedgeOpenTime(const ulong parentTicket)
  {
   GlobalVariableSet(PositionHedgeOpenTimeKey(parentTicket), (double)TimeCurrent());
  }

int GetHedgeLifeSeconds(const ulong parentTicket)
  {
   const string key = PositionHedgeOpenTimeKey(parentTicket);
   if(!GlobalVariableCheck(key))
      return 0;
   const datetime opened = (datetime)GlobalVariableGet(key);
   if(opened <= 0)
      return 0;
   return (int)(TimeCurrent() - opened);
  }

void ClearHedgeOpenTime(const ulong parentTicket)
  {
   const string key = PositionHedgeOpenTimeKey(parentTicket);
   if(GlobalVariableCheck(key))
      GlobalVariableDel(key);
  }

string PositionHedgeBlockLogKey(const ulong parentTicket)
  {
   return StringFormat("TGM_HedgeBlk_%I64u_%s_%I64u",
                       (ulong)AccountInfoInteger(ACCOUNT_LOGIN),
                       _Symbol,
                       parentTicket);
  }

void LogHedgeBlockOnce(const ulong parentTicket, const string reason)
  {
   const string key = PositionHedgeBlockLogKey(parentTicket);
   const datetime now = TimeCurrent();
   if(GlobalVariableCheck(key) && (now - (datetime)GlobalVariableGet(key)) < 60)
      return;
   GlobalVariableSet(key, (double)now);
   PrintFormat("TGM [HEDGE]: Parent #%I64u blocked - %s", parentTicket, reason);
  }

void MarkHedgeRearmLocked(const ulong parentTicket)
  {
   ClearHedgeOpenTime(parentTicket);
   // No LOCK / no rapid-death pause — clear state so next tick can re-hedge if loss >= trigger.
   ClearHedgeRearmState(parentTicket);
   SetHedgeTriggerReady(parentTicket, true);
   ApplyHedgeRecycleCooldown(parentTicket, 0);
  }

bool IsHedgeRearmLocked(const ulong parentTicket)
  {
   return (GetHedgeRearmState(parentTicket) == TGM_HEDGE_REARM_LOCKED);
  }

bool IsHedgeRearmReady(const ulong parentTicket)
  {
   return (GetHedgeRearmState(parentTicket) == TGM_HEDGE_REARM_READY);
  }

bool IsHedgeRearmArmed(const ulong parentTicket)
  {
   return (GetHedgeRearmState(parentTicket) == TGM_HEDGE_REARM_ARMED);
  }

void ClearHedgeRearmState(const ulong parentTicket)
  {
   const string key = PositionHedgeRearmKey(parentTicket);
   if(GlobalVariableCheck(key))
      GlobalVariableDel(key);
  }

bool IsHedgeTriggerReady(const ulong parentTicket)
  {
   return (GlobalVariableCheck(PositionHedgeTriggerReadyKey(parentTicket)) &&
           GlobalVariableGet(PositionHedgeTriggerReadyKey(parentTicket)) > 0.5);
  }

void SetHedgeTriggerReady(const ulong parentTicket, const bool ready)
  {
   GlobalVariableSet(PositionHedgeTriggerReadyKey(parentTicket), ready ? 1.0 : 0.0);
  }

void SeedHedgeMonitorForParent(const ulong parentTicket)
  {
   if(parentTicket == 0)
      return;

   if(GlobalVariableCheck(PositionHedgeTriggerReadyKey(parentTicket)))
      return;

   CPositionInfo pos;
   if(!pos.SelectByTicket(parentTicket))
      return;

   const double parentLoss = GetPositionLossUSD(parentTicket);
   // Allow hedge whenever loss already >= trigger (recurrent zone), including first sight.
   SetHedgeTriggerReady(parentTicket, true);
   ClearHedgeRearmState(parentTicket);
   if(parentLoss >= GetActiveHedgeTriggerUSD())
     {
      PrintFormat("TGM [HEDGE]: Parent #%I64u at loss $%.2f >= $%.2f - hedge armed.",
                  parentTicket, parentLoss, GetActiveHedgeTriggerUSD());
     }
  }

void HealStaleHedgeLock(const ulong parentTicket)
  {
   if(!IsHedgeRearmLocked(parentTicket))
      return;
   if(IsHedgeReopenCooldownActive(parentTicket))
      return;

   // Clear any legacy LOCK state — recurrent re-hedge uses cooldown + loss>=trigger only.
   ClearHedgeRearmState(parentTicket);
   SetHedgeTriggerReady(parentTicket, true);
   PrintFormat("TGM [HEDGE]: Parent #%I64u stale LOCK cleared - recurrent hedge enabled.", parentTicket);
  }

void TryUnlockHedgeAfterRecovery(const ulong parentTicket)
  {
   if(!IsHedgeRearmLocked(parentTicket))
      return;
   if(IsHedgeChopFrozen(parentTicket))
      return;
   if(IsHedgeReopenCooldownActive(parentTicket))
      return;

   const double parentLoss = GetPositionLossUSD(parentTicket);
   const double clearLevel = MathMin(GetActiveHedgeTriggerUSD(), InpHedgeRearmClearUSD);
   if(parentLoss >= clearLevel)
      return;

   ClearHedgeRearmState(parentTicket);
   SetHedgeTriggerReady(parentTicket, true);
   PrintFormat("TGM [HEDGE]: Parent #%I64u recovered to loss $%.2f < $%.2f - ready for next live cross.",
               parentTicket, parentLoss, clearLevel);
  }

void TryPromoteHedgeRearmToReady(const ulong parentTicket)
  {
   if(!IsHedgeRearmLocked(parentTicket))
      return;
   if(IsHedgeChopFrozen(parentTicket))
      return;
   if(IsHedgeReopenCooldownActive(parentTicket))
      return;

   const double parentLoss = GetPositionLossUSD(parentTicket);

   // Re-arm only after the parent actually recovers back below the hedge trigger.
   if(parentLoss >= GetActiveHedgeTriggerUSD())
      return;

   GlobalVariableSet(PositionHedgeRearmKey(parentTicket), TGM_HEDGE_REARM_READY);
    SetHedgeTriggerReady(parentTicket, true);
   PrintFormat("TGM [HEDGE]: Parent #%I64u loss $%.2f < $%.2f - hedge re-arm READY.",
               parentTicket, parentLoss, GetActiveHedgeTriggerUSD());
  }

void TryPromoteHedgeRearmToArmed(const ulong parentTicket)
  {
   if(!IsHedgeRearmReady(parentTicket))
      return;
   if(IsHedgeChopFrozen(parentTicket))
      return;
   if(!IsHedgeTriggerReady(parentTicket))
      return;

   const double parentLoss = GetPositionLossUSD(parentTicket);
   if(parentLoss < GetActiveHedgeTriggerUSD())
      return;

   GlobalVariableSet(PositionHedgeRearmKey(parentTicket), TGM_HEDGE_REARM_ARMED);
   PrintFormat("TGM [HEDGE]: Parent #%I64u loss $%.2f >= $%.2f - hedge re-arm ARMED.",
               parentTicket, parentLoss, GetActiveHedgeTriggerUSD());
  }

bool CanOpenHedgeForParent(const ulong parentTicket)
  {
   // JAIL: never hedge manual / foreign trades.
   if(!IsOurBotGridParent(parentTicket))
     {
      LogHedgeBlockOnce(parentTicket, "FOREIGN/MANUAL trade — EA is blind (not our magic)");
      return false;
     }

   // Allow open/top-up whenever coverage is incomplete (not merely "any hedge exists").
   const double shortfall = GetHedgeVolumeShortfall(parentTicket);
   if(shortfall <= 0.0)
     {
      LogHedgeBlockOnce(parentTicket, "hedge fully covers parent lots (1:1)");
      return false;
     }

   const double parentLossPips = GetPositionLossPips(parentTicket);
   if(parentLossPips + 1e-9 < TGM_LOSS_HEDGE_PIPS)
     {
      LogHedgeBlockOnce(parentTicket,
                        StringFormat("loss %.1fpip < trigger %.0fpip",
                                     parentLossPips, TGM_LOSS_HEDGE_PIPS));
      return false;
     }

   // R406 HARD RULE: naked parent still in loss => ALWAYS allow hedge.
   // No cooldown / bleed / chop / bar-lock may block the ~30pip net method.
   if(CountHedgesForParent(parentTicket) <= 0)
      return true;

   if(IsHedgeReopenCooldownActive(parentTicket))
     {
      LogHedgeBlockOnce(parentTicket, "hedge cooldown (coverage incomplete — will retry)");
      return false;
     }

   return true;
  }

void MarkHedgeLive(const ulong parentTicket)
  {
   GlobalVariableSet(PositionHedgeLiveKey(parentTicket), 1.0);
  }

void ClearHedgeLive(const ulong parentTicket)
  {
   const string key = PositionHedgeLiveKey(parentTicket);
   if(GlobalVariableCheck(key))
      GlobalVariableDel(key);
  }

bool WasHedgeLive(const ulong parentTicket)
  {
   return GlobalVariableCheck(PositionHedgeLiveKey(parentTicket));
  }

//+------------------------------------------------------------------+
//| Smart chop-freeze: detect $1 whipsaw loops and pause hedge opens |
//| until price breaks out of the sideways zone.                     |
//+------------------------------------------------------------------+
string HedgeChopNextIdxKey(const ulong parentTicket)
  {
   return StringFormat("TGM_HedgeChopIdx_%I64u_%s_%I64u",
                       (ulong)AccountInfoInteger(ACCOUNT_LOGIN), _Symbol, parentTicket);
  }

string HedgeChopDeathTimeKey(const ulong parentTicket, const int slot)
  {
   return StringFormat("TGM_HedgeChopT_%I64u_%s_%I64u_%d",
                       (ulong)AccountInfoInteger(ACCOUNT_LOGIN), _Symbol, parentTicket, slot);
  }

string HedgeChopDeathPriceKey(const ulong parentTicket, const int slot)
  {
   return StringFormat("TGM_HedgeChopP_%I64u_%s_%I64u_%d",
                       (ulong)AccountInfoInteger(ACCOUNT_LOGIN), _Symbol, parentTicket, slot);
  }

string HedgeChopDeathRapidKey(const ulong parentTicket, const int slot)
  {
   return StringFormat("TGM_HedgeChopR_%I64u_%s_%I64u_%d",
                       (ulong)AccountInfoInteger(ACCOUNT_LOGIN), _Symbol, parentTicket, slot);
  }

string HedgeChopFreezeStartKey(const ulong parentTicket)
  {
   return StringFormat("TGM_HedgeChopFrz_%I64u_%s_%I64u",
                       (ulong)AccountInfoInteger(ACCOUNT_LOGIN), _Symbol, parentTicket);
  }

string HedgeChopCenterKey(const ulong parentTicket)
  {
   return StringFormat("TGM_HedgeChopCtr_%I64u_%s_%I64u",
                       (ulong)AccountInfoInteger(ACCOUNT_LOGIN), _Symbol, parentTicket);
  }

string HedgeChopHalfRangeKey(const ulong parentTicket)
  {
   return StringFormat("TGM_HedgeChopRad_%I64u_%s_%I64u",
                       (ulong)AccountInfoInteger(ACCOUNT_LOGIN), _Symbol, parentTicket);
  }

bool IsHedgeChopFreezeActive(const ulong parentTicket)
  {
   return GlobalVariableCheck(HedgeChopFreezeStartKey(parentTicket));
  }

void ClearHedgeChopState(const ulong parentTicket)
  {
   const string frzKey = HedgeChopFreezeStartKey(parentTicket);
   const string ctrKey = HedgeChopCenterKey(parentTicket);
   const string radKey = HedgeChopHalfRangeKey(parentTicket);
   const string idxKey = HedgeChopNextIdxKey(parentTicket);
   if(GlobalVariableCheck(frzKey)) GlobalVariableDel(frzKey);
   if(GlobalVariableCheck(ctrKey)) GlobalVariableDel(ctrKey);
   if(GlobalVariableCheck(radKey)) GlobalVariableDel(radKey);
   if(GlobalVariableCheck(idxKey)) GlobalVariableDel(idxKey);
   for(int s = 0; s < TGM_HEDGE_CHOP_MAX_EVENTS; s++)
     {
      const string tKey = HedgeChopDeathTimeKey(parentTicket, s);
      const string pKey = HedgeChopDeathPriceKey(parentTicket, s);
      const string rKey = HedgeChopDeathRapidKey(parentTicket, s);
      if(GlobalVariableCheck(tKey)) GlobalVariableDel(tKey);
      if(GlobalVariableCheck(pKey)) GlobalVariableDel(pKey);
      if(GlobalVariableCheck(rKey)) GlobalVariableDel(rKey);
     }
  }

void ActivateHedgeChopFreeze(const ulong parentTicket, const double center, const double halfRange)
  {
   if(IsHedgeChopFreezeActive(parentTicket))
      return;

   const int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   GlobalVariableSet(HedgeChopFreezeStartKey(parentTicket), (double)TimeCurrent());
   GlobalVariableSet(HedgeChopCenterKey(parentTicket), center);
   GlobalVariableSet(HedgeChopHalfRangeKey(parentTicket), halfRange);
   ClearHedgeRearmState(parentTicket);

   PrintFormat("TGM [HEDGE-CHOP]: Parent #%I64u FROZEN | zone %.*f +/- $%.2f | breakout need $%.2f | min %d sec.",
               parentTicket, digits, center, halfRange, InpHedgeChopBreakoutUSD, InpHedgeChopFreezeMinSec);
  }

void TryReleaseHedgeChopFreeze(const ulong parentTicket)
  {
   if(!IsHedgeChopFreezeActive(parentTicket))
      return;

   const datetime freezeStart = (datetime)GlobalVariableGet(HedgeChopFreezeStartKey(parentTicket));
   const int freezeAge = (int)(TimeCurrent() - freezeStart);
   if(freezeAge < InpHedgeChopFreezeMinSec)
      return;

   const double center    = GlobalVariableGet(HedgeChopCenterKey(parentTicket));
   const double halfRange = GlobalVariableGet(HedgeChopHalfRangeKey(parentTicket));
   const double bid       = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   const double dist      = MathAbs(bid - center);
   const double breakout  = halfRange + InpHedgeChopBreakoutUSD;

   if(dist <= breakout)
      return;

   const int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   PrintFormat("TGM [HEDGE-CHOP]: Parent #%I64u UNFROZEN | price %.*f left chop zone (center %.*f, moved $%.2f).",
               parentTicket, digits, bid, digits, center, dist);
   ClearHedgeChopState(parentTicket);
  }

bool IsHedgeChopFrozen(const ulong parentTicket)
  {
   if(!InpHedgeChopFreezeEnable)
      return false;

   TryReleaseHedgeChopFreeze(parentTicket);
   return IsHedgeChopFreezeActive(parentTicket);
  }

void EvaluateHedgeChopPattern(const ulong parentTicket)
  {
   if(!InpHedgeChopFreezeEnable || IsHedgeChopFreezeActive(parentTicket))
      return;

   const datetime now      = TimeCurrent();
   const int      windowSec = (InpHedgeChopWindowSec < 60) ? 60 : InpHedgeChopWindowSec;
   const int      minDeaths = (InpHedgeChopMinDeaths < 2) ? 2 : InpHedgeChopMinDeaths;
   const double   chopBand  = (InpHedgeChopRangeUSD < 0.50) ? 0.50 : InpHedgeChopRangeUSD;

   int    deathCount  = 0;
   int    rapidCount  = 0;
   double priceMin    = 0.0;
   double priceMax    = 0.0;
   bool   havePrice   = false;

   for(int s = 0; s < TGM_HEDGE_CHOP_MAX_EVENTS; s++)
     {
      const string tKey = HedgeChopDeathTimeKey(parentTicket, s);
      const string pKey = HedgeChopDeathPriceKey(parentTicket, s);
      if(!GlobalVariableCheck(tKey) || !GlobalVariableCheck(pKey))
         continue;

      const datetime evtTime = (datetime)GlobalVariableGet(tKey);
      if(evtTime <= 0 || (now - evtTime) > windowSec)
         continue;

      const double evtPrice = GlobalVariableGet(pKey);
      deathCount++;
      if(!havePrice)
        {
         priceMin = evtPrice;
         priceMax = evtPrice;
         havePrice = true;
        }
      else
        {
         if(evtPrice < priceMin) priceMin = evtPrice;
         if(evtPrice > priceMax) priceMax = evtPrice;
        }

      const string rKey = HedgeChopDeathRapidKey(parentTicket, s);
      if(GlobalVariableCheck(rKey) && GlobalVariableGet(rKey) > 0.5)
         rapidCount++;
     }

   if(deathCount < minDeaths || !havePrice)
      return;

   const double band = priceMax - priceMin;
   if(band > chopBand)
      return;

   if(rapidCount < 2 && deathCount < minDeaths + 1)
      return;

   const double center    = (priceMin + priceMax) * 0.5;
   const double halfRange = MathMax(chopBand * 0.5, band * 0.5);
   ActivateHedgeChopFreeze(parentTicket, center, halfRange);
  }

void RecordHedgeChopDeath(const ulong parentTicket, const double price, const bool rapid)
  {
   if(!InpHedgeChopFreezeEnable)
      return;

   const string idxKey = HedgeChopNextIdxKey(parentTicket);
   int slot = GlobalVariableCheck(idxKey) ? (int)GlobalVariableGet(idxKey) : 0;
   if(slot < 0 || slot >= TGM_HEDGE_CHOP_MAX_EVENTS)
      slot = 0;

   GlobalVariableSet(HedgeChopDeathTimeKey(parentTicket, slot), (double)TimeCurrent());
   GlobalVariableSet(HedgeChopDeathPriceKey(parentTicket, slot), price);
   GlobalVariableSet(HedgeChopDeathRapidKey(parentTicket, slot), rapid ? 1.0 : 0.0);
   slot = (slot + 1) % TGM_HEDGE_CHOP_MAX_EVENTS;
   GlobalVariableSet(idxKey, (double)slot);

   EvaluateHedgeChopPattern(parentTicket);
  }

//--- Profit-engine "armed" latch: set once +50pip partial+BE runner transition completes.
string PositionProfitArmedKey(const ulong ticket)
  {
   return StringFormat("TGM_Armed_%I64u_%s_%I64u",
                       (ulong)AccountInfoInteger(ACCOUNT_LOGIN),
                       _Symbol,
                       ticket);
  }

string PositionPartialClosedBeRunnerKey(const ulong ticket)
  {
   return StringFormat("TGM_P28A_Runner_%I64u_%s_%I64u",
                       (ulong)AccountInfoInteger(ACCOUNT_LOGIN),
                       _Symbol,
                       ticket);
  }

bool IsProfitEngineArmed(const ulong ticket)
  {
   return GlobalVariableCheck(PositionProfitArmedKey(ticket)) || IsPartialClosedBeRunner(ticket);
  }

void MarkProfitEngineArmed(const ulong ticket)
  {
   GlobalVariableSet(PositionProfitArmedKey(ticket), (double)TimeCurrent());
  }

bool IsPartialClosedBeRunner(const ulong ticket)
  {
   return (GlobalVariableCheck(PositionPartialClosedBeRunnerKey(ticket)) &&
           GlobalVariableGet(PositionPartialClosedBeRunnerKey(ticket)) > 0.5);
  }

void MarkPartialClosedBeRunner(const ulong ticket)
  {
   if(ticket == 0)
      return;
   GlobalVariableSet(PositionPartialClosedBeRunnerKey(ticket), 1.0);
   MarkProfitEngineArmed(ticket);
   LogPhase28A("RUNNER_ACTIVE", ticket, "PARTIAL_CLOSED_BE_RUNNER");
  }

void LogPhase28A(const string eventName, const ulong ticket, const string detail)
  {
   PrintFormat("TGM [P28A]: %s | ticket=%I64u | %s", eventName, ticket, detail);
  }

double GetPositionProfitPips(const ulong ticket)
  {
   const double pip = Phase17_GetPipSize();
   if(pip <= 0.0)
      return 0.0;
   CPositionInfo pos;
   if(!pos.SelectByTicket(ticket))
      return 0.0;
   const double open = pos.PriceOpen();
   if(pos.PositionType() == POSITION_TYPE_BUY)
      return (SymbolInfoDouble(_Symbol, SYMBOL_BID) - open) / pip;
   if(pos.PositionType() == POSITION_TYPE_SELL)
      return (open - SymbolInfoDouble(_Symbol, SYMBOL_ASK)) / pip;
   return 0.0;
  }

bool StripPositionTakeProfit(const ulong ticket, const string reason)
  {
   CPositionInfo pos;
   if(!pos.SelectByTicket(ticket))
      return false;
   if(pos.TakeProfit() <= 0.0)
      return true;
   const double sl = pos.StopLoss();
   if(!SafePositionModify(ticket, sl, 0.0, "PositionModify(STRIP-ATR-TP)"))
      return false;
   if(!pos.SelectByTicket(ticket))
      return false;
   const bool ok = (pos.TakeProfit() <= 0.0);
   if(ok)
      LogPhase28A("ATR_TP_REMOVED", ticket, reason);
   return ok;
  }

//--- Loss method starts: remove pending/shared broker SL — hedge owns the risk now.
string ParentPendingSLKey(const ulong ticket)
  {
   return StringFormat("TGM_PendSL_%I64u_%s_%I64u",
                       (ulong)AccountInfoInteger(ACCOUNT_LOGIN), _Symbol, ticket);
  }

void RememberParentPendingSL(const ulong ticket)
  {
   CPositionInfo pos;
   if(!pos.SelectByTicket(ticket))
      return;
   if(pos.StopLoss() <= 0.0)
      return;
   const string key = ParentPendingSLKey(ticket);
   if(!GlobalVariableCheck(key))
      GlobalVariableSet(key, pos.StopLoss());
  }

bool RestoreParentPendingSL(const ulong ticket, const string reason)
  {
   CPositionInfo pos;
   if(!pos.SelectByTicket(ticket))
      return false;
   if(pos.StopLoss() > 0.0)
      return true;

   const string key = ParentPendingSLKey(ticket);
   if(!GlobalVariableCheck(key))
      return false;
   const double sl = GlobalVariableGet(key);
   if(sl <= 0.0)
      return false;

   const ENUM_POSITION_TYPE posType = pos.PositionType();
   const double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   const double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   const double ref = (posType == POSITION_TYPE_BUY) ? bid : ask;
   if(!IsBrokerStopDistanceOK(posType, ref, sl))
     {
      PrintFormat("TGM [R403]: Parent #%I64u cannot restore pending SL %.5f (%s) — price already through. Re-hedge required.",
                  ticket, sl, reason);
      return false;
     }

   const double tp = pos.TakeProfit();
   if(!SafePositionModify(ticket, sl, tp, "PositionModify(RESTORE-PARENT-SL)"))
      return false;
   PrintFormat("TGM [R403]: Parent #%I64u pending SL restored to %.5f (%s).", ticket, sl, reason);
   return true;
  }

bool StripPositionStopLoss(const ulong ticket, const string reason)
  {
   // R404 hard rule: pending/shared SL is NEVER removed. It stays until broker hit.
   PrintFormat("TGM [R404]: Strip parent SL BLOCKED #%I64u (%s) — pending SL stays until hit.",
               ticket, reason);
   return false;
  }

bool ApplyBreakEvenSlNoTp(const ulong ticket, const double beSL, const string reason)
  {
   LogPhase28A("BE_REQUEST", ticket, StringFormat("beSL=%.5f | %s", beSL, reason));
   CPositionInfo pos;
   if(!pos.SelectByTicket(ticket))
      return false;
   if(!SafePositionModify(ticket, beSL, 0.0, reason))
      return false;
   if(!pos.SelectByTicket(ticket))
      return false;
   const int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   const double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   const bool beOk = (pos.StopLoss() > 0.0 && MathAbs(pos.StopLoss() - beSL) <= MathMax(point * 2.0, 0.0));
   const bool tpOk = (pos.TakeProfit() <= 0.0);
   if(beOk && tpOk)
     {
      LogPhase28A("BE_CONFIRMED", ticket,
                  StringFormat("SL=%.5f TP=0 remaining=%.2f", pos.StopLoss(), pos.Volume()));
      return true;
     }
   LogPhase28A("BE_REQUEST", ticket,
               StringFormat("VERIFY_FAIL SL=%.5f TP=%.5f wantBE=%.5f",
                            pos.StopLoss(), pos.TakeProfit(), beSL));
   return false;
  }

//+------------------------------------------------------------------+
//| Consolidated Account Protection Engine                           |
//+------------------------------------------------------------------+
int CountGridPositions()
  {
   CPositionInfo pos;
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(!pos.SelectByIndex(i))
         continue;
      if(pos.Symbol() != _Symbol || pos.Magic() != (ulong)EXPERT_MAGIC)
         continue;
      if(IsBotHedgePosition(pos.Ticket(), pos.Comment()))
         continue;
      count++;
     }
   return count;
  }

int CountHedgePositions()
  {
   CPositionInfo pos;
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(!pos.SelectByIndex(i))
         continue;
      if(pos.Symbol() != _Symbol || pos.Magic() != (ulong)EXPERT_MAGIC)
         continue;
      if(!IsBotHedgePosition(pos.Ticket(), pos.Comment()))
         continue;
      count++;
     }
   return count;
  }

//--- Combined floating P/L of ONLY this EA's own positions (magic == EXPERT_MAGIC).
//    Manual / foreign trades never counted — protection & DD governor stay bot-only.
double GetBotFloatingPL()
  {
   CPositionInfo pos;
   double pl = 0.0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(!pos.SelectByIndex(i))
         continue;
      if(pos.Symbol() != _Symbol || pos.Magic() != (ulong)EXPERT_MAGIC)
         continue;
      pl += pos.Profit() + pos.Swap() + pos.Commission();
     }
   return pl;
  }

double GetFloatingDrawdownPercent()
  {
   const double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   if(balance <= 0.0)
      return 0.0;
   const double botPL = GetBotFloatingPL();          // EA-only, ignores manual trades
   const double loss  = (botPL < 0.0) ? -botPL : 0.0;
   return (loss > 0.0) ? (loss / balance * 100.0) : 0.0;
  }

void LogProtectionAlert(const string message)
  {
   const datetime now = TimeCurrent();
   if((now - g_lastProtectionAlertTime) < TGM_PROTECTION_ALERT_INTERVAL_SEC)
      return;
   g_lastProtectionAlertTime = now;
   Print("TGM [PROTECTION ALERT]: ", message);
  }

void MonitorAccountDrawdownProtection()
  {
   if(!Enable_Account_Protection)
     {
      g_accountProtectionActive = false;
      g_accountProtectionReason = "";
      return;
     }

   const double ddPct = GetFloatingDrawdownPercent();
   if(ddPct >= Max_Floating_DD_Percent)
     {
      g_accountProtectionActive = true;
      g_accountProtectionReason = StringFormat("Bot floating DD %.1f%% >= limit %.1f%% - same-H4 grid BLOCKED (manual ignored)",
                                               ddPct, Max_Floating_DD_Percent);
      LogProtectionAlert(g_accountProtectionReason);
     }
   else
     {
      g_accountProtectionActive = false;
      g_accountProtectionReason = "";
     }
  }

//--- Method: with hedge open, parent may stay forever — do NOT force-close (no kill/survival wash).
void EnforceSurvivalBeforeStopOut()
  {
  }

bool IsResearchH4RangeAllowed(string &reasonOut)
  {
#ifdef TGM_R380_FORCE_NO_H4_RANGE_FILTER
   reasonOut = "";
   return true; // R416: no 200pip lock — any H4 range allowed
#else
   reasonOut = "";
   const double pip = Phase17_GetPipSize();
   const double h = iHigh(_Symbol, PERIOD_H4, 1);
   const double l = iLow(_Symbol, PERIOD_H4, 1);
   if(pip <= 0.0 || h <= l)
     {
      reasonOut = "H4_RANGE_INVALID";
      return false;
     }
   const double rangePips = (h - l) / pip;
   const double maxPips = Phase17_EffectiveMaxH4RangePips();
   if(rangePips > maxPips + 1e-9)
     {
      reasonOut = StringFormat("H4_RANGE_REJECTED pips=%.1f>%.1f (R382)",
                               rangePips, maxPips);
      return false;
     }
   return true;
#endif
  }

bool IsGridPlacementAllowed(const bool freshH4Cycle = false)
  {
   if(IsKillSwitchActiveToday())
      return false;

   if(!IsGridOpsAllowed())
      return false;

   string shockReason = "";
   if(IsExtremeH4ShockCooldownActive(shockReason))
     {
      static datetime lastShockLogTime = 0;
      const datetime now = TimeCurrent();
      if((now - lastShockLogTime) >= 60)
        {
         lastShockLogTime = now;
         PrintFormat("TGM [R378]: %s blocked — %s",
                     freshH4Cycle ? "H4FreshGrid" : "GridPlacement",
                     shockReason);
        }
      return false;
     }

   // R416: H4 range gate disabled — both sides on every H4 close.
#ifdef TGM_R380_FORCE_NO_H4_RANGE_FILTER
   // skip range check
#else
   string rangeReason = "";
   if(!IsResearchH4RangeAllowed(rangeReason))
     {
      static datetime lastRangeLogTime = 0;
      const datetime now = TimeCurrent();
      if((now - lastRangeLogTime) >= 60)
        {
         lastRangeLogTime = now;
         PrintFormat("TGM [R382]: %s blocked — %s",
                     freshH4Cycle ? "H4FreshGrid" : "GridPlacement",
                     rangeReason);
        }
      return false;
     }
#endif

   // Fresh H4 bar: 3% equity per level + up to 6 pendings unless daily lock.
   if(freshH4Cycle)
      return Phase17_AllowFreshH4GridPlacement("H4FreshGrid");

   // Same-H4 refill: bot-only DD pause, daily lock, range filter.
   if(!Phase17_AllowNewExposureSimple("GridPlacement"))
      return false;

   // Bot-only floating loss vs balance — manual open P/L invisible.
   if(Enable_Account_Protection && g_accountProtectionActive)
      return false;

   return true;
  }

string KillSwitchDayKey()
  {
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   return StringFormat("TGM_KillDay_%04d%02d%02d_%I64u_%s",
                       dt.year, dt.mon, dt.day,
                       (ulong)AccountInfoInteger(ACCOUNT_LOGIN),
                       _Symbol);
  }

string DayStartBalanceKey()
  {
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   return StringFormat("TGM_DayBal_%04d%02d%02d_%I64u",
                       dt.year, dt.mon, dt.day,
                       (ulong)AccountInfoInteger(ACCOUNT_LOGIN));
  }

void SetKillSwitchForToday(const string reason)
  {
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   GlobalVariableSet(KillSwitchDayKey(), (double)dt.day);
   g_emergencyKillSwitchActive = true;
   g_emergencyKillSwitchReason = reason;
   g_accountProtectionActive = true;
   g_accountProtectionReason = "KILL SWITCH: " + reason;
  }

bool IsKillSwitchActiveToday()
  {
   if(!Enable_Triple_Protection)
     {
      g_emergencyKillSwitchActive = false;
      return false;
     }

   const string key = KillSwitchDayKey();
   if(!GlobalVariableCheck(key))
     {
      g_emergencyKillSwitchActive = false;
      return false;
     }

   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   const bool active = ((int)GlobalVariableGet(key) == dt.day);
   g_emergencyKillSwitchActive = active;
   return active;
  }

double GetDayStartBalance()
  {
   const string key = DayStartBalanceKey();
   if(!GlobalVariableCheck(key))
     {
      const double bal = AccountInfoDouble(ACCOUNT_BALANCE);
      GlobalVariableSet(key, bal);
      return bal;
     }
   return GlobalVariableGet(key);
  }

double GetDailyLossPercent()
  {
   const double dayStart = GetDayStartBalance();
   if(dayStart <= 0.0)
      return 0.0;
   const double botPL = GetBotFloatingPL();          // EA-only, ignores manual trades
   const double loss  = (botPL < 0.0) ? -botPL : 0.0;
   return (loss > 0.0) ? (loss / dayStart * 100.0) : 0.0;
  }

void ActivateEmergencyKillSwitch(const string reason)
  {
   Print("TGM [KILL SWITCH LAYER 3]: ", reason, " - closing ALL bot positions and pendings.");
   CloseAllBotPositionsForced("KillSwitch");
   EnsureAllBotPendingDeletedForced();
   SetKillSwitchForToday(reason);
   LogProtectionAlert("LAYER 3 ACTIVATED: " + reason + " | Trading paused until tomorrow.");
  }

void MonitorLayer3HardKillSwitch()
  {
   if(!Enable_Triple_Protection || !Enable_Account_Protection)
      return;

   if(IsKillSwitchActiveToday())
      return;

   const double floatDD = GetFloatingDrawdownPercent();
   if(floatDD >= Emergency_Close_DD_Percent)
     {
      ActivateEmergencyKillSwitch(StringFormat("Floating DD %.1f%% >= emergency %.1f%%",
                                               floatDD, Emergency_Close_DD_Percent));
      return;
     }

   const double dailyLoss = GetDailyLossPercent();
   if(dailyLoss >= Max_Daily_Loss_Percent)
     {
      ActivateEmergencyKillSwitch(StringFormat("Daily loss %.1f%% >= limit %.1f%%",
                                               dailyLoss, Max_Daily_Loss_Percent));
     }
  }

string PositionUnprotectedSinceKey(const ulong ticket)
  {
   return StringFormat("TGM_Unprot_%I64u_%s_%I64u",
                       (ulong)AccountInfoInteger(ACCOUNT_LOGIN), _Symbol, ticket);
  }

string PositionHedgeFailCountKey(const ulong parentTicket)
  {
   return StringFormat("TGM_HedgeFail_%I64u_%s_%I64u",
                       (ulong)AccountInfoInteger(ACCOUNT_LOGIN), _Symbol, parentTicket);
  }

string PositionEmergencySLKey(const ulong ticket)
  {
   return StringFormat("TGM_EmSL_%I64u_%s_%I64u",
                       (ulong)AccountInfoInteger(ACCOUNT_LOGIN), _Symbol, ticket);
  }

void MarkUnprotectedSince(const ulong ticket)
  {
   const string key = PositionUnprotectedSinceKey(ticket);
   if(!GlobalVariableCheck(key))
      GlobalVariableSet(key, (double)TimeCurrent());
  }

void ClearUnprotectedSince(const ulong ticket)
  {
   const string key = PositionUnprotectedSinceKey(ticket);
   if(GlobalVariableCheck(key))
      GlobalVariableDel(key);
  }

int GetHedgeFailCount(const ulong parentTicket)
  {
   const string key = PositionHedgeFailCountKey(parentTicket);
   return GlobalVariableCheck(key) ? (int)GlobalVariableGet(key) : 0;
  }

void IncrementHedgeFailCount(const ulong parentTicket)
  {
   GlobalVariableSet(PositionHedgeFailCountKey(parentTicket), (double)(GetHedgeFailCount(parentTicket) + 1));
  }

void ClearHedgeFailCount(const ulong parentTicket)
  {
   const string key = PositionHedgeFailCountKey(parentTicket);
   if(GlobalVariableCheck(key))
      GlobalVariableDel(key);
  }

bool IsEmergencySLApplied(const ulong ticket)
  {
   return GlobalVariableCheck(PositionEmergencySLKey(ticket));
  }

void MarkEmergencySLApplied(const ulong ticket)
  {
   GlobalVariableSet(PositionEmergencySLKey(ticket), 1.0);
  }

bool ParentHasActiveHedge(const ulong parentTicket)
  {
   ulong linked = 0;
   if(GetLinkedHedgeTicket(parentTicket, linked))
      return true;
   return (FindOpenHedgeTicketForParent(parentTicket) > 0);
  }

bool ApplyEmergencyParentSL(const ulong ticket)
  {
   if(!Enable_Triple_Protection || !PreProtectionTradeGuard("EmergencyParentSL"))
      return false;

   CPositionInfo pos;
   if(!pos.SelectByTicket(ticket))
      return false;
   if(pos.Symbol() != _Symbol || pos.Magic() != (ulong)EXPERT_MAGIC)
      return false;
   if(IsHedgePositionComment(pos.Comment()))
      return false;
   if(IsEmergencySLApplied(ticket))
      return false;

   const int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   const double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   if(point <= 0.0)
      return false;

   const double openPrice = pos.PriceOpen();
   const double slDist = StrategyPointsToPriceDistance(Emergency_Parent_SL_Points);
   const double stopsLevel = (double)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * point;
   const double minDist = MathMax(slDist, stopsLevel + point);
   const double liveTP = pos.TakeProfit();
   double targetSL = 0.0;

   if(pos.PositionType() == POSITION_TYPE_BUY)
     {
      targetSL = NormalizeDouble(openPrice - minDist, digits);
      const double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      const double maxValidSL = NormalizeDouble(bid - stopsLevel - point, digits);
      if(targetSL > maxValidSL)
         targetSL = maxValidSL;
     }
   else
     {
      targetSL = NormalizeDouble(openPrice + minDist, digits);
      const double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      const double minValidSL = NormalizeDouble(ask + stopsLevel + point, digits);
      if(targetSL < minValidSL)
         targetSL = minValidSL;
     }

   const double liveSL = pos.StopLoss();
   if(liveSL > 0.0)
     {
      if(pos.PositionType() == POSITION_TYPE_BUY && targetSL <= liveSL)
         return true;
      if(pos.PositionType() == POSITION_TYPE_SELL && targetSL >= liveSL)
         return true;
     }

   if(!SafePositionModify(ticket, targetSL, liveTP, "EmergencyParentSL"))
      return false;

   MarkEmergencySLApplied(ticket);
   PrintFormat("TGM [LAYER 2]: Emergency broker SL on grid #%I64u at %s (max -%.0f pts).",
               ticket, DoubleToString(targetSL, digits), Emergency_Parent_SL_Points);
   return true;
  }

bool CloseGridPositionEmergency(const ulong ticket, const string reason)
  {
   if(!PreProtectionTradeGuard("EmergencyClose"))
      return false;

   CPositionInfo pos;
   if(!pos.SelectByTicket(ticket))
      return false;

   if(!ExecuteTradeOp("EmergencyClose", g_trade.PositionClose(ticket),
                      StringFormat("ticket=%I64u reason=%s", ticket, reason)))
      return false;

   ClearHedgeProtectionState(ticket);
   ClearUnprotectedSince(ticket);
   ClearHedgeFailCount(ticket);
   const string emKey = PositionEmergencySLKey(ticket);
   if(GlobalVariableCheck(emKey))
      GlobalVariableDel(emKey);

   PrintFormat("TGM [LAYER 2]: Emergency CLOSE grid #%I64u (%s).", ticket, reason);
   return true;
  }

void EnforceLayer2EmergencyParentProtection()
  {
   if(!Enable_Triple_Protection || !Enable_Account_Protection)
      return;
   // Mode B: shared Live ATR-14 H4 broker SL is the loss exit — do not overlay emergency SL.
   if(IsFixedSlReentryMode())
      return;
   // Mode A: still run while hedge engine is ON — only parents WITHOUT a live hedge
   // get emergency SL after hang timeout (see ParentHasActiveHedge check below).

   const double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   if(point <= 0.0)
      return;

   const double triggerPts = StrategyPointsToBrokerPoints(TGM_HEDGE_TRIGGER_STRATEGY_PTS);
   const double emergencyPts = StrategyPointsToBrokerPoints(Emergency_Parent_SL_Points);
   const datetime now = TimeCurrent();
   CPositionInfo pos;

   for(int i = 0; i < PositionsTotal(); i++)
     {
      if(!pos.SelectByIndex(i))
         continue;
      if(pos.Symbol() != _Symbol || pos.Magic() != (ulong)EXPERT_MAGIC)
         continue;
      if(IsHedgePositionComment(pos.Comment()))
         continue;

      const ulong ticket = pos.Ticket();
      if(ParentHasActiveHedge(ticket))
        {
         ClearUnprotectedSince(ticket);
         continue;
        }

      const double lossPts = GetTicketLossPoints(ticket, point);
      if(lossPts < triggerPts)
        {
         ClearUnprotectedSince(ticket);
         continue;
        }

      MarkUnprotectedSince(ticket);
      const datetime unprotSince = (datetime)GlobalVariableGet(PositionUnprotectedSinceKey(ticket));
      const int hangSec = (int)(now - unprotSince);
      const int failCount = GetHedgeFailCount(ticket);

      const bool hangTriggered = (hangSec >= Unprotected_Hang_Seconds);
      const bool deepLoss = (lossPts >= emergencyPts);
      const bool failTriggered = (failCount >= TGM_MAX_HEDGE_FAIL_BEFORE_EMERGENCY && lossPts >= triggerPts);

      if(!hangTriggered && !deepLoss && !failTriggered)
         continue;

      LogProtectionAlert(StringFormat("LAYER 2: grid #%I64u unprotected %ds | loss %.0f | hedgeFails=%d",
                                      ticket, hangSec, lossPts, failCount));

      if(!ApplyEmergencyParentSL(ticket) && deepLoss)
         CloseGridPositionEmergency(ticket, "Layer2-EmergencyClose");
     }
  }

string PositionHedgeBarLockKey(const ulong parentTicket)
  {
   return StringFormat("TGM_HedgeBar_%I64u_%s_%I64u",
                       (ulong)AccountInfoInteger(ACCOUNT_LOGIN), _Symbol, parentTicket);
  }

string PositionHedgeCycleH4Key(const ulong parentTicket)
  {
   return StringFormat("TGM_HedgeCyc_%I64u_%s_%I64u",
                       (ulong)AccountInfoInteger(ACCOUNT_LOGIN), _Symbol, parentTicket);
  }

string PositionHedgeRetryKey(const ulong parentTicket)
  {
   return StringFormat("TGM_HedgeRetry_%I64u_%s_%I64u",
                       (ulong)AccountInfoInteger(ACCOUNT_LOGIN), _Symbol, parentTicket);
  }

string PositionHedgeLossGateKey(const ulong parentTicket)
  {
   return StringFormat("TGM_HedgeGate_%I64u_%s_%I64u",
                       (ulong)AccountInfoInteger(ACCOUNT_LOGIN), _Symbol, parentTicket);
  }

void SetHedgeBarLock(const ulong parentTicket)
  {
   GlobalVariableSet(PositionHedgeBarLockKey(parentTicket), (double)GetCurrentH4BarOpenTime());
  }

bool IsHedgeBarLockActive(const ulong parentTicket)
  {
   const string key = PositionHedgeBarLockKey(parentTicket);
   if(!GlobalVariableCheck(key))
      return false;
   return ((datetime)GlobalVariableGet(key) == GetCurrentH4BarOpenTime());
  }

void ClearHedgeProtectionState(const ulong parentTicket)
  {
   const string k0 = PositionHedgeBarLockKey(parentTicket);
   const string k1 = PositionHedgeCycleH4Key(parentTicket);
   const string k2 = PositionHedgeRetryKey(parentTicket);
   const string k3 = PositionHedgeLossGateKey(parentTicket);
   const string k4 = PositionHedgeCycleCountKey(parentTicket);
   const string k5 = PositionHedgeCycleBarKey(parentTicket);
   const string k6 = PositionHedgeRearmKey(parentTicket);
   const string k7 = PositionHedgeLiveKey(parentTicket);
   const string k8 = PositionHedgeOpenTimeKey(parentTicket);
   const string k9 = PositionHedgeTriggerReadyKey(parentTicket);
   if(GlobalVariableCheck(k0)) GlobalVariableDel(k0);
   if(GlobalVariableCheck(k1)) GlobalVariableDel(k1);
   if(GlobalVariableCheck(k2)) GlobalVariableDel(k2);
   if(GlobalVariableCheck(k3)) GlobalVariableDel(k3);
   if(GlobalVariableCheck(k4)) GlobalVariableDel(k4);
   if(GlobalVariableCheck(k5)) GlobalVariableDel(k5);
   if(GlobalVariableCheck(k6)) GlobalVariableDel(k6);
   if(GlobalVariableCheck(k7)) GlobalVariableDel(k7);
   if(GlobalVariableCheck(k8)) GlobalVariableDel(k8);
   if(GlobalVariableCheck(k9)) GlobalVariableDel(k9);
   ClearLinkedHedgeTicket(parentTicket);
   const string cdKey = PositionHedgeCooldownKey(parentTicket);
   if(GlobalVariableCheck(cdKey))
      GlobalVariableDel(cdKey);
   ClearHedgeChopState(parentTicket);
  }

string PositionHedgeCycleCountKey(const ulong parentTicket)
  {
   return StringFormat("TGM_HedgeCnt_%I64u_%s_%I64u",
                       (ulong)AccountInfoInteger(ACCOUNT_LOGIN), _Symbol, parentTicket);
  }

string PositionHedgeCycleBarKey(const ulong parentTicket)
  {
   return StringFormat("TGM_HedgeCycBar_%I64u_%s_%I64u",
                       (ulong)AccountInfoInteger(ACCOUNT_LOGIN), _Symbol, parentTicket);
  }

void SyncHedgeBarStateForParent(const ulong parentTicket)
  {
   const string lockKey = PositionHedgeBarLockKey(parentTicket);
   if(!GlobalVariableCheck(lockKey))
      return;
   if((datetime)GlobalVariableGet(lockKey) != GetCurrentH4BarOpenTime())
     {
      GlobalVariableDel(lockKey);
      const string gateKey = PositionHedgeLossGateKey(parentTicket);
      if(GlobalVariableCheck(gateKey))
         GlobalVariableDel(gateKey);
      const string cntKey = PositionHedgeCycleCountKey(parentTicket);
      if(GlobalVariableCheck(cntKey))
         GlobalVariableDel(cntKey);
      const string cycBarKey = PositionHedgeCycleBarKey(parentTicket);
      if(GlobalVariableCheck(cycBarKey))
         GlobalVariableDel(cycBarKey);
     }
  }

int GetHedgeCyclesThisH4(const ulong parentTicket)
  {
   SyncHedgeBarStateForParent(parentTicket);

   const datetime h4Bar = GetCurrentH4BarOpenTime();
   const string cycBarKey = PositionHedgeCycleBarKey(parentTicket);
   const string cntKey = PositionHedgeCycleCountKey(parentTicket);

   if(GlobalVariableCheck(cycBarKey) && (datetime)GlobalVariableGet(cycBarKey) != h4Bar)
     {
      GlobalVariableDel(cycBarKey);
      if(GlobalVariableCheck(cntKey))
         GlobalVariableDel(cntKey);
      return 0;
     }

   if(!GlobalVariableCheck(cntKey))
      return 0;
   return (int)GlobalVariableGet(cntKey);
  }

void IncrementHedgeCycle(const ulong parentTicket)
  {
   if(Max_Hedge_Cycles_Per_H4 <= 0)
      return;

   const int cycles = GetHedgeCyclesThisH4(parentTicket) + 1;
   GlobalVariableSet(PositionHedgeCycleBarKey(parentTicket), (double)GetCurrentH4BarOpenTime());
   GlobalVariableSet(PositionHedgeCycleCountKey(parentTicket), (double)cycles);

   const int limit = Enable_Account_Protection ? Max_Hedge_Cycles_Per_H4 : TGM_MAX_HEDGE_CYCLES_PER_H4;
   if(cycles >= limit)
     {
      SetHedgeBarLock(parentTicket);
      LogProtectionAlert(StringFormat("Hedge cycle limit %d/%d on parent #%I64u - locked until new H4 bar.",
                                      cycles, limit, parentTicket));
     }
  }

bool IsHedgeCycleLimitReached(const ulong parentTicket)
  {
   if(Max_Hedge_Cycles_Per_H4 <= 0)
      return false;

   const int limit = Enable_Account_Protection ? Max_Hedge_Cycles_Per_H4 : TGM_MAX_HEDGE_CYCLES_PER_H4;
   return (GetHedgeCyclesThisH4(parentTicket) >= limit);
  }

void ScheduleHedgeRetry(const ulong parentTicket)
  {
   GlobalVariableSet(PositionHedgeRetryKey(parentTicket), (double)(TimeCurrent() + Hedge_Retry_Seconds));
  }

bool IsHedgeRetryDue(const ulong parentTicket)
  {
   const string key = PositionHedgeRetryKey(parentTicket);
   if(!GlobalVariableCheck(key))
      return true;
   if(TimeCurrent() >= (datetime)GlobalVariableGet(key))
     {
      GlobalVariableDel(key);
      return true;
     }
   return false;
  }

void SetHedgeLossGate(const ulong parentTicket, const double lossPts)
  {
   GlobalVariableSet(PositionHedgeLossGateKey(parentTicket), lossPts);
  }

double GetHedgeLossGate(const ulong parentTicket)
  {
   const string key = PositionHedgeLossGateKey(parentTicket);
   return GlobalVariableCheck(key) ? GlobalVariableGet(key) : 0.0;
  }

bool IsHedgeOpenAllowedForParent(const ulong parentTicket, const double parentLossPts)
  {
   if(!IsHedgeEngineActive())
      return false;

   SyncHedgeBarStateForParent(parentTicket);

   if(IsHedgeBarLockActive(parentTicket))
      return false;

   if(IsHedgeCycleLimitReached(parentTicket))
      return false;

   if(!IsHedgeRetryDue(parentTicket))
      return false;

   return true;
  }

void EnforceHedgeCoverageScan()
  {
   if(!IsHedgeEngineActive() || !Enable_Account_Protection)
      return;

   const double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   if(point <= 0.0)
      return;

   const double triggerBrokerPts = StrategyPointsToBrokerPoints(TGM_HEDGE_TRIGGER_STRATEGY_PTS);
   CPositionInfo pos;

   for(int i = 0; i < PositionsTotal(); i++)
     {
      if(!pos.SelectByIndex(i))
         continue;
      if(pos.Symbol() != _Symbol || pos.Magic() != (ulong)EXPERT_MAGIC)
         continue;
      if(IsHedgePositionComment(pos.Comment()))
         continue;

      const ulong parentTicket = pos.Ticket();
      const double lossPts = GetTicketLossPoints(parentTicket, point);
      if(lossPts < triggerBrokerPts)
         continue;

      ulong activeHedge = 0;
      if(GetLinkedHedgeTicket(parentTicket, activeHedge))
         continue;
      if(FindOpenHedgeTicketForParent(parentTicket) > 0)
         continue;

      if(IsTradeProfitZoneSecured(parentTicket))
         continue;

      LogProtectionAlert(StringFormat("UNPROTECTED grid #%I64u | loss %.0f pts | no hedge - forcing open.",
                                      parentTicket, lossPts));
      OpenHedgeForParent(parentTicket);
     }
  }

//--- Simplified per-tick engine (R411: PROFIT BOOK FIRST — hedge BE must not starve closes).
void RunAccountProtectionEngine()
  {
   if(IsKillSwitchActiveToday())
      return;

   MonitorLayer3HardKillSwitch();
   if(IsKillSwitchActiveToday())
      return;

   MonitorAccountDrawdownProtection();

   // R411: book floating winners BEFORE hedge modify spam (invalid stops was starving closes).
   UniversalGoldTrailingEngine();

   if(IsHedgeEngineActive())
     {
      ProcessHedgeProtectionEngine();
      ManageHedgeBreakEvenCycle();
     }

   EnforceSurvivalBeforeStopOut();
   EnforceTrendBleedProtect();
  }

bool CloseHedgePosition(const ulong hedgeTicket, const string reason)
  {
   if(!PreProtectionTradeGuard("HedgeClose"))
      return false;

   CPositionInfo pos;
   if(!pos.SelectByTicket(hedgeTicket))
      return false;

   const ulong parentTicket = ResolveHedgeParentTicket(hedgeTicket, pos.Comment());
   double parentLossAtClose = 0.0;
   if(parentTicket > 0)
     {
      CPositionInfo parent;
      if(parent.SelectByTicket(parentTicket))
        {
         const double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
         parentLossAtClose = GetTicketLossPoints(parentTicket, point);
        }
     }

   if(!ExecuteTradeOp("HedgeClose", g_trade.PositionClose(hedgeTicket),
                      StringFormat("ticket=%I64u reason=%s", hedgeTicket, reason)))
      return false;

   ClearHedgePeakProfitPoints(hedgeTicket);
   ClearHedgeBreakEvenArmed(hedgeTicket);
   ClearHedgeReturnArmed(hedgeTicket);

   if(parentTicket > 0)
     {
      ulong linked = 0;
      if(GetLinkedHedgeTicket(parentTicket, linked) && linked == hedgeTicket)
         ClearLinkedHedgeTicket(parentTicket);

      if(reason == "ParentClosed")
         ClearHedgeProtectionState(parentTicket);
      else if(reason == "DuplicateCleanup")
        {
         // Keep parent hedge-live / re-arm state; another hedge remains open.
        }
      else
        {
         ClearHedgeLive(parentTicket);
         ClearHedgeRearmState(parentTicket);
         ApplyHedgeRecycleCooldown(parentTicket, 0);
         SetHedgeTriggerReady(parentTicket, true);
         if(reason == "HedgeLoss100")
            ScheduleHedgeRetry(parentTicket);
         // R406: hedge gone while parent still in loss => MANDATORY instant re-hedge.
         ForceRehedgeIfParentStillInLoss(parentTicket, "HedgeClosed:" + reason);
        }
     }

   PrintFormat("TGM [HEDGE]: Closed hedge #%I64u for parent #%I64u (%s).", hedgeTicket, parentTicket, reason);
   return true;
  }

//--- CONDITION 2: open / top-up opposite hedge for a parent in loss by
//    >= InpHedgeTriggerUSD. Hedge lot MUST match remaining uncovered parent volume (1:1).
bool OpenHedgeForParent(const ulong parentTicket)
  {
   if(!IsHedgeEngineActive() || !PreProtectionTradeGuard("HedgeOpen"))
      return false;

   CPositionInfo pos;
   if(!pos.SelectByTicket(parentTicket))
      return false;
   // JAIL: manual/foreign parents cannot receive a hedge from this EA.
   if(!IsOurBotGridParent(parentTicket))
     {
      LogProtectionAlert(StringFormat("Hedge BLOCKED — ticket #%I64u is manual/foreign (magic gate).", parentTicket));
      return false;
     }
   if(IsBotHedgePosition(parentTicket, pos.Comment()))
      return false;
   if(!CanOpenHedgeForParent(parentTicket))
      return false;

   // R394: sticky mode — at most ONE hedge ticket per parent (no second-leg spam).
   if(CountHedgesForParent(parentTicket) >= 1)
     {
      LogHedgeBlockOnce(parentTicket, "sticky: one hedge already live (no second ticket)");
      return false;
     }

   // CRITICAL: hedge size = parent lot still uncovered (never Manual_Lot_Size).
   const double parentLots = pos.Volume();
   double lots = GetHedgeVolumeShortfall(parentTicket);
   if(lots <= 0.0)
      lots = NormalizeVolume(parentLots);
   if(lots <= 0.0)
      return false;

   // Safety: never open a hedge larger than parent (netting / float quirks).
   if(lots > parentLots + 1e-8)
      lots = NormalizeVolume(parentLots);

   const int    digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   const double stops  = GetSymbolStopsPrice();
   const double pip    = Phase17_GetPipSize();
   const string cmt    = BuildHedgeComment(parentTicket);
   const double bid    = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   const double ask    = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

   bool   ok    = false;
   double entry = 0.0;
   double sl    = 0.0;
   ENUM_ORDER_TYPE hedgeSide;
   // R412: always attach hedge death SL at -10pip (parent pending SL untouched).
   const double hedgeLossDist = (pip > 0.0) ? (TGM_HEDGE_OWN_LOSS_PIPS * pip) : 1.0;

   if(pos.PositionType() == POSITION_TYPE_BUY)
     {
      hedgeSide = ORDER_TYPE_SELL;
      entry     = bid;
      sl = NormalizeDouble(entry + hedgeLossDist, digits); // SELL SL above entry
      const double minSL = NormalizeDouble(ask + stops, digits);
      if(sl < minSL)
         sl = minSL;
      ok = g_trade.Sell(lots, _Symbol, entry, sl, 0.0, cmt);
     }
   else
     {
      hedgeSide = ORDER_TYPE_BUY;
      entry     = ask;
      sl = NormalizeDouble(entry - hedgeLossDist, digits); // BUY SL below entry
      const double maxSL = NormalizeDouble(bid - stops, digits);
      if(sl > maxSL)
         sl = maxSL;
      ok = g_trade.Buy(lots, _Symbol, entry, sl, 0.0, cmt);
     }

   if(!ok)
     {
      LogProtectionAlert(StringFormat("Hedge OPEN FAILED for parent #%I64u needLots=%.2f parentLots=%.2f (retcode=%u).",
                                      parentTicket, lots, parentLots, g_trade.ResultRetcode()));
      return false;
     }

   ulong openedHedgeTicket = GetOpenedPositionIdFromTrade();
   if(openedHedgeTicket == 0)
      openedHedgeTicket = FindOpenHedgeTicketForParent(parentTicket);

   double filledLots = lots;
   CPositionInfo openedPos;
   if(openedHedgeTicket > 0 && openedPos.SelectByTicket(openedHedgeTicket))
      filledLots = openedPos.Volume();

   if(openedHedgeTicket > 0)
     {
      SetLinkedHedgeTicket(parentTicket, openedHedgeTicket);
      SetHedgeTriggerReady(parentTicket, true);
      ClearHedgeRearmState(parentTicket);
      PrintFormat("TGM [R412]: opened %s hedge #%I64u for parent #%I64u | lots=%.2f | hedgeSL=-%.0fpip @ %.*f.",
                  (hedgeSide == ORDER_TYPE_SELL) ? "SELL" : "BUY",
                  openedHedgeTicket, parentTicket, filledLots,
                  TGM_HEDGE_OWN_LOSS_PIPS, digits, sl);
      if(MathAbs(filledLots - lots) > SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP))
         LogProtectionAlert(StringFormat("HEDGE LOT MISMATCH parent #%I64u requested=%.2f filled=%.2f — will top-up.",
                                         parentTicket, lots, filledLots));
      MarkHedgeLive(parentTicket);
      MarkHedgeOpenTime(parentTicket);
      IncrementHedgeCycle(parentTicket);
      ApplyParentHardLossCap(parentTicket);
     }
   return (openedHedgeTicket > 0);
  }

void SyncHedgeOrphanPositions()
  {
   CPositionInfo pos;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(!pos.SelectByIndex(i))
         continue;
      if(pos.Symbol() != _Symbol || pos.Magic() != (ulong)EXPERT_MAGIC)
         continue;
      if(!IsBotHedgePosition(pos.Ticket(), pos.Comment()))
         continue;

      const ulong parentTicket = ResolveHedgeParentTicket(pos.Ticket(), pos.Comment());
      CPositionInfo parent;
      if(parentTicket == 0 || !parent.SelectByTicket(parentTicket))
         CloseHedgePosition(pos.Ticket(), "ParentClosed");
     }
  }

//--- Wipe every soft gate that could delay re-hedge while parent is still in loss.
void ClearMandatoryHedgeGates(const ulong parentTicket)
  {
   if(parentTicket == 0)
      return;
   const string cd = PositionHedgeCooldownKey(parentTicket);
   if(GlobalVariableCheck(cd))
      GlobalVariableDel(cd);
   const string retry = PositionHedgeRetryKey(parentTicket);
   if(GlobalVariableCheck(retry))
      GlobalVariableDel(retry);
   const string barLock = PositionHedgeBarLockKey(parentTicket);
   if(GlobalVariableCheck(barLock))
      GlobalVariableDel(barLock);
   ClearHedgeChopState(parentTicket);
   ClearHedgeRearmState(parentTicket);
   SetHedgeTriggerReady(parentTicket, true);
  }

//--- HARD RULE: parent still open + loss >= 30pip + no 1:1 hedge => open NOW.
bool ForceRehedgeIfParentStillInLoss(const ulong parentTicket, const string reason)
  {
   if(parentTicket == 0 || !IsHedgeEngineActive())
      return false;

   CPositionInfo parent;
   if(!parent.SelectByTicket(parentTicket))
      return false;
   if(!IsOurBotGridParent(parentTicket))
      return false;
   if(GetPositionLossPips(parentTicket) + 1e-9 < TGM_LOSS_HEDGE_PIPS)
      return false;
   if(HasHedge(parentTicket) && HasFullHedgeCoverage(parentTicket))
      return true;

   ClearMandatoryHedgeGates(parentTicket);
   RestoreParentPendingSL(parentTicket, reason);

   for(int attempt = 1; attempt <= TGM_MANDATORY_REHEDGE_ATTEMPTS; attempt++)
     {
      if(HasHedge(parentTicket) && HasFullHedgeCoverage(parentTicket))
         return true;
      if(OpenHedgeForParent(parentTicket))
        {
         PrintFormat("TGM [R406]: MANDATORY re-hedge OK parent #%I64u (%s) attempt=%d loss=%.1fpip",
                     parentTicket, reason, attempt, GetPositionLossPips(parentTicket));
         return true;
        }
     }

   PrintFormat("TGM [R406]: MANDATORY re-hedge FAILED parent #%I64u (%s) — retry every tick until covered.",
               parentTicket, reason);
   return false;
  }

void EnforceMandatoryHedgeCoverage()
  {
   if(!IsHedgeEngineActive() || IsMarketValidationMode())
      return;

   CPositionInfo pos;
   for(int i = 0; i < PositionsTotal(); i++)
     {
      if(IsStopped())
         return;
      if(!pos.SelectByIndex(i))
         continue;
      if(pos.Symbol() != _Symbol || pos.Magic() != (ulong)EXPERT_MAGIC)
         continue;
      if(!IsOurBotGridParent(pos.Ticket()))
         continue;

      const ulong parentTicket = pos.Ticket();
      EnsureHedgeProtectArmed(parentTicket);
      if(GetPositionLossPips(parentTicket) + 1e-9 < TGM_LOSS_HEDGE_PIPS)
         continue;
      if(HasHedge(parentTicket) && HasFullHedgeCoverage(parentTicket))
         continue;

      ForceRehedgeIfParentStillInLoss(parentTicket, "EnforceMandatory");
     }
  }

ulong FindHedgeProtectStopTicket(const ulong parentTicket)
  {
   if(parentTicket == 0)
      return 0;
   const string expected = BuildHedgeComment(parentTicket);
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      const ulong ticket = OrderGetTicket(i);
      if(ticket == 0 || !OrderSelect(ticket))
         continue;
      if(OrderGetString(ORDER_SYMBOL) != _Symbol)
         continue;
      if((long)OrderGetInteger(ORDER_MAGIC) != EXPERT_MAGIC)
         continue;
      const ENUM_ORDER_TYPE ot = (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
      if(ot != ORDER_TYPE_BUY_STOP && ot != ORDER_TYPE_SELL_STOP)
         continue;
      const string cmt = OrderGetString(ORDER_COMMENT);
      if(cmt == expected || ParseHedgeParentTicket(cmt) == parentTicket)
         return ticket;
     }
   return 0;
  }

int CancelHedgeProtectStopsForParent(const ulong parentTicket, const string reason)
  {
   int n = 0;
   const string expected = BuildHedgeComment(parentTicket);
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      const ulong ticket = OrderGetTicket(i);
      if(ticket == 0 || !OrderSelect(ticket))
         continue;
      if(OrderGetString(ORDER_SYMBOL) != _Symbol)
         continue;
      if((long)OrderGetInteger(ORDER_MAGIC) != EXPERT_MAGIC)
         continue;
      const string cmt = OrderGetString(ORDER_COMMENT);
      if(!IsHedgePositionComment(cmt))
         continue;
      if(cmt != expected && ParseHedgeParentTicket(cmt) != parentTicket)
         continue;
      if(ExecuteTradeOp("HedgeStopDelete", g_trade.OrderDelete(ticket),
                        StringFormat("ticket=%I64u %s", ticket, reason)))
         n++;
     }
   return n;
  }

bool PlaceHedgeProtectStop(const ulong parentTicket)
  {
   if(!IsHedgeEngineActive() || !PreProtectionTradeGuard("HedgeProtectStop"))
      return false;

   CPositionInfo parent;
   if(!parent.SelectByTicket(parentTicket) || !IsOurBotGridParent(parentTicket))
      return false;
   if(HasHedge(parentTicket))
      return true;
   if(FindHedgeProtectStopTicket(parentTicket) > 0)
      return true;

   const double pip = Phase17_GetPipSize();
   if(pip <= 0.0)
      return false;

   const int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   const double lots = NormalizeVolume(parent.Volume());
   if(lots <= 0.0)
      return false;

   const double open = parent.PriceOpen();
   const double dist = TGM_LOSS_HEDGE_PIPS * pip;
   const string cmt = BuildHedgeComment(parentTicket);
   const double stops = GetSymbolStopsPrice();
   const double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   const double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

   bool ok = false;
   double stopPrice = 0.0;

   if(parent.PositionType() == POSITION_TYPE_BUY)
     {
      stopPrice = NormalizeDouble(open - dist, digits);
      if(bid <= stopPrice + 1e-9 || (bid - stopPrice) < stops - 1e-9)
         return OpenHedgeForParent(parentTicket);
      ok = g_trade.SellStop(lots, stopPrice, _Symbol, 0.0, 0.0, ORDER_TIME_GTC, (datetime)0, cmt);
     }
   else
     {
      stopPrice = NormalizeDouble(open + dist, digits);
      if(ask >= stopPrice - 1e-9 || (stopPrice - ask) < stops - 1e-9)
         return OpenHedgeForParent(parentTicket);
      ok = g_trade.BuyStop(lots, stopPrice, _Symbol, 0.0, 0.0, ORDER_TIME_GTC, (datetime)0, cmt);
     }

   if(!ok)
     {
      PrintFormat("TGM [R407]: Hedge STOP FAILED parent #%I64u price=%.*f lots=%.2f ret=%u — market fallback.",
                  parentTicket, digits, stopPrice, lots, g_trade.ResultRetcode());
      return OpenHedgeForParent(parentTicket);
     }

   PrintFormat("TGM [R407]: Hedge STOP armed parent #%I64u %s @ %.*f lots=%.2f (broker fill @ -%.0fpip).",
               parentTicket,
               (parent.PositionType() == POSITION_TYPE_BUY) ? "SELL_STOP" : "BUY_STOP",
               digits, stopPrice, lots, TGM_LOSS_HEDGE_PIPS);
   return true;
  }

void EnsureHedgeProtectArmed(const ulong parentTicket)
  {
   if(parentTicket == 0 || !IsHedgeEngineActive())
      return;
   CPositionInfo parent;
   if(!parent.SelectByTicket(parentTicket) || !IsOurBotGridParent(parentTicket))
      return;

   if(GetPositionProfitPips(parentTicket) > 0.0)
     {
      CancelHedgeProtectStopsForParent(parentTicket, "ParentInProfit");
      return;
     }

   if(HasHedge(parentTicket) && HasFullHedgeCoverage(parentTicket))
     {
      CancelHedgeProtectStopsForParent(parentTicket, "HedgeAlreadyLive");
      return;
     }

   if(GetPositionLossPips(parentTicket) + 1e-9 >= TGM_LOSS_HEDGE_PIPS)
     {
      CancelHedgeProtectStopsForParent(parentTicket, "AlreadyThrough30");
      ForceRehedgeIfParentStillInLoss(parentTicket, "Through30Market");
      return;
     }

   PlaceHedgeProtectStop(parentTicket);
  }

//--- Hedge STOP/market fill: permanently bind parent↔hedge in GV (survives comment wipe).
void ProcessHedgeFillBindFromDeal(const ulong dealTicket)
  {
   if(dealTicket == 0)
      return;
   if(!HistoryDealSelect(dealTicket))
     {
      HistorySelect(0, TimeCurrent());
      if(!HistoryDealSelect(dealTicket))
         return;
     }
   if(HistoryDealGetString(dealTicket, DEAL_SYMBOL) != _Symbol)
      return;
   if((long)HistoryDealGetInteger(dealTicket, DEAL_MAGIC) != EXPERT_MAGIC)
      return;
   if(HistoryDealGetInteger(dealTicket, DEAL_ENTRY) != DEAL_ENTRY_IN)
      return;

   const string dealComment = HistoryDealGetString(dealTicket, DEAL_COMMENT);
   const ulong hedgePos = (ulong)HistoryDealGetInteger(dealTicket, DEAL_POSITION_ID);
   if(hedgePos == 0)
      return;

   ulong parentTicket = ParseHedgeParentTicket(dealComment);
   if(parentTicket == 0)
     {
      // Order comment may still have GM_HEDGE_xxx even if deal comment is blank.
      const ulong orderTicket = (ulong)HistoryDealGetInteger(dealTicket, DEAL_ORDER);
      if(orderTicket > 0 && HistoryOrderSelect(orderTicket))
         parentTicket = ParseHedgeParentTicket(HistoryOrderGetString(orderTicket, ORDER_COMMENT));
     }
   if(parentTicket == 0)
      parentTicket = FindParentForLinkedHedge(hedgePos);
   if(parentTicket == 0 || !IsOurBotGridParent(parentTicket))
      return;

   SetLinkedHedgeTicket(parentTicket, hedgePos);
   MarkHedgeLive(parentTicket);
   PrintFormat("TGM [R409]: Hedge FILL bound #%I64u -> parent #%I64u (link survives comment wipe).",
               hedgePos, parentTicket);
  }

//--- Hedge closed by broker BE / SL / any OUT: same-event re-hedge if parent still losing.
void ProcessHedgeExitRehedgeFromDeal(const ulong dealTicket)
  {
   if(dealTicket == 0 || !IsHedgeEngineActive())
      return;
   if(!HistoryDealSelect(dealTicket))
     {
      HistorySelect(0, TimeCurrent());
      if(!HistoryDealSelect(dealTicket))
         return;
     }
   if(HistoryDealGetString(dealTicket, DEAL_SYMBOL) != _Symbol)
      return;
   if((long)HistoryDealGetInteger(dealTicket, DEAL_MAGIC) != EXPERT_MAGIC)
      return;

   const long entry = HistoryDealGetInteger(dealTicket, DEAL_ENTRY);
   if(entry != DEAL_ENTRY_OUT && entry != DEAL_ENTRY_OUT_BY)
      return;

   const string dealComment = HistoryDealGetString(dealTicket, DEAL_COMMENT);
   if(!IsHedgePositionComment(dealComment))
      return;

   const ulong parentTicket = ParseHedgeParentTicket(dealComment);
   if(parentTicket == 0)
      return;

   CPositionInfo parent;
   if(!parent.SelectByTicket(parentTicket))
      return; // parent already gone — orphan path handles leftover hedges

   ForceRehedgeIfParentStillInLoss(parentTicket, "HedgeDealOut");
  }

void RecordPairedCycleNet(const double netMoney, const bool hedged, const string tag)
  {
   g_pairCycles++;
   g_pairNetSum += netMoney;
   if(netMoney >= 0.0)
     {
      g_pairWins++;
      g_pairWinSum += netMoney;
      if(g_pairCycles == 1 || netMoney > g_pairBestNet)
         g_pairBestNet = netMoney;
     }
   else
     {
      g_pairLosses++;
      g_pairLossSum += netMoney;
      if(g_pairCycles == 1 || netMoney < g_pairWorstNet)
         g_pairWorstNet = netMoney;
     }
   if(!hedged && netMoney < -1.0)
      g_pairUnhedgedSL++;

   PrintFormat("TGM [PAIR-NET]: %s net=$%.2f hedged=%s (truth vs MT5 split deals)",
               tag, netMoney, hedged ? "Y" : "N");
  }

void LogPairedNetSummary()
  {
   const double avgAll = (g_pairCycles > 0) ? (g_pairNetSum / g_pairCycles) : 0.0;
   const double avgW = (g_pairWins > 0) ? (g_pairWinSum / g_pairWins) : 0.0;
   const double avgL = (g_pairLosses > 0) ? (g_pairLossSum / g_pairLosses) : 0.0;
   PrintFormat("TGM [PAIR-SUMMARY]: cycles=%d sum=$%.2f avg=$%.2f | pairWins=%d avgW=$%.2f | pairLosses=%d avgL=$%.2f | best=$%.2f worst=$%.2f | unhedgedSL_hits=%d",
               g_pairCycles, g_pairNetSum, avgAll,
               g_pairWins, avgW, g_pairLosses, avgL,
               g_pairBestNet, g_pairWorstNet, g_pairUnhedgedSL);
   if(g_pairUnhedgedSL > 0)
      PrintFormat("TGM [PAIR-SUMMARY]: %d parent SL closes had NO live hedge — those are real leakage (not 30pip net).",
                  g_pairUnhedgedSL);
  }

double SumLiveHedgeMoneyForParent(const ulong parentTicket)
  {
   ulong hedges[];
   const int n = CollectHedgesForParent(parentTicket, hedges);
   double sum = 0.0;
   for(int i = 0; i < n; i++)
      sum += GetTicketNetMoney(hedges[i]);
   return sum;
  }

void CloseHedgesForParent(const ulong parentTicket, const string reason)
  {
   if(parentTicket == 0)
      return;
   ulong hedges[];
   const int n = CollectHedgesForParent(parentTicket, hedges);
   for(int i = 0; i < n; i++)
      CloseHedgePosition(hedges[i], reason);
  }

//--- Parent fully closed (SL / any OUT): close linked hedge same event + record PAIR net.
void ProcessParentExitCloseHedges(const ulong dealTicket)
  {
   if(dealTicket == 0)
      return;
   if(!HistoryDealSelect(dealTicket))
     {
      HistorySelect(0, TimeCurrent());
      if(!HistoryDealSelect(dealTicket))
         return;
     }
   if(HistoryDealGetString(dealTicket, DEAL_SYMBOL) != _Symbol)
      return;
   if((long)HistoryDealGetInteger(dealTicket, DEAL_MAGIC) != EXPERT_MAGIC)
      return;

   const long entry = HistoryDealGetInteger(dealTicket, DEAL_ENTRY);
   if(entry != DEAL_ENTRY_OUT && entry != DEAL_ENTRY_OUT_BY)
      return;

   const string dealComment = HistoryDealGetString(dealTicket, DEAL_COMMENT);
   if(IsHedgePositionComment(dealComment))
      return;

   const ulong parentTicket = (ulong)HistoryDealGetInteger(dealTicket, DEAL_POSITION_ID);
   if(parentTicket == 0)
      return;

   // Partial close still leaves parent live — do not kill hedge.
   CPositionInfo stillOpen;
   if(stillOpen.SelectByTicket(parentTicket))
      return;

   CancelHedgeProtectStopsForParent(parentTicket, "ParentGone");

   const long reason = HistoryDealGetInteger(dealTicket, DEAL_REASON);
   const string why = (reason == DEAL_REASON_SL) ? "ParentSLHit" : "ParentClosed";
   const double dealMoney = HistoryDealGetDouble(dealTicket, DEAL_PROFIT)
                            + HistoryDealGetDouble(dealTicket, DEAL_SWAP)
                            + HistoryDealGetDouble(dealTicket, DEAL_COMMISSION);
   const int hedgeN = CountHedgesForParent(parentTicket);
   const double hedgeMoney = SumLiveHedgeMoneyForParent(parentTicket);
   const bool hedged = (hedgeN > 0);

   PrintFormat("TGM [R408]: Parent #%I64u closed (%s) parent$=%.2f hedgeFloat$=%.2f hedges=%d",
               parentTicket, why, dealMoney, hedgeMoney, hedgeN);
   if(hedgeN > 0)
      CloseHedgesForParent(parentTicket, "ParentClosed");

   RecordPairedCycleNet(dealMoney + hedgeMoney, hedged, why);
  }

//--- Manage hedge (R412):
//    +10pip hedge profit (or parent -40) -> BE on hedge only
//    -10pip hedge loss -> broker SL / force-close hedge only (parent pending SL stays)
void ManageHedgeStopLoss(const ulong hedgeTicket)
  {
   CPositionInfo pos;
   if(!pos.SelectByTicket(hedgeTicket))
      return;

   const int    digits   = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   const double point    = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   const double pip      = Phase17_GetPipSize();
   if(pip <= 0.0)
      return;
   const double stops    = GetSymbolStopsPrice();
   const double open     = pos.PriceOpen();
   const double bid      = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   const double ask      = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   const double buffer   = GetSymbolSpreadPrice();
   const ENUM_POSITION_TYPE posType = pos.PositionType();
   const ulong parentTicket = ResolveHedgeParentTicket(hedgeTicket, pos.Comment());

   const double hedgeProfitPips = GetPositionProfitPips(hedgeTicket);
   const double hedgeLossPips   = GetPositionLossPips(hedgeTicket);
   const double parentLossPips  = (parentTicket > 0) ? GetPositionLossPips(parentTicket) : 0.0;

   // Soft close if broker SL missed: hedge -10pip -> close HEDGE only.
   if(!IsHedgeBreakEvenArmed(hedgeTicket) &&
      hedgeLossPips + 1e-9 >= TGM_HEDGE_OWN_LOSS_PIPS)
     {
      CloseHedgePosition(hedgeTicket, "HedgeMinus10Close");
      return;
     }

   const bool wantBE = (hedgeProfitPips + 1e-9 >= TGM_HEDGE_OWN_BE_PIPS) ||
                       (parentLossPips + 1e-9 >= TGM_LOSS_BE_PIPS);

   // Already BE-armed: keep BE SL; do not re-apply death SL.
   if(IsHedgeBreakEvenArmed(hedgeTicket))
     {
      const double curSL = pos.StopLoss();
      bool okBE = false;
      if(posType == POSITION_TYPE_BUY)
         okBE = (curSL != 0.0 && curSL + point >= open);
      else
         okBE = (curSL != 0.0 && curSL - point <= open);
      if(okBE)
         return;
     }

   if(wantBE || IsHedgeBreakEvenArmed(hedgeTicket))
     {
      if(hedgeProfitPips <= 0.0)
         return; // wrong-side BE blocked

      const double beSL = (posType == POSITION_TYPE_BUY) ? NormalizeDouble(open + buffer, digits)
                                                           : NormalizeDouble(open - buffer, digits);
      const double curSL  = pos.StopLoss();

      if(curSL != 0.0 && MathAbs(curSL - beSL) <= point)
        {
         if(!IsHedgeBreakEvenArmed(hedgeTicket))
            MarkHedgeBreakEvenArmed(hedgeTicket);
         return;
        }

      bool room = false;
      if(posType == POSITION_TYPE_BUY)
         room = ((bid - beSL) > stops + point);
      else
         room = ((beSL - ask) > stops + point);

      if(!room || IsTradeModifyCooldownActive())
         return;

      if(SafePositionModify(hedgeTicket, beSL, 0.0, "HedgeBE"))
        {
         MarkHedgeBreakEvenArmed(hedgeTicket);
         PrintFormat("TGM [R412]: Hedge #%I64u BE @ +%.0fpip (parentLoss=%.0f) | parent SL KEPT | SL=%.*f.",
                     hedgeTicket, TGM_HEDGE_OWN_BE_PIPS, parentLossPips, digits, beSL);
        }
      return;
     }

   // Not yet BE: keep death SL at hedge open ± 10pip (recovery close path).
   const double lossDist = TGM_HEDGE_OWN_LOSS_PIPS * pip;
   double wantSL = 0.0;
   bool room = false;
   if(posType == POSITION_TYPE_SELL)
     {
      wantSL = NormalizeDouble(open + lossDist, digits);
      room   = ((wantSL - ask) > stops);
     }
   else
     {
      wantSL = NormalizeDouble(open - lossDist, digits);
      room   = ((bid - wantSL) > stops);
     }

   const double curSL2 = pos.StopLoss();
   if(curSL2 != 0.0 && MathAbs(curSL2 - wantSL) <= point)
      return;
   if(!room || IsTradeModifyCooldownActive())
      return;

   if(SafePositionModify(hedgeTicket, wantSL, 0.0, "HedgeSL10"))
      PrintFormat("TGM [R412]: Hedge #%I64u death SL -%.0fpip @ %.*f (parent untouched).",
                  hedgeTicket, TGM_HEDGE_OWN_LOSS_PIPS, digits, wantSL);
  }

//--- Live hedge: BE/+10 and -10 close; entry-return optional (OFF).
void ManageLiveHedge(const ulong hedgeTicket)
  {
   if(hedgeTicket == 0)
      return;

   ManageHedgeStopLoss(hedgeTicket);

   if(InpHedgeReturnArmUSD <= 0.0)
      return;

   CPositionInfo pos;
   if(!pos.SelectByTicket(hedgeTicket))
      return;

   // Never entry-return-close before hedge has locked break-even at +$2.
   if(!IsHedgeBreakEvenArmed(hedgeTicket))
      return;

   const double profitUSD = GetPositionProfitUSD(hedgeTicket);
   const double armLevel  = InpHedgeReturnArmUSD;

   if(profitUSD >= armLevel)
      MarkHedgeReturnArmed(hedgeTicket);

   if(!IsHedgeReturnArmed(hedgeTicket))
      return;
   if(!IsPriceBackAtHedgeEntry(hedgeTicket))
      return;

   PrintFormat("TGM [HEDGE]: Entry-return -> close hedge #%I64u at open %.5f (parent ATR SL unchanged).",
               hedgeTicket, pos.PriceOpen());
   CloseHedgePosition(hedgeTicket, "EntryReturn");
  }

//--- R392 loss control: parent loss >=40pip -> BE on HEDGE only. Parent NEVER closed here.
//    Hedge may close at BE then re-open while parent still losing (>=30pip).
double GetTicketNetMoney(const ulong ticket)
  {
   CPositionInfo pos;
   if(!pos.SelectByTicket(ticket))
      return 0.0;
   return pos.Profit() + pos.Swap() + pos.Commission();
  }

double GetPositionLossPips(const ulong ticket)
  {
   const double p = GetPositionProfitPips(ticket);
   return (p < 0.0) ? -p : 0.0;
  }

bool ArmHedgeBreakEvenSL(const ulong hedgeTicket)
  {
   CPositionInfo pos;
   if(!pos.SelectByTicket(hedgeTicket))
      return false;
   if(!IsBotHedgePosition(hedgeTicket, pos.Comment()))
      return false;
   // Never BE-arm a losing hedge (wrong-side SL → invalid stops flood).
   if(GetPositionProfitUSD(hedgeTicket) <= 0.0)
      return false;

   const int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   const double open = pos.PriceOpen();
   const double buffer = GetSymbolSpreadPrice();
   const ENUM_POSITION_TYPE posType = pos.PositionType();
   const double beSL = (posType == POSITION_TYPE_BUY)
                        ? NormalizeDouble(open + buffer, digits)
                        : NormalizeDouble(open - buffer, digits);
   const double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   const double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   const double currentPrice = (posType == POSITION_TYPE_BUY) ? bid : ask;

   if(!IsBrokerStopDistanceOK(posType, currentPrice, beSL))
      return false;

   const double liveSL = pos.StopLoss();
   const double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   if(liveSL != 0.0 && MathAbs(liveSL - beSL) <= point)
     {
      MarkHedgeBreakEvenArmed(hedgeTicket);
      return true;
     }

   if(IsTradeModifyCooldownActive())
      return false;

   if(!SafePositionModify(hedgeTicket, beSL, 0.0, "R404_HedgeBE"))
      return false;

   MarkHedgeBreakEvenArmed(hedgeTicket);
   PrintFormat("TGM [R412]: Hedge #%I64u BE SL at %.*f (+%.0fpip / parent -%.0f) | parent pending SL KEPT.",
               hedgeTicket, digits, beSL, TGM_HEDGE_OWN_BE_PIPS, TGM_LOSS_BE_PIPS);
   return true;
  }

void ManageHedgeBreakEvenCycle()
  {
   if(!IsHedgeEngineActive())
      return;

   CPositionInfo pos;
   for(int i = 0; i < PositionsTotal(); i++)
     {
      if(IsStopped())
         return;
      if(!pos.SelectByIndex(i))
         continue;
      if(pos.Symbol() != _Symbol || pos.Magic() != (ulong)EXPERT_MAGIC)
         continue;
      if(!IsBotHedgePosition(pos.Ticket(), pos.Comment()))
         continue;

      const ulong hedge = pos.Ticket();
      const ulong parent = ResolveHedgeParentTicket(hedge, pos.Comment());
      if(parent > 0 && GetPositionProfitPips(parent) > 0.0)
        {
         TryReleaseStickyHedge(parent);
         continue;
        }

      // R412: arm BE when hedge +10pip OR parent -40pip.
      const bool hedgePlus10 = (GetPositionProfitPips(hedge) + 1e-9 >= TGM_HEDGE_OWN_BE_PIPS);
      const bool parentMinus40 = (parent > 0 && GetPositionLossPips(parent) + 1e-9 >= TGM_LOSS_BE_PIPS);
      if(!hedgePlus10 && !parentMinus40)
         continue;
      ArmHedgeBreakEvenSL(hedge);
     }
  }

//--- Individual recurrent hedge engine (pure $ / price based).
//    The hedge itself is closed automatically by its strict broker SL (-$),
//    so this loop only has to (a) tidy orphaned hedges, (b) keep each hedge's
//    strict SL in place, and (c) open a fresh hedge only when a parent crosses
//    back up to the $ loss trigger AFTER recovering below it (re-arm latch).
void ProcessHedgeProtectionEngine()
  {
   if(!IsHedgeEngineActive() || IsMarketValidationMode())
      return;

   const double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   if(point <= 0.0)
      return;

   SyncHedgeOrphanPositions();
   RebindOrphanHedgeLinks();
   AssignOrphanHedgesToParents();
   ConsolidateAllDuplicateHedges();

   ulong parentTickets[];
   CPositionInfo pos;

   // Keep strict SL on every live hedge before parent processing.
   for(int h = 0; h < PositionsTotal(); h++)
     {
      if(!pos.SelectByIndex(h))
         continue;
      if(pos.Symbol() != _Symbol || pos.Magic() != (ulong)EXPERT_MAGIC)
         continue;
      if(IsBotHedgePosition(pos.Ticket(), pos.Comment()))
         ManageLiveHedge(pos.Ticket());
     }

   ArrayResize(parentTickets, 0);

   for(int i = 0; i < PositionsTotal(); i++)
     {
      if(!pos.SelectByIndex(i))
         continue;
      if(pos.Symbol() != _Symbol || pos.Magic() != (ulong)EXPERT_MAGIC)
         continue;
      // JAIL: only OUR grid parents (manual trades never enter this list).
      if(!IsOurBotGridParent(pos.Ticket()))
         continue;

      const int n = ArraySize(parentTickets);
      ArrayResize(parentTickets, n + 1);
      parentTickets[n] = pos.Ticket();
     }

   for(int g = 0; g < ArraySize(parentTickets); g++)
     {
      if(IsStopped())
         return;

      const ulong parentTicket = parentTickets[g];

      TryReleaseHedgeChopFreeze(parentTicket);

      HealStaleHedgeLock(parentTicket);

      // Release sticky hedge when parent recovers (Mode A).
      if(IsHedgeEngineActive())
        {
         TryReleaseStickyHedge(parentTicket);
         EnsureHedgeProtectArmed(parentTicket);
        }

      const bool hedgeLive = HasHedge(parentTicket);

      // R404: keep parent pending SL forever (never strip). Hard-cap SL rewrite stays OFF.
      if(hedgeLive && HasFullHedgeCoverage(parentTicket))
         ApplyParentHardLossCap(parentTicket);

      // Hedge closed (broker BE / any): MANDATORY re-hedge same tick if still >= -30.
      if(WasHedgeLive(parentTicket) && !hedgeLive)
        {
         const int lifeSec = GetHedgeLifeSeconds(parentTicket);
         const double lossNow = GetPositionLossUSD(parentTicket);
         ClearHedgeLive(parentTicket);
         ClearLinkedHedgeTicket(parentTicket);
         ClearHedgeRearmState(parentTicket);
         ApplyHedgeRecycleCooldown(parentTicket, 0); // never delay
         SetHedgeTriggerReady(parentTicket, true);
         PrintFormat("TGM [R406]: Hedge gone on parent #%I64u (lived %ds, loss $%.2f) — forcing re-hedge.",
                     parentTicket, lifeSec, lossNow);
         ForceRehedgeIfParentStillInLoss(parentTicket, "HedgeGoneScan");
        }

      if(HasHedge(parentTicket))
        {
         MarkHedgeLive(parentTicket);
         ApplyParentHardLossCap(parentTicket);
         continue;
        }

      // No hedge: KEEP pending/shared SL until a hedge is live (do not leave naked).
      if(GetPositionLossPips(parentTicket) + 1e-9 < TGM_LOSS_HEDGE_PIPS)
         SetHedgeTriggerReady(parentTicket, true);

      if(IsProfitEngineArmed(parentTicket) && GetPositionProfitPips(parentTicket) > 0.0)
         continue;

      ForceRehedgeIfParentStillInLoss(parentTicket, "ProtectionLoop");
     }
  }

// --- Research Build 389: 30pip SL | +30 25%+BE | +50 +25% | +80 80% out | 20pip trail ---

string R375_BEAppliedKey(const ulong ticket)
  {
   return StringFormat("R375_BE_%I64u_%s_%I64u",
                       (ulong)AccountInfoInteger(ACCOUNT_LOGIN), _Symbol, ticket);
  }

bool R375_IsBEApplied(const ulong ticket)
  {
   return GlobalVariableCheck(R375_BEAppliedKey(ticket)) &&
          GlobalVariableGet(R375_BEAppliedKey(ticket)) > 0.5;
  }

void R375_MarkBEApplied(const ulong ticket)
  {
   GlobalVariableSet(R375_BEAppliedKey(ticket), 1.0);
  }

string R389_OrigVolKey(const ulong ticket)
  {
   return StringFormat("R389_OrigVol_%I64u_%s_%I64u",
                       (ulong)AccountInfoInteger(ACCOUNT_LOGIN), _Symbol, ticket);
  }

void R389_RememberOriginalVolume(const ulong ticket, const double volume)
  {
   if(ticket == 0 || volume <= 0.0)
      return;
   const string key = R389_OrigVolKey(ticket);
   if(GlobalVariableCheck(key))
     {
      const double stored = GlobalVariableGet(key);
      // Tester/runtime safety: if stale GV from an older run carried a smaller
      // lot for this ticket, refresh it to the current live volume so scale-out
      // percentages are based on the real original size.
      if(stored + 1e-12 >= volume)
         return;
     }
   GlobalVariableSet(key, volume);
  }

double R389_GetOriginalVolume(const ulong ticket, const double fallbackCurrent)
  {
   double stored = 0.0;
   if(GlobalVariableCheck(R389_OrigVolKey(ticket)))
      stored = GlobalVariableGet(R389_OrigVolKey(ticket));
   return MathMax(stored, fallbackCurrent);
  }

string R389_StageKey(const ulong ticket, const int stage)
  {
   return StringFormat("R389_Stage%d_%I64u_%s_%I64u",
                       stage, (ulong)AccountInfoInteger(ACCOUNT_LOGIN), _Symbol, ticket);
  }

bool R389_IsStageDone(const ulong ticket, const int stage)
  {
   return GlobalVariableCheck(R389_StageKey(ticket, stage)) &&
          GlobalVariableGet(R389_StageKey(ticket, stage)) > 0.5;
  }

void R389_MarkStageDone(const ulong ticket, const int stage)
  {
   GlobalVariableSet(R389_StageKey(ticket, stage), 1.0);
  }

bool CloseGridPositionProfit(const ulong ticket, const string reason)
  {
   if(!PreProtectionTradeGuard("PositionScaleOut"))
      return false;
   CPositionInfo pos;
   if(!pos.SelectByTicket(ticket) || pos.Symbol() != _Symbol || pos.Magic() != (ulong)EXPERT_MAGIC)
      return false;
   const double vol = pos.Volume();
   if(!ExecuteTradeOp("PositionClose(PROFIT)", g_trade.PositionClose(ticket),
                      StringFormat("ticket=%I64u vol=%.2f reason=%s", ticket, vol, reason)))
      return false;
   PrintFormat("TGM [R398]: BOOKED profit close #%I64u (%s) vol=%.2f", ticket, reason, vol);
   return true;
  }

// Close a fixed % of live volume. Min-lot positions cannot partial — full close books the profit.
bool ExecutePartialCloseOfOriginal(const ulong ticket, const double originalVol, const double pctOfOriginal)
  {
   if(!PreProtectionTradeGuard("PositionScaleOut"))
      return false;
   if(pctOfOriginal <= 0.0)
      return false;

   CPositionInfo pos;
   if(!pos.SelectByTicket(ticket) || pos.Symbol() != _Symbol || pos.Magic() != (ulong)EXPERT_MAGIC)
      return false;

   const double currentLot = pos.Volume();
   const double volMin  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   const double volStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   if(currentLot <= 0.0 || volStep <= 0.0)
      return false;

   // 0.01 (broker min) cannot close 25% — that left 2294-pip winners floating.
   if(currentLot <= volMin + 1e-12)
      return CloseGridPositionProfit(ticket, "MinLotFullBook");

   const double working = MathMax(originalVol, currentLot);
   double closeLot = NormalizeVolume(working * (pctOfOriginal / 100.0));
   if(closeLot < volMin - 1e-12)
      closeLot = volMin;

   if(closeLot >= currentLot - volMin + 1e-12)
      return CloseGridPositionProfit(ticket, "ScaleOutRemainder");

   const ENUM_POSITION_TYPE posType = pos.PositionType();
   const string opLabel = (posType == POSITION_TYPE_BUY) ? "PositionScaleOut(BUY)" : "PositionScaleOut(SELL)";
   if(!ExecuteTradeOp(opLabel, g_trade.PositionClosePartial(ticket, closeLot),
                      StringFormat("ticket=%I64u close=%.2f (%.0f%% of %.2f)",
                                   ticket, closeLot, pctOfOriginal, working)))
      return CloseGridPositionProfit(ticket, "PartialFailedFullBook");

   if(!pos.SelectByTicket(ticket))
      return true;
   return (pos.Volume() + 1e-12 < currentLot);
  }

// Scale out so remaining volume ≈ remainPct% of original (stage 3: keep 20% runner).
bool ExecuteScaleOutToRemainPercent(const ulong ticket, const double originalVol, const double remainPct)
  {
   if(!PreProtectionTradeGuard("PositionScaleOut"))
      return false;

   CPositionInfo pos;
   if(!pos.SelectByTicket(ticket) || pos.Symbol() != _Symbol || pos.Magic() != (ulong)EXPERT_MAGIC)
      return false;

   const double currentLot = pos.Volume();
   const double volMin  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   const double volStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   if(currentLot <= volMin + 1e-12 || volStep <= 0.0 || originalVol <= 0.0)
      return CloseGridPositionProfit(ticket, "ScaleOutMinLot");

   double targetRemain = NormalizeVolume(originalVol * (remainPct / 100.0));
   if(targetRemain < volMin)
      targetRemain = volMin;

   if(currentLot <= targetRemain + 1e-12)
      return true;

   double closeLot = NormalizeVolume(currentLot - targetRemain);
   double remainLot = NormalizeDouble(currentLot - closeLot, 8);
   if(remainLot < volMin - 1e-12)
     {
      closeLot = NormalizeVolume(currentLot - volMin);
      remainLot = NormalizeDouble(currentLot - closeLot, 8);
     }
   if(closeLot < volMin - 1e-12 || closeLot >= currentLot - 1e-12)
      return false;

   const ENUM_POSITION_TYPE posType = pos.PositionType();
   const string opLabel = (posType == POSITION_TYPE_BUY) ? "PositionScaleOut(BUY)" : "PositionScaleOut(SELL)";
   if(!ExecuteTradeOp(opLabel, g_trade.PositionClosePartial(ticket, closeLot),
                      StringFormat("ticket=%I64u close=%.2f keep~%.2f (%.0f%% of orig %.2f)",
                                   ticket, closeLot, remainLot, remainPct, originalVol)))
      return false;

   if(!pos.SelectByTicket(ticket))
      return false;
   return (pos.Volume() + 1e-12 < currentLot);
  }

bool R389_ApplyBreakEven(const ulong ticket, const ENUM_POSITION_TYPE posType,
                         const double currentPrice, const double beSL)
  {
   if(!Enable_BreakEven || R375_IsBEApplied(ticket))
      return false;
   if(!IsBrokerStopDistanceOK(posType, currentPrice, beSL))
      return false;

   CPositionInfo pos;
   if(!pos.SelectByTicket(ticket))
      return false;
   // Profit method: BE only — never keep/restore ATR TP (runner trails).
   if(!SafePositionModify(ticket, beSL, 0.0, "R389_BE"))
      return false;

   R375_MarkBEApplied(ticket);
   MarkProfitEngineArmed(ticket);
   PrintFormat("TGM [R400]: %s #%I64u BE locked (TP stripped).",
               (posType == POSITION_TYPE_BUY) ? "BUY" : "SELL", ticket);
   return true;
  }

void ManagePositionTradeLifecycle(const ulong ticket)
  {
   if(ticket == 0)
      return;
   if(!PreProtectionTradeGuard("PositionLifecycle"))
      return;

   CPositionInfo pos;
   if(!pos.SelectByTicket(ticket))
      return;
   if(!IsOurBotGridParent(ticket))
      return;

   RememberParentPendingSL(ticket);
   R389_RememberOriginalVolume(ticket, pos.Volume());
   const double origVol = R389_GetOriginalVolume(ticket, pos.Volume());

   const double profitPips = GetPositionProfitPips(ticket);
   const ENUM_POSITION_TYPE posType = pos.PositionType();
   const int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   const double openPrice = pos.PriceOpen();
   const double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   const double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   const double currentPrice = (posType == POSITION_TYPE_BUY) ? bid : ask;
   const double buffer = GetSymbolSpreadPrice();
   const double beSL = (posType == POSITION_TYPE_BUY) ? NormalizeDouble(openPrice + buffer, digits)
                                                      : NormalizeDouble(openPrice - buffer, digits);
   const double pip = Phase17_GetPipSize();
   if(pip <= 0.0)
      return;

   // R404: parent pending SL stays until broker hit. Never strip on hedge open / BE.

   // R415: +30 pip -> FULL book immediately (no partial, no runner float).
   if(profitPips + 1e-9 >= TGM_STAGE1_AT_PIPS)
     {
      if(!pos.SelectByTicket(ticket))
         return;
      if(pos.TakeProfit() > 0.0)
         StripPositionTakeProfit(ticket, "ProfitMethodStart");
      if(CloseGridPositionProfit(ticket, "R415_FullBook30"))
        {
         R389_MarkStageDone(ticket, 1);
         R389_MarkStageDone(ticket, 2);
         R389_MarkStageDone(ticket, 3);
         R389_MarkStageDone(ticket, 4);
         MarkProfitEngineArmed(ticket);
         PrintFormat("TGM [R415]: %s #%I64u +%.1fpip -> FULL booked (balance sync).",
                     (posType == POSITION_TYPE_BUY) ? "BUY" : "SELL", ticket, profitPips);
        }
     }
  }

//--- Watchdog: any grid winner +30 -> FULL close (R415).
void ForceBookStuckFloatingWinners()
  {
   CPositionInfo pos;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(!pos.SelectByIndex(i))
         continue;
      if(pos.Symbol() != _Symbol || pos.Magic() != (ulong)EXPERT_MAGIC)
         continue;
      const ulong ticket = pos.Ticket();
      if(!IsOurBotGridParent(ticket))
         continue;

      const double profitPips = GetPositionProfitPips(ticket);
      if(profitPips + 1e-9 < TGM_STAGE1_AT_PIPS)
         continue;

      if(pos.TakeProfit() > 0.0)
         StripPositionTakeProfit(ticket, "WatchdogStripTP");
      if(CloseGridPositionProfit(ticket, "WatchdogFull30"))
        {
         R389_MarkStageDone(ticket, 1);
         R389_MarkStageDone(ticket, 2);
         R389_MarkStageDone(ticket, 3);
         R389_MarkStageDone(ticket, 4);
         MarkProfitEngineArmed(ticket);
         PrintFormat("TGM [R415]: WATCHDOG FULL #%I64u @ +%.1fpip.", ticket, profitPips);
        }
     }
  }

void UniversalGoldTrailingEngine()
  {
   ulong tickets[];
   CPositionInfo pos;
   ArrayResize(tickets, 0);

   const int total = PositionsTotal();
   for(int i = 0; i < total; i++)
     {
      if(!pos.SelectByIndex(i))
         continue;
      if(pos.Symbol() != _Symbol || pos.Magic() != (ulong)EXPERT_MAGIC)
         continue;
      if(IsBotHedgePosition(pos.Ticket(), pos.Comment()))
         continue;

      const int n = ArraySize(tickets);
      ArrayResize(tickets, n + 1);
      tickets[n] = pos.Ticket();
     }

   for(int j = 0; j < ArraySize(tickets); j++)
     {
      if(IsStopped())
         return;
      ManagePositionTradeLifecycle(tickets[j]);
     }

   ForceBookStuckFloatingWinners();
  }

void CleanDeadGlobalVariables()
  {
   const string partPrefix = StringFormat("TGM_Part_%I64u_%s_",
                                          (ulong)AccountInfoInteger(ACCOUNT_LOGIN),
                                          _Symbol);
   const string peakPrefix = StringFormat("TGM_Peak_%I64u_%s_",
                                          (ulong)AccountInfoInteger(ACCOUNT_LOGIN),
                                          _Symbol);
   const string hedgePrefix = StringFormat("TGM_Hedge_%I64u_%s_",
                                             (ulong)AccountInfoInteger(ACCOUNT_LOGIN),
                                             _Symbol);
   const string bePendingPrefix = StringFormat("TGM_BEPend_%I64u_%s_",
                                               (ulong)AccountInfoInteger(ACCOUNT_LOGIN),
                                               _Symbol);
   const string hedgePeakPrefix = StringFormat("TGM_HedgePk_%I64u_%s_",
                                               (ulong)AccountInfoInteger(ACCOUNT_LOGIN),
                                               _Symbol);
   const string armedPrefix = StringFormat("TGM_Armed_%I64u_%s_",
                                           (ulong)AccountInfoInteger(ACCOUNT_LOGIN),
                                           _Symbol);
   const string runnerPrefix = StringFormat("TGM_P28A_Runner_%I64u_%s_",
                                            (ulong)AccountInfoInteger(ACCOUNT_LOGIN),
                                            _Symbol);
   const string hedgeRearmPrefix = StringFormat("TGM_HedgeRearm_%I64u_%s_",
                                                (ulong)AccountInfoInteger(ACCOUNT_LOGIN),
                                                _Symbol);
   const string hedgeLivePrefix = StringFormat("TGM_HedgeLive_%I64u_%s_",
                                               (ulong)AccountInfoInteger(ACCOUNT_LOGIN),
                                               _Symbol);
   const string hedgeTrigReadyPrefix = StringFormat("TGM_HedgeTrigReady_%I64u_%s_",
                                                    (ulong)AccountInfoInteger(ACCOUNT_LOGIN),
                                                    _Symbol);
   const string hedgeBEPrefix = StringFormat("TGM_HBE_%I64u_%s_",
                                             (ulong)AccountInfoInteger(ACCOUNT_LOGIN),
                                             _Symbol);
   const string hedgeRetPrefix = StringFormat("TGM_HRet_%I64u_%s_",
                                              (ulong)AccountInfoInteger(ACCOUNT_LOGIN),
                                              _Symbol);
   const string gridStatePrefix = StringFormat("TGM_GridState_%I64u_%s_",
                                               (ulong)AccountInfoInteger(ACCOUNT_LOGIN),
                                               _Symbol);
   const string gridTicketPrefix = StringFormat("TGM_GridTicket_%I64u_%s_",
                                                (ulong)AccountInfoInteger(ACCOUNT_LOGIN),
                                                _Symbol);
   const string r373SecondPrefix = StringFormat("R373_2nd_%I64u_%s_",
                                                (ulong)AccountInfoInteger(ACCOUNT_LOGIN),
                                                _Symbol);
   const string r373PeakPrefix = StringFormat("R373_Peak_%I64u_%s_",
                                               (ulong)AccountInfoInteger(ACCOUNT_LOGIN),
                                               _Symbol);
   const string r375BEPrefix   = StringFormat("R375_BE_%I64u_%s_",
                                               (ulong)AccountInfoInteger(ACCOUNT_LOGIN),
                                               _Symbol);
   const string r375PartPrefix = StringFormat("R375_Part_%I64u_%s_",
                                               (ulong)AccountInfoInteger(ACCOUNT_LOGIN),
                                               _Symbol);
   CPositionInfo pos;

   for(int i = GlobalVariablesTotal() - 1; i >= 0; i--)
     {
      string name = GlobalVariableName(i);
      bool isPart = (StringFind(name, partPrefix) == 0);
      bool isPeak = (StringFind(name, peakPrefix) == 0);
      bool isHedge = (StringFind(name, hedgePrefix) == 0);
      bool isBePending = (StringFind(name, bePendingPrefix) == 0);
      bool isHedgePeak = (StringFind(name, hedgePeakPrefix) == 0);
      bool isArmed = (StringFind(name, armedPrefix) == 0);
      bool isRunner = (StringFind(name, runnerPrefix) == 0);
      bool isHedgeRearm = (StringFind(name, hedgeRearmPrefix) == 0);
      bool isHedgeLive = (StringFind(name, hedgeLivePrefix) == 0);
      bool isHedgeTrigReady = (StringFind(name, hedgeTrigReadyPrefix) == 0);
      bool isHedgeBE = (StringFind(name, hedgeBEPrefix) == 0);
      bool isHedgeRet = (StringFind(name, hedgeRetPrefix) == 0);
      bool isGridState = (StringFind(name, gridStatePrefix) == 0);
      bool isGridTicket = (StringFind(name, gridTicketPrefix) == 0);
      bool isR373Second = (StringFind(name, r373SecondPrefix) == 0);
      bool isR373Peak   = (StringFind(name, r373PeakPrefix) == 0);
      bool isR375BE     = (StringFind(name, r375BEPrefix) == 0);
      bool isR375Part   = (StringFind(name, r375PartPrefix) == 0);
      if(!isPart && !isPeak && !isHedge && !isBePending && !isHedgePeak && !isArmed && !isRunner &&
         !isHedgeRearm && !isHedgeLive && !isHedgeTrigReady && !isHedgeBE && !isHedgeRet &&
         !isGridState && !isGridTicket && !isR373Second && !isR373Peak && !isR375BE && !isR375Part)
         continue;

      int prefixLen = 0;
      if(isPart) prefixLen = StringLen(partPrefix);
      else if(isPeak) prefixLen = StringLen(peakPrefix);
      else if(isBePending) prefixLen = StringLen(bePendingPrefix);
      else if(isHedgePeak) prefixLen = StringLen(hedgePeakPrefix);
      else if(isArmed) prefixLen = StringLen(armedPrefix);
      else if(isRunner) prefixLen = StringLen(runnerPrefix);
      else if(isHedgeRearm) prefixLen = StringLen(hedgeRearmPrefix);
      else if(isHedgeLive) prefixLen = StringLen(hedgeLivePrefix);
      else if(isHedgeTrigReady) prefixLen = StringLen(hedgeTrigReadyPrefix);
      else if(isHedgeBE) prefixLen = StringLen(hedgeBEPrefix);
      else if(isHedgeRet) prefixLen = StringLen(hedgeRetPrefix);
      else if(isGridState) prefixLen = StringLen(gridStatePrefix);
      else if(isGridTicket) prefixLen = StringLen(gridTicketPrefix);
      else if(isR373Second) prefixLen = StringLen(r373SecondPrefix);
      else if(isR373Peak)   prefixLen = StringLen(r373PeakPrefix);
      else if(isR375BE)     prefixLen = StringLen(r375BEPrefix);
      else if(isR375Part)   prefixLen = StringLen(r375PartPrefix);
      else prefixLen = StringLen(hedgePrefix);
      if(isGridState)
         continue;
      if(isGridTicket)
        {
         const ulong trackedTicket = (ulong)GlobalVariableGet(name);
         if(trackedTicket == 0 || (!OrderSelect(trackedTicket) && !pos.SelectByTicket(trackedTicket)))
            GlobalVariableDel(name);
         continue;
        }
      const string ticketStr = StringSubstr(name, prefixLen);
      const ulong ticket = (ulong)StringToInteger(ticketStr);
      if(ticket == 0)
        {
         GlobalVariableDel(name);
         continue;
        }

      if(isHedge)
        {
         const ulong hedgeTicket = (ulong)GlobalVariableGet(name);
         CPositionInfo hedgePos;
         if(!pos.SelectByTicket(ticket) || !hedgePos.SelectByTicket(hedgeTicket))
            GlobalVariableDel(name);
         continue;
        }

      if(!pos.SelectByTicket(ticket))
         GlobalVariableDel(name);
     }
  }

//+------------------------------------------------------------------+
//| Dashboard UI                                                     |
//+------------------------------------------------------------------+
bool IsDashboardSymbolMatch(const string dealSymbol)
  {
   if(dealSymbol == _Symbol)
      return true;

   const int chartLen = StringLen(_Symbol);
   const int dealLen  = StringLen(dealSymbol);
   if(chartLen > 1 && dealLen > 1)
     {
      const string chartTrim = StringSubstr(_Symbol, 0, chartLen - 1);
      const string dealTrim  = StringSubstr(dealSymbol, 0, dealLen - 1);
      if(chartTrim == dealTrim && StringLen(chartTrim) >= 3)
         return true;
     }

   return false;
  }

bool IsBotClosingDeal(const long entry)
  {
   return (entry == DEAL_ENTRY_OUT || entry == DEAL_ENTRY_OUT_BY || entry == DEAL_ENTRY_INOUT);
  }

bool GetTradeSessionWindow(datetime &fromOut, datetime &toOut, bool &sessionOpenOut)
  {
   const datetime now = TimeTradeServer();
   MqlDateTime dt;
   TimeToStruct(now, dt);

   datetime lastFrom = 0;
   datetime lastTo   = 0;

   for(uint session = 0; session < 32; session++)
     {
      datetime from = 0, to = 0;
      if(!SymbolInfoSessionTrade(_Symbol, (ENUM_DAY_OF_WEEK)dt.day_of_week, session, from, to))
         break;

      datetime sessFrom = SessionBoundaryForToday(from, now);
      datetime sessTo   = SessionBoundaryForToday(to, now);
      if(sessTo < sessFrom)
         sessTo += 86400;

      if(now >= sessFrom && now <= sessTo)
        {
         fromOut = sessFrom;
         toOut   = sessTo;
         sessionOpenOut = true;
         return true;
        }

      if(now > sessTo && sessTo > lastTo)
        {
         lastFrom = sessFrom;
         lastTo   = sessTo;
        }
     }

   if(lastFrom > 0)
     {
      fromOut = lastFrom;
      toOut   = lastTo;
      sessionOpenOut = false;
      return true;
     }

   fromOut = iTime(_Symbol, PERIOD_D1, 0);
   toOut   = now;
   sessionOpenOut = IsSymbolTradeSessionOpenNow();
   return (fromOut > 0);
  }

bool IsPositionIdentifierStillOpen(const long positionId)
  {
   CPositionInfo pos;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(!pos.SelectByIndex(i))
         continue;
      if(pos.Symbol() != _Symbol || pos.Magic() != (ulong)EXPERT_MAGIC)
         continue;
      if((long)pos.Identifier() == positionId)
         return true;
     }
   return false;
  }

bool IsDashboardDealRelevant(const ulong ticket)
  {
   if(ticket == 0)
      return false;

   if(!IsDashboardSymbolMatch(HistoryDealGetString(ticket, DEAL_SYMBOL)))
      return false;

   if((long)HistoryDealGetInteger(ticket, DEAL_MAGIC) != EXPERT_MAGIC)
      return false;

   return true;
  }

double GetDashboardDealNetProfit(const ulong ticket)
  {
   return HistoryDealGetDouble(ticket, DEAL_PROFIT)
        + HistoryDealGetDouble(ticket, DEAL_SWAP)
        + HistoryDealGetDouble(ticket, DEAL_COMMISSION);
  }

bool GetDashboardDayWindow(datetime &fromOut, datetime &toOut)
  {
   fromOut = iTime(_Symbol, PERIOD_D1, 0);
   if(fromOut <= 0)
     {
      MqlDateTime dt;
      TimeToStruct(TimeTradeServer(), dt);
      dt.hour = 0;
      dt.min  = 0;
      dt.sec  = 0;
      fromOut = StructToTime(dt);
     }
   toOut = TimeTradeServer();
   return (fromOut > 0 && toOut >= fromOut);
  }

bool IsDashboardGridDealComment(const ulong dealTicket)
  {
   if(dealTicket == 0 || !IsDashboardDealRelevant(dealTicket))
      return false;

   const string dealComment = HistoryDealGetString(dealTicket, DEAL_COMMENT);
   if(IsGridPositionComment(dealComment))
      return true;

   const long entry = HistoryDealGetInteger(dealTicket, DEAL_ENTRY);
   if(entry != DEAL_ENTRY_IN && entry != DEAL_ENTRY_INOUT)
      return false;

   const ulong orderTicket = (ulong)HistoryDealGetInteger(dealTicket, DEAL_ORDER);
   if(orderTicket == 0 || !HistoryOrderSelect(orderTicket))
      return false;

   return IsGridPositionComment(HistoryOrderGetString((long)orderTicket, ORDER_COMMENT));
  }

bool IsDashboardGridPositionId(const long positionId)
  {
   if(positionId == 0 || !HistorySelectByPosition(positionId))
      return false;

   const int dealsTotal = HistoryDealsTotal();
   for(int d = 0; d < dealsTotal; d++)
     {
      const ulong dealTicket = HistoryDealGetTicket(d);
      if(dealTicket == 0 || !IsDashboardDealRelevant(dealTicket))
         continue;

      if(IsDashboardGridDealComment(dealTicket))
         return true;

      const long entry = HistoryDealGetInteger(dealTicket, DEAL_ENTRY);
      if(entry != DEAL_ENTRY_IN && entry != DEAL_ENTRY_INOUT)
         continue;

      const string dealComment = HistoryDealGetString(dealTicket, DEAL_COMMENT);
      if(IsGridPositionComment(dealComment))
         return true;

      const ulong orderTicket = (ulong)HistoryDealGetInteger(dealTicket, DEAL_ORDER);
      if(orderTicket != 0 && HistoryOrderSelect(orderTicket))
        {
         if(IsGridPositionComment(HistoryOrderGetString((long)orderTicket, ORDER_COMMENT)))
            return true;
        }
     }
   return false;
  }

double SumGridPositionSessionNet(const long positionId, const datetime sessFrom, const datetime statsEnd)
  {
   if(positionId == 0 || !HistorySelectByPosition(positionId))
      return 0.0;

   double net = 0.0;
   const int dealsTotal = HistoryDealsTotal();
   for(int d = 0; d < dealsTotal; d++)
     {
      const ulong dealTicket = HistoryDealGetTicket(d);
      if(dealTicket == 0 || !IsDashboardDealRelevant(dealTicket))
         continue;

      const datetime dealTime = (datetime)HistoryDealGetInteger(dealTicket, DEAL_TIME);
      if(dealTime < sessFrom || dealTime > statsEnd)
         continue;

      net += GetDashboardDealNetProfit(dealTicket);
     }
   return net;
  }

bool IsSessionPositionIdSeen(const long positionId, const long &seenIds[])
  {
   for(int i = 0; i < ArraySize(seenIds); i++)
     {
      if(seenIds[i] == positionId)
         return true;
     }
   return false;
  }

bool IsDashboardGridEntryDeal(const ulong dealTicket)
  {
   if(dealTicket == 0 || !IsDashboardDealRelevant(dealTicket))
      return false;

   const long entry = HistoryDealGetInteger(dealTicket, DEAL_ENTRY);
   if(entry != DEAL_ENTRY_IN && entry != DEAL_ENTRY_INOUT)
      return false;

   return IsDashboardGridDealComment(dealTicket);
  }

bool IsDashboardGridClosingDeal(const ulong dealTicket)
  {
   if(dealTicket == 0 || !IsDashboardDealRelevant(dealTicket))
      return false;

   const long entry = HistoryDealGetInteger(dealTicket, DEAL_ENTRY);
   return IsBotClosingDeal(entry);
  }

bool AddUniquePositionId(const long positionId, long &ids[])
  {
   if(positionId == 0)
      return false;

   for(int i = 0; i < ArraySize(ids); i++)
     {
      if(ids[i] == positionId)
         return false;
     }

   const int n = ArraySize(ids);
   ArrayResize(ids, n + 1);
   ids[n] = positionId;
   return true;
  }

void CollectDashboardTradeStats(double &sessionProfit, int &openGridTrades, int &openHedgeTrades, int &sessionOpenedGrid, int &sessionClosedTotal, int &sessionClosedWins, int &sessionClosedLosses)
  {
   sessionProfit        = 0.0;
   openGridTrades       = 0;
   openHedgeTrades      = 0;
   sessionOpenedGrid    = 0;
   sessionClosedTotal   = 0;
   sessionClosedWins    = 0;
   sessionClosedLosses  = 0;

   datetime dayFrom = 0, dayTo = 0;
   if(!GetDashboardDayWindow(dayFrom, dayTo))
      return;

   CPositionInfo pos;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(!pos.SelectByIndex(i))
         continue;
      if(pos.Symbol() != _Symbol || pos.Magic() != (ulong)EXPERT_MAGIC)
         continue;

      if(IsBotHedgePosition(pos.Ticket(), pos.Comment()))
        {
         openHedgeTrades++;
         continue;
        }

      // Any other EA-magic position is a grid trade (comment may be broker-stripped).
      sessionProfit += pos.Profit() + pos.Swap();
      openGridTrades++;
     }

   if(!HistorySelect(dayFrom, dayTo))
      return;

   // ---- Single pass: capture EVERY relevant deal of today into memory ----
   // We never call HistoryOrderSelect()/HistorySelectByPosition() during this
   // loop, because either would swap the history cache and break
   // HistoryDealsTotal()/HistoryDealGetTicket() mid-iteration.
   long   dPos[];      // position id of the deal
   double dNet[];      // profit + swap + commission
   long   dEntry[];    // DEAL_ENTRY_*
   string dComment[];  // deal comment
   long   dOrder[];    // originating order ticket
   long   dMagic[];    // deal magic (0 for manual-close deals)
   ArrayResize(dPos, 0); ArrayResize(dNet, 0); ArrayResize(dEntry, 0);
   ArrayResize(dComment, 0); ArrayResize(dOrder, 0); ArrayResize(dMagic, 0);

   // Capture by SYMBOL only (not magic): a position opened by the EA may be
   // closed manually, and that closing deal carries magic 0. Filtering by
   // magic here would hide the close and leave the trade stuck in "Opened".
   const int dealsTotal = HistoryDealsTotal();
   for(int d = 0; d < dealsTotal; d++)
     {
      const ulong dealTicket = HistoryDealGetTicket(d);
      if(dealTicket == 0)
         continue;
      if(!IsDashboardSymbolMatch(HistoryDealGetString(dealTicket, DEAL_SYMBOL)))
         continue;

      const long entry = HistoryDealGetInteger(dealTicket, DEAL_ENTRY);
      if(entry != DEAL_ENTRY_IN && entry != DEAL_ENTRY_INOUT &&
         entry != DEAL_ENTRY_OUT && entry != DEAL_ENTRY_OUT_BY)
         continue;

      const datetime dealTime = (datetime)HistoryDealGetInteger(dealTicket, DEAL_TIME);
      if(dealTime < dayFrom || dealTime > dayTo)
         continue;

      const int n = ArraySize(dPos);
      ArrayResize(dPos, n + 1);   ArrayResize(dNet, n + 1);   ArrayResize(dEntry, n + 1);
      ArrayResize(dComment, n + 1); ArrayResize(dOrder, n + 1); ArrayResize(dMagic, n + 1);
      dPos[n]     = (long)HistoryDealGetInteger(dealTicket, DEAL_POSITION_ID);
      dNet[n]     = GetDashboardDealNetProfit(dealTicket);
      dEntry[n]   = entry;
      dComment[n] = HistoryDealGetString(dealTicket, DEAL_COMMENT);
      dOrder[n]   = (long)HistoryDealGetInteger(dealTicket, DEAL_ORDER);
      dMagic[n]   = (long)HistoryDealGetInteger(dealTicket, DEAL_MAGIC);
     }

   // ---- Build the unique position list from captured deals ----
   long uniquePos[];
   ArrayResize(uniquePos, 0);
   const int capturedDeals = ArraySize(dPos);
   for(int i = 0; i < capturedDeals; i++)
      AddUniquePositionId(dPos[i], uniquePos);

   // ---- Classify each unique position and aggregate its today P/L ----
   const int posCount = ArraySize(uniquePos);
   for(int u = 0; u < posCount; u++)
     {
      const long posId = uniquePos[u];

      bool   isGrid     = false;
      bool   isHedge    = false;
      bool   hasIn      = false;
      bool   hasOut     = false;
      bool   hasEaMagic = false;   // at least one deal opened/closed by THIS EA
      double net        = 0.0;
      long   anyOrder   = 0;

      for(int i = 0; i < capturedDeals; i++)
        {
         if(dPos[i] != posId)
            continue;

         net += dNet[i];
         if(dEntry[i] == DEAL_ENTRY_IN || dEntry[i] == DEAL_ENTRY_INOUT)
            hasIn = true;
         if(dEntry[i] == DEAL_ENTRY_OUT || dEntry[i] == DEAL_ENTRY_OUT_BY)
            hasOut = true;
         if(dMagic[i] == EXPERT_MAGIC)
            hasEaMagic = true;

         if(IsHedgePositionComment(dComment[i]))
            isHedge = true;
         else if(IsGridPositionComment(dComment[i]))
            isGrid = true;

         if(dOrder[i] != 0)
            anyOrder = dOrder[i];
        }

      // Order-comment fallback (safe now: deal iteration is finished).
      if(!isGrid && !isHedge && anyOrder != 0 && HistoryOrderSelect((ulong)anyOrder))
        {
         const string oc = HistoryOrderGetString((long)anyOrder, ORDER_COMMENT);
         if(IsHedgePositionComment(oc))
            isHedge = true;
         else if(IsGridPositionComment(oc))
            isGrid = true;
        }

      // Only count OUR grid trades (EA magic present + grid comment, not hedge,
      // not a pure manual trade).
      if(!hasEaMagic || !isGrid || isHedge)
         continue;

      if(hasIn)
         sessionOpenedGrid++;

      // Closed today = has a closing deal today AND not currently open.
      if(hasOut && !IsPositionIdentifierStillOpen(posId))
        {
         sessionClosedTotal++;
         sessionProfit += net;
         if(net > TGM_DASHBOARD_BE_EPSILON)
            sessionClosedWins++;
         else if(net < -TGM_DASHBOARD_BE_EPSILON)
            sessionClosedLosses++;
        }
     }
  }

string FormatDashboardMoney(const double value)
  {
   return StringFormat("$%.2f", value);
  }

color GetDailyProfitColor(const double dailyProfit)
  {
   if(dailyProfit > 0.0) return clrLime;
   if(dailyProfit < 0.0) return clrRed;
   return clrWhite;
  }

void SetUILabelColor(const string name, const color textColor)
  {
   const long chartId = ChartID();
   const string objName = UI_PREFIX + name;
   if(ObjectFind(chartId, objName) >= 0)
      ObjectSetInteger(chartId, objName, OBJPROP_COLOR, textColor);
  }

void InitDashboard()
  {
   g_uiMinimized = false;

   const color labelColor = C'180,165,120';

   CreateUIBackground("PanelBG", C'18,16,12', C'198,168,86');
   CreateUIBackground("PanelHeader", C'38,32,18', C'38,32,18');
   CreateUILabel("Title", "THE GOLD MIND", C'255,215,100', 11, "Arial Bold");
   CreateUILabel("Tagline", "Mind The Market - Mine The Gold", C'198,168,86', 7, "Arial");
   CreateUIMinButton("BtnMin", "[-]");
   RemoveLogoFrame();
   RemoveDashboardDragHandle();
   CreateUILogoFrame();

   if(!LoadDashboardLogo())
      CreateUILabel("Logo", "GM", clrGold, 10, "Arial Bold");

   CreateUISeparator("Sep0");
   CreateUILabel("LblAcc",   "Account", labelColor, 9, "Arial");
   CreateUILabel("LblRisk",  "Risk", labelColor, 9, "Arial");
   CreateUILabel("LblPos",   "Running", labelColor, 9, "Arial");
   CreateUILabel("LblTrail", "Trailing Engine", labelColor, 9, "Arial");

   CreateUISeparator("Sep1");
   CreateUILabel("LblLic",   "Market Status", labelColor, 9, "Arial");

   CreateUISeparator("Sep2");
   CreateUILabel("LblDaily",       "Today P/L", labelColor, 9, "Arial");
   CreateUILabel("LblSessionOpen", "Today Opened", labelColor, 9, "Arial");
   CreateUILabel("LblTotalTrades", "Still Open", labelColor, 9, "Arial");
   CreateUILabel("LblHedge",       "Hedge", labelColor, 9, "Arial");
   CreateUILabel("LblWinLoss",     "Today Closed", labelColor, 9, "Arial");

   CreateUILabel("ValAcc",   "---", clrLightSkyBlue, 9, "Arial Bold");
   CreateUILabel("ValRisk",  "---", clrGold, 9, "Arial Bold");
   CreateUILabel("ValPos",   "---", clrLime, 9, "Arial Bold");
   CreateUILabel("ValTrail", "---", C'120,210,150', 9, "Arial Bold");
   CreateUILabel("ValLic",   "CHECKING", clrLightGray, 9, "Arial Bold");
   CreateUILabel("ValDaily",       "---", clrWhite, 10, "Arial Bold");
   CreateUILabel("ValSessionOpen", "---", clrWhite, 9, "Arial Bold");
   CreateUILabel("ValTotalTrades", "---", clrWhite, 9, "Arial Bold");
   CreateUILabel("ValHedge",       "---", clrWhite, 9, "Arial Bold");
   CreateUILabel("ValWinLoss",     "---", clrWhite, 9, "Arial Bold");

   RenderDashboardLayout();
   UpdateDashboard(true);
  }

void RenderDashboardLayout()
  {
   const long chartId = ChartID();
   const int width  = TGM_PANEL_WIDTH;
   const int height = g_uiMinimized ? TGM_PANEL_HEIGHT_MIN : TGM_PANEL_HEIGHT_FULL;
   const long visibilityState = g_uiMinimized ? OBJ_NO_PERIODS : OBJ_ALL_PERIODS;
   
   ObjectSetInteger(chartId, UI_PREFIX + "PanelBG", OBJPROP_XDISTANCE, g_uiX);
   ObjectSetInteger(chartId, UI_PREFIX + "PanelBG", OBJPROP_YDISTANCE, g_uiY);
   ObjectSetInteger(chartId, UI_PREFIX + "PanelBG", OBJPROP_YSIZE, height);
   ObjectSetInteger(chartId, UI_PREFIX + "PanelBG", OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
   ObjectSetInteger(chartId, UI_PREFIX + "PanelBG", OBJPROP_BACK, false);
   ObjectSetInteger(chartId, UI_PREFIX + "PanelBG", OBJPROP_HIDDEN, false);
   ObjectSetInteger(chartId, UI_PREFIX + "PanelBG", OBJPROP_ZORDER, TGM_UI_Z_PANEL);

   ObjectSetInteger(chartId, UI_PREFIX + "PanelHeader", OBJPROP_XDISTANCE, g_uiX);
   ObjectSetInteger(chartId, UI_PREFIX + "PanelHeader", OBJPROP_YDISTANCE, g_uiY);
   ObjectSetInteger(chartId, UI_PREFIX + "PanelHeader", OBJPROP_XSIZE, width);
   ObjectSetInteger(chartId, UI_PREFIX + "PanelHeader", OBJPROP_YSIZE, TGM_HEADER_H);
   ObjectSetInteger(chartId, UI_PREFIX + "PanelHeader", OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
   ObjectSetInteger(chartId, UI_PREFIX + "PanelHeader", OBJPROP_ZORDER, TGM_UI_Z_PANEL + 1);

   ObjectSetInteger(chartId, UI_PREFIX + "LogoFrame", OBJPROP_XDISTANCE, g_uiX + TGM_LOGO_X_OFFSET - 2);
   ObjectSetInteger(chartId, UI_PREFIX + "LogoFrame", OBJPROP_YDISTANCE, g_uiY + TGM_LOGO_Y_OFFSET - 2);
   ObjectSetInteger(chartId, UI_PREFIX + "LogoFrame", OBJPROP_XSIZE, TGM_LOGO_W + 4);
   ObjectSetInteger(chartId, UI_PREFIX + "LogoFrame", OBJPROP_YSIZE, TGM_LOGO_H + 4);
   ObjectSetInteger(chartId, UI_PREFIX + "LogoFrame", OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
   ObjectSetInteger(chartId, UI_PREFIX + "LogoFrame", OBJPROP_ZORDER, 2);

   ObjectSetInteger(chartId, UI_PREFIX + "Logo", OBJPROP_XDISTANCE, g_uiX + TGM_LOGO_X_OFFSET);
   ObjectSetInteger(chartId, UI_PREFIX + "Logo", OBJPROP_YDISTANCE, g_uiY + TGM_LOGO_Y_OFFSET);
   ObjectSetInteger(chartId, UI_PREFIX + "Logo", OBJPROP_XSIZE, TGM_LOGO_W);
   ObjectSetInteger(chartId, UI_PREFIX + "Logo", OBJPROP_YSIZE, TGM_LOGO_H);
   ObjectSetInteger(chartId, UI_PREFIX + "Logo", OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
   ObjectSetInteger(chartId, UI_PREFIX + "Logo", OBJPROP_BACK, false);
   ObjectSetInteger(chartId, UI_PREFIX + "Logo", OBJPROP_HIDDEN, false);
   ObjectSetInteger(chartId, UI_PREFIX + "Logo", OBJPROP_ZORDER, TGM_UI_Z_LOGO);
   ObjectSetString(chartId, UI_PREFIX + "Logo", OBJPROP_BMPFILE, 0, LOGO_RESOURCE_PATH);
   ObjectSetString(chartId, UI_PREFIX + "Logo", OBJPROP_BMPFILE, 1, LOGO_RESOURCE_PATH);
   ObjectSetInteger(chartId, UI_PREFIX + "Logo", OBJPROP_STATE, false);
   
   ObjectSetInteger(chartId, UI_PREFIX + "Title", OBJPROP_XDISTANCE, g_uiX + TGM_TITLE_X_OFFSET);
   ObjectSetInteger(chartId, UI_PREFIX + "Title", OBJPROP_YDISTANCE, g_uiY + TGM_TITLE_Y_OFFSET);
   ObjectSetInteger(chartId, UI_PREFIX + "Title", OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);

   ObjectSetInteger(chartId, UI_PREFIX + "Tagline", OBJPROP_XDISTANCE, g_uiX + TGM_TITLE_X_OFFSET);
   ObjectSetInteger(chartId, UI_PREFIX + "Tagline", OBJPROP_YDISTANCE, g_uiY + TGM_TAGLINE_Y_OFFSET);
   ObjectSetInteger(chartId, UI_PREFIX + "Tagline", OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
   
   ObjectSetInteger(chartId, UI_PREFIX + "BtnMin", OBJPROP_XDISTANCE, g_uiX + width - 30);
   ObjectSetInteger(chartId, UI_PREFIX + "BtnMin", OBJPROP_YDISTANCE, g_uiY + 6);
   ObjectSetString(chartId, UI_PREFIX + "BtnMin", OBJPROP_TEXT, g_uiMinimized ? "[+]" : "[-]");
   ObjectSetInteger(chartId, UI_PREFIX + "BtnMin", OBJPROP_COLOR, g_uiMinimized ? clrLime : clrSilver);
   ObjectSetInteger(chartId, UI_PREFIX + "BtnMin", OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);

   string internalLabels[] = {"Sep0",
                              "LblAcc", "ValAcc", "LblRisk", "ValRisk", "LblPos", "ValPos",
                              "LblTrail", "ValTrail",
                              "Sep1", "LblLic", "ValLic",
                              "Sep2",
                              "LblDaily", "ValDaily", "LblSessionOpen", "ValSessionOpen",
                              "LblTotalTrades", "ValTotalTrades", "LblHedge", "ValHedge",
                              "LblWinLoss", "ValWinLoss"};

   int internalOffsetsY[] = {52,
                             60, 60, 82, 82, 104, 104,
                             126, 126,
                             150, 158, 158,
                             182,
                             190, 190, 212, 212,
                             234, 234, 256, 256,
                             278, 278};
   int internalOffsetsX[] = {12,
                             15, 140, 15, 140, 15, 140,
                             15, 140,
                             12, 15, 140,
                             12,
                             15, 140, 15, 140,
                             15, 140, 15, 140,
                             15, 140};

   int totalElements = ArraySize(internalLabels);
   for(int i = 0; i < totalElements; i++)
     {
      string objName = UI_PREFIX + internalLabels[i];
      ObjectSetInteger(chartId, objName, OBJPROP_XDISTANCE, g_uiX + internalOffsetsX[i]);
      ObjectSetInteger(chartId, objName, OBJPROP_YDISTANCE, g_uiY + internalOffsetsY[i]);
      ObjectSetInteger(chartId, objName, OBJPROP_TIMEFRAMES, visibilityState);
     }
     
   ChartRedraw(chartId);
  }

void EnsureDashboardPresent()
  {
   if(!ShouldRenderUI() || ObjectFind(ChartID(), UI_PREFIX + "PanelBG") >= 0)
      return;

   Print("The Gold Mind: Dashboard missing - rebuilding.");
   g_uiMinimized = false;
   InitDashboard();
   EnableDashboardChartEvents();
  }

void EnableDashboardChartEvents()
  {
   const long chartId = ChartID();
   ChartSetInteger(chartId, CHART_EVENT_MOUSE_MOVE, true);
   ChartSetInteger(chartId, CHART_FOREGROUND, false);
  }

bool IsPointInsideMinButton(const int mouseX, const int mouseY)
  {
   const int btnX = g_uiX + TGM_PANEL_WIDTH - 30;
   const int btnY = g_uiY + 4;
   return (mouseX >= btnX && mouseX <= btnX + 28 &&
           mouseY >= btnY && mouseY <= btnY + 22);
  }

bool IsPointInsideDashboardHeader(const int mouseX, const int mouseY)
  {
   const int headerWidth  = TGM_PANEL_WIDTH;
   const int headerHeight = TGM_HEADER_H;
   return (mouseX >= g_uiX && mouseX <= g_uiX + headerWidth &&
           mouseY >= g_uiY && mouseY <= g_uiY + headerHeight);
  }

void UpdateDashboard(const bool forceUpdate)
  {
   if(!ShouldRenderUI()) return;

   datetime now = TimeCurrent();
   if(!forceUpdate && now - g_lastDashboardUpdate < 1 && !g_isDragging) return;
   g_lastDashboardUpdate = now;

   string accNum   = IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN));
   string riskStr  = (RiskMode == RISK_AUTO_3_PERCENT_EQUITY) ? "Auto 3% Equity [R395]" : "Manual Lot [R395]";
   string trailStatus = Enable_BreakEven ? "25@30+25@50+80@80+20trail" : "OFF";
   string marketState = GetDashboardMarketStatus();

   double sessionProfit = 0.0;
   int openGridTrades = 0, openHedgeTrades = 0, sessionOpenedGrid = 0;
   int sessionClosedTotal = 0, sessionClosedWins = 0, sessionClosedLosses = 0;
   CollectDashboardTradeStats(sessionProfit, openGridTrades, openHedgeTrades, sessionOpenedGrid, sessionClosedTotal, sessionClosedWins, sessionClosedLosses);

   SetUILabelText("ValAcc", accNum);
   SetUILabelText("ValRisk", riskStr);
   SetUILabelText("ValPos", IntegerToString(openGridTrades));
   SetUILabelText("ValTrail", trailStatus);
   SetUILabelText("ValLic", marketState);
   SetUILabelColor("ValLic", GetMarketStatusColor(marketState));
   SetUILabelText("ValDaily", FormatDashboardMoney(sessionProfit));
   SetUILabelColor("ValDaily", GetDailyProfitColor(sessionProfit));
   SetUILabelText("ValSessionOpen", IntegerToString(sessionOpenedGrid));
   SetUILabelText("ValTotalTrades", IntegerToString(openGridTrades + openHedgeTrades));
   SetUILabelText("ValHedge", IntegerToString(openHedgeTrades));
   SetUILabelText("ValWinLoss", IntegerToString(sessionClosedTotal) + " (" +
                  IntegerToString(sessionClosedWins) + "W / " +
                  IntegerToString(sessionClosedLosses) + "L)");

   if(g_isDragging) RenderDashboardLayout();
  }

string GetDashboardMarketStatus()
  {
   if(g_emergencyKillSwitchActive || IsKillSwitchActiveToday())
      return "KILL SWITCH";

   if(g_accountProtectionActive)
      return "DD PROTECT";

   if(!IsStrategyTester() && IsDashboardMarketClosed())
      return GetDashboardClosedStatusLabel();

   if(IsPositionMgmtAllowed() && !IsServerTradePaused())
      return "OPEN";

   if(IsWeekendOrMarketClosed())
      return GetDashboardClosedStatusLabel();

   if(IsServerTradePaused())
      return "BROKER HALT";

   const string reason = GetAutoTradeBlockReason();
   if(reason != "")
      return "BLOCKED";

   return "PAUSED";
  }

color GetMarketStatusColor(const string status)
  {
   if(status == "OPEN")
      return clrLimeGreen;
   if(status == "DD PROTECT")
      return clrGold;
   if(status == "KILL SWITCH")
      return clrRed;
   if(status == "CLOSED" || status == "WEEKEND")
      return clrOrange;
   if(status == "BROKER HALT" || status == "BLOCKED")
      return clrTomato;
   return clrLightGray;
  }

void RemoveLogoFrame()
  {
   const long chartId = ChartID();
   const string objName = UI_PREFIX + "LogoFrame";
   if(ObjectFind(chartId, objName) >= 0)
      ObjectDelete(chartId, objName);
  }

//--- Resample the source logo (any size, e.g. 100x100) into a new resource
//    that is exactly the frame size, so MT5 shows the WHOLE image fitted to
//    the frame instead of cropping it (MT5 bitmap labels do not auto-scale).
bool BuildScaledLogoResource(const string srcResource, const int dstW, const int dstH)
  {
   if(dstW <= 0 || dstH <= 0)
      return false;

   uint src[];
   uint sw = 0, sh = 0;
   ResetLastError();
   if(!ResourceReadImage(srcResource, src, sw, sh) || sw == 0 || sh == 0)
      return false;

   uint dst[];
   if(ArrayResize(dst, dstW * dstH) != dstW * dstH)
      return false;

   for(int i = 0; i < dstW * dstH; i++)   // transparent background (letterbox)
      dst[i] = 0x00000000;

   // Detect whether the source actually carries an alpha channel. If NONE of
   // the pixels have alpha (opaque BMP), we must force alpha so it is visible;
   // if it does (transparent PNG), we keep it so the background stays clear.
   bool srcHasAlpha = false;
   for(int i = 0; i < (int)(sw * sh); i++)
     {
      if((src[i] & 0xFF000000) != 0)
        {
         srcHasAlpha = true;
         break;
        }
     }

   // Contain-fit: preserve aspect ratio, center inside the frame.
   double scale = MathMin((double)dstW / (double)sw, (double)dstH / (double)sh);
   int drawW = (int)MathRound((double)sw * scale);
   int drawH = (int)MathRound((double)sh * scale);
   if(drawW < 1) drawW = 1; if(drawW > dstW) drawW = dstW;
   if(drawH < 1) drawH = 1; if(drawH > dstH) drawH = dstH;
   const int offX = (dstW - drawW) / 2;
   const int offY = (dstH - drawH) / 2;

   for(int y = 0; y < drawH; y++)
     {
      int sy = (int)((long)y * (long)sh / (long)drawH);
      if(sy >= (int)sh) sy = (int)sh - 1;
      for(int x = 0; x < drawW; x++)
        {
         int sx = (int)((long)x * (long)sw / (long)drawW);
         if(sx >= (int)sw) sx = (int)sw - 1;

         uint px = src[sy * (int)sw + sx];
         if(!srcHasAlpha)                // opaque source -> make fully visible
            px |= 0xFF000000;
         dst[(offY + y) * dstW + (offX + x)] = px;
        }
     }

   return ResourceCreate(LOGO_FIT_RESOURCE, dst, dstW, dstH, 0, 0, dstW, COLOR_FORMAT_ARGB_NORMALIZE);
  }

bool LoadDashboardLogo()
  {
   // The embedded logo is pre-sized to the exact frame (42x42, 24-bit BMP
   // composited over the header colour) so MT5 renders it directly without any
   // runtime scaling. BMP is the most reliable format for OBJ_BITMAP_LABEL.
   if(CreateUIBitmap("Logo", LOGO_RESOURCE_PATH))
     {
      PrintFormat("The Gold Mind: Logo loaded from %s", LOGO_RESOURCE_PATH);
      return true;
     }
   Print("The Gold Mind: Logo embedded resource failed - using GM text badge.");
   return false;
  }

void DestroyAllChartDashboardUI()
  {
   const long chartId = ChartID();
   const string prefixes[] = {UI_PREFIX, UI_LEGACY_PREFIX_LOCK, UI_LEGACY_PREFIX_RTAS};

   for(int pass = 0; pass < 2; pass++)
     {
      const long targetChart = (pass == 0 ? chartId : 0);
      for(int i = ObjectsTotal(targetChart, 0, -1) - 1; i >= 0; i--)
        {
         const string name = ObjectName(targetChart, i, 0, -1);
         for(int p = 0; p < ArraySize(prefixes); p++)
           {
            if(StringFind(name, prefixes[p]) == 0)
              {
               ObjectDelete(targetChart, name);
               break;
              }
           }
        }
     }
   ChartRedraw(chartId);
  }

void CreateUIBackground(string name, color bg_color, color border_color)
  {
   const long chartId = ChartID();
   string objName = UI_PREFIX + name;
   if(ObjectFind(chartId, objName) >= 0) ObjectDelete(chartId, objName);
   
   if(!ObjectCreate(chartId, objName, OBJ_RECTANGLE_LABEL, 0, 0, 0))
     {
      PrintFormat("The Gold Mind: UI PanelBG create failed err=%d", GetLastError());
      return;
     }
   
   ObjectSetInteger(chartId, objName, OBJPROP_XDISTANCE, g_uiX);
   ObjectSetInteger(chartId, objName, OBJPROP_YDISTANCE, g_uiY);
   ObjectSetInteger(chartId, objName, OBJPROP_XSIZE, TGM_PANEL_WIDTH);
   ObjectSetInteger(chartId, objName, OBJPROP_YSIZE, TGM_PANEL_HEIGHT_FULL);
   ObjectSetInteger(chartId, objName, OBJPROP_BGCOLOR, bg_color);
   ObjectSetInteger(chartId, objName, OBJPROP_BORDER_COLOR, border_color);
   ObjectSetInteger(chartId, objName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(chartId, objName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(chartId, objName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(chartId, objName, OBJPROP_BACK, false);
   ObjectSetInteger(chartId, objName, OBJPROP_HIDDEN, false);
   ObjectSetInteger(chartId, objName, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
   ObjectSetInteger(chartId, objName, OBJPROP_ZORDER, TGM_UI_Z_PANEL);
  }

void CreateUILogoFrame()
  {
   const long chartId = ChartID();
   const string objName = UI_PREFIX + "LogoFrame";
   if(ObjectFind(chartId, objName) >= 0) ObjectDelete(chartId, objName);

   if(!ObjectCreate(chartId, objName, OBJ_RECTANGLE_LABEL, 0, 0, 0))
     {
      PrintFormat("The Gold Mind: LogoFrame create failed err=%d", GetLastError());
      return;
     }

   ObjectSetInteger(chartId, objName, OBJPROP_XSIZE, TGM_LOGO_W + 4);
   ObjectSetInteger(chartId, objName, OBJPROP_YSIZE, TGM_LOGO_H + 4);
   ObjectSetInteger(chartId, objName, OBJPROP_BGCOLOR, clrNONE);
   ObjectSetInteger(chartId, objName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(chartId, objName, OBJPROP_BORDER_COLOR, C'198,168,86');
   ObjectSetInteger(chartId, objName, OBJPROP_COLOR, C'198,168,86');
   ObjectSetInteger(chartId, objName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(chartId, objName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(chartId, objName, OBJPROP_BACK, false);
   ObjectSetInteger(chartId, objName, OBJPROP_HIDDEN, true);
   ObjectSetInteger(chartId, objName, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
   ObjectSetInteger(chartId, objName, OBJPROP_ZORDER, 2);
  }

void CreateUISeparator(string name)
  {
   const long chartId = ChartID();
   const string objName = UI_PREFIX + name;
   if(ObjectFind(chartId, objName) >= 0) ObjectDelete(chartId, objName);

   if(!ObjectCreate(chartId, objName, OBJ_RECTANGLE_LABEL, 0, 0, 0))
     {
      PrintFormat("The Gold Mind: UI separator create failed (%s) err=%d", name, GetLastError());
      return;
     }

   ObjectSetInteger(chartId, objName, OBJPROP_XSIZE, TGM_PANEL_WIDTH - 24);
   ObjectSetInteger(chartId, objName, OBJPROP_YSIZE, 1);
   ObjectSetInteger(chartId, objName, OBJPROP_BGCOLOR, C'198,168,86');
   ObjectSetInteger(chartId, objName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(chartId, objName, OBJPROP_BORDER_COLOR, C'212,175,55');
   ObjectSetInteger(chartId, objName, OBJPROP_COLOR, C'212,175,55');
   ObjectSetInteger(chartId, objName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(chartId, objName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(chartId, objName, OBJPROP_BACK, false);
   ObjectSetInteger(chartId, objName, OBJPROP_HIDDEN, true);
   ObjectSetInteger(chartId, objName, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
   ObjectSetInteger(chartId, objName, OBJPROP_ZORDER, TGM_UI_Z_LABELS);
  }

bool CreateUIBitmap(string name, string bmp_path)
  {
   const long chartId = ChartID();
   string objName = UI_PREFIX + name;
   if(ObjectFind(chartId, objName) >= 0) ObjectDelete(chartId, objName);
   
   ResetLastError();
   if(!ObjectCreate(chartId, objName, OBJ_BITMAP_LABEL, 0, 0, 0))
     {
      PrintFormat("The Gold Mind: Bitmap create failed for %s err=%d", bmp_path, GetLastError());
      return false;
     }

   ObjectSetInteger(chartId, objName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(chartId, objName, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
   ObjectSetInteger(chartId, objName, OBJPROP_XDISTANCE, g_uiX + TGM_LOGO_X_OFFSET);
   ObjectSetInteger(chartId, objName, OBJPROP_YDISTANCE, g_uiY + TGM_LOGO_Y_OFFSET);
   ObjectSetInteger(chartId, objName, OBJPROP_XSIZE, TGM_LOGO_W);
   ObjectSetInteger(chartId, objName, OBJPROP_YSIZE, TGM_LOGO_H);
   ObjectSetInteger(chartId, objName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(chartId, objName, OBJPROP_BACK, false);
   ObjectSetInteger(chartId, objName, OBJPROP_HIDDEN, false);
   ObjectSetInteger(chartId, objName, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
   ObjectSetInteger(chartId, objName, OBJPROP_ZORDER, TGM_UI_Z_LOGO);
   // OBJ_BITMAP_LABEL keeps TWO images: modifier 0 = ON(pressed) state,
   // modifier 1 = OFF(released) state. The object defaults to the OFF state,
   // so BOTH must be set or the label renders blank.
   ObjectSetString(chartId, objName, OBJPROP_BMPFILE, 0, bmp_path);
   ObjectSetString(chartId, objName, OBJPROP_BMPFILE, 1, bmp_path);
   ObjectSetInteger(chartId, objName, OBJPROP_STATE, false);
   ChartRedraw(chartId);
   return (ObjectFind(chartId, objName) >= 0);
  }

void CreateUIMinButton(string name, string text)
  {
   const long chartId = ChartID();
   string objName = UI_PREFIX + name;
   if(ObjectFind(chartId, objName) >= 0) ObjectDelete(chartId, objName);
   
   if(!ObjectCreate(chartId, objName, OBJ_BUTTON, 0, 0, 0))
     {
      PrintFormat("The Gold Mind: UI BtnMin create failed err=%d", GetLastError());
      return;
     }

   ObjectSetString(chartId, objName, OBJPROP_TEXT, text);
   ObjectSetInteger(chartId, objName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(chartId, objName, OBJPROP_XSIZE, 28);
   ObjectSetInteger(chartId, objName, OBJPROP_YSIZE, 22);
   ObjectSetInteger(chartId, objName, OBJPROP_BGCOLOR, C'45,38,22');
   ObjectSetInteger(chartId, objName, OBJPROP_BORDER_COLOR, C'198,168,86');
   ObjectSetInteger(chartId, objName, OBJPROP_COLOR, clrSilver);
   ObjectSetInteger(chartId, objName, OBJPROP_FONTSIZE, 10);
   ObjectSetString(chartId, objName, OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(chartId, objName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(chartId, objName, OBJPROP_STATE, false);
   ObjectSetInteger(chartId, objName, OBJPROP_BACK, false);
   ObjectSetInteger(chartId, objName, OBJPROP_HIDDEN, false);
   ObjectSetInteger(chartId, objName, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
   ObjectSetInteger(chartId, objName, OBJPROP_ZORDER, TGM_UI_Z_BUTTON);
  }

void RemoveDashboardDragHandle()
  {
   const long chartId = ChartID();
   const string objName = UI_PREFIX + "DragHdr";
   if(ObjectFind(chartId, objName) >= 0)
      ObjectDelete(chartId, objName);
  }

void CreateUILabel(string name, string text, color text_color, int font_size, string font_name="Arial")
  {
   const long chartId = ChartID();
   string objName = UI_PREFIX + name;
   if(ObjectFind(chartId, objName) >= 0) ObjectDelete(chartId, objName);
   
   if(!ObjectCreate(chartId, objName, OBJ_LABEL, 0, 0, 0))
     {
      PrintFormat("The Gold Mind: UI label create failed (%s) err=%d", name, GetLastError());
      return;
     }

   ObjectSetString(chartId, objName, OBJPROP_TEXT, text);
   ObjectSetInteger(chartId, objName, OBJPROP_COLOR, text_color);
   ObjectSetInteger(chartId, objName, OBJPROP_FONTSIZE, font_size);
   ObjectSetString(chartId, objName, OBJPROP_FONT, font_name);
   ObjectSetInteger(chartId, objName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(chartId, objName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(chartId, objName, OBJPROP_BACK, false);
   ObjectSetInteger(chartId, objName, OBJPROP_HIDDEN, false);
   ObjectSetInteger(chartId, objName, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
   ObjectSetInteger(chartId, objName, OBJPROP_ZORDER, TGM_UI_Z_LABELS);
  }

void SetUILabelText(string name, string text)
  {
   const long chartId = ChartID();
   string objName = UI_PREFIX + name;
   if(ObjectFind(chartId, objName) < 0)
      return;
   ObjectSetString(chartId, objName, OBJPROP_TEXT, text);
  }

