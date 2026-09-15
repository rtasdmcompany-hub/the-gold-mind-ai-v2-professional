//+------------------------------------------------------------------+
//|                                                The_Gold_Mind.mq5 |
//|                        The Gold Mind - H4 Grid Expert Advisor     |
//|  RESEARCH BUILD 448 - 2% equity risk | locked range BOTH preset |
//+------------------------------------------------------------------+
#property copyright "RTAS Digital Marketing Company | RTAS Group of Companies"
#property version   "2.155"
#property description "The Gold Mind Research - H4 range router | 2 methods BOTH sides."
#property description "R448: 2% EQUITY risk/trade | SmallRange=250 | DIRECTIONAL_AUTO=false."
#property description "R447: SL:TP 1:1.5 | L1 100/150 L2 60/90 L3 40/60."
#property description "R445/R444: BOTH sides + pending restore while EA on chart."
#property link      "https://www.mql5.com/en/users/rtas"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <AI/ExecutionSupervisor/Phase11B/CGmEAPreActivationBridge.mqh>
#include <AI/InstitutionalValidation/CGmPhase14ValidationBridge.mqh>

//--- Core constants
#define EXPERT_MAGIC              112234
#define GRID_LINE_PREFIX          "TGM_GL_"
#define UI_PREFIX                 "TGM_UI_"
#define TGM_BE_STRATEGY_POINTS      500.0
#define TGM_TRAIL_STRATEGY_POINTS   300.0
#define TGM_PARTIAL_BE_TRIGGER_PIPS 30.0   // +30 pips -> FULL close (Build 417 method)
#define TGM_FULL_CLOSE_TRIGGER_PIPS 30.0   // same gate - no runner float
#define TGM_SHARED_SL_BEYOND_LAST_PIPS 50.0 // all 3 levels share SL = last +/-50pip
#define TGM_RISK_DIST_PIPS           50.0
#define TGM_BUILD_SERIAL            448
#define TGM_PARTIAL_CLOSE_AT_30_PCT  100.0  // unused while FULL book ON
#define TGM_R380_FORCE_NO_H4_RANGE_FILTER 1
#define TGM_FORCE_DISABLE_DAILY_PROFIT_LOCK 1
#define TGM_PENDING_CLAIM_STALE_SEC  3      // clear ghost PENDING(ticket=0) after this

#include <AI/RiskGovernor/Phase17/CPhase17RiskGovernor.mqh>
#include <AI/Research/CUnifiedMethodRouter.mqh>
#define TGM_RETCODE_FROZEN          10029
#define TGM_RISK_PER_TRADE_FRACTION 0.02   // R448: 2% EQUITY per trade (was 3%)
#define TGM_AUTO_MAX_LOT_CAP        0.00   // Auto path uncapped; broker/manual max only
#define TGM_HEDGE_TRIGGER_STRATEGY_PTS 500.0
#define TGM_HEDGE_CLOSE_STRATEGY_PTS   100.0
#define TGM_HEDGE_COMMENT              "GM_HEDGE"
#define TGM_MAX_GRID_POSITIONS_TOTAL    6
// Max activations/level/H4: PHASE18_MAX_LEVEL_ACTIVATIONS_H4 (default 2) ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â 1st SL re-arm; 2nd SL locks
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
   RISK_AUTO_3_PERCENT_EQUITY = 0, // Auto: each trade risks TGM_RISK_PER_TRADE_FRACTION of EQUITY (R448=2%)
   RISK_MANUAL_LOT            = 1  // Manual Lot Size
  };

//--- Mode A (hedge + loss-cap) permanently removed in v2.067 ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â Mode B only.

//--- Inputs
input group "--- Risk & Lot Sizing ---"
input ENUM_RISK_MODE RiskMode           = RISK_AUTO_3_PERCENT_EQUITY; // Risk Mode: Auto EQUITY % (R448=2%) OR Manual
input double         Manual_Lot_Size      = 0.50; // Manual lot size (used when RiskMode = Manual)
input double         Max_Lot_Size         = 5.00; // Hard cap: never open above this lot (0 = broker max only)

input group "--- ATR Fallback ---"
input double         InpFixedStopLossUSD  = 3.00; // Fallback only if ATR unavailable

input group "--- Live ATR Indicator Settings ---"
input int            ATR_Period           = 12; // Live ATR-12 H4 for TP only

input group "--- SL & TP Settings ---"
const bool           Enable_ATR_StopLoss       = false; // OFF: shared SL last+/-50pip
input double         SL_ATR_Multiplier       = 1.0; // unused while ATR SL OFF
input double         TP_ATR_Multiplier       = 1.0; // TP = Live ATR x multiplier

//--- RESEARCH 428 ------------------------------------------------------------
// Three departures from the Professional 422 core, each behind its own switch
// so the defaults leave this file behaving exactly like Professional.
//  1. Shared SL AND shared TP, both sized off the live ATR-12 rather than the
//     fixed 50pip. Today the SL is already one price for the whole side while
//     the TP differs per level; this makes the TP one price as well.
//  2. The +30pip full book-out is replaced by a move to break-even at +50pip,
//     letting the shared TP do the exiting.
//  3. A level mask and an H4 cycle whitelist, so a subset of levels can be run
//     in a subset of cycles on both sides.
input group "=== RESEARCH 428 ==="
input bool   RESEARCH_ATR_SHARED_SLTP = false; // Shared SL = last -/+ ATR*SL_mult, shared TP = first +/- ATR*TP_mult
input bool   RESEARCH_BE_MODE         = false; // Drop the +30pip full close; move to break-even instead
input double RESEARCH_BE_PIPS         = 30.0;  // Profit at which the stop moves to entry
input double RESEARCH_PARTIAL_AT_PIPS = 100.0; // Profit at which part of the lot is booked (0 = never)
input double RESEARCH_PARTIAL_PERCENT = 50.0;  // How much of the lot to book at that point
input double RESEARCH_LOCK_SL_PIPS    = 80.0;  // Stop is moved this far into profit at the same time
input int    RESEARCH_LEVEL_MASK      = 0;     // 0 = all levels; else bit0=L1, bit1=L2, bit2=L3 (5 = L1+L3)
input string RESEARCH_CYCLES          = "";    // Allowed H4 open hours, e.g. "0,12"; empty = every cycle
input bool   RESEARCH_ENABLE_BUY      = true;  // Arm the BUY  side
input bool   RESEARCH_ENABLE_SELL     = true;  // Arm the SELL side
input bool   RESEARCH_INDIV_SL_TP     = false; // Each position gets its OWN SL = entry -/+ ATR*SL_mult (no shared stop)
input double RESEARCH_TP_PIPS         = 50.0;  // Fixed target from entry, in pips, used with the above
input double RESEARCH_MAX_H4_RANGE_PIPS = 0.0; // Skip the cycle when the H4 high-low exceeds this (0 = no filter)
// The mirror of the above, for the breakout method: a narrow previous bar has
// no momentum to break out of, so only wide bars are worth arming.
input double RESEARCH_MIN_H4_RANGE_PIPS = 0.0; // Skip the cycle when the H4 high-low is below this (0 = no filter)

//--- The inverted method. The grid's buy levels sit below price and its sell
//--- levels above, so trading them the other way round means selling into a
//--- fall and buying into a rise: stop orders, not limits. That turns the
//--- method from mean-reversion into breakout, which is the real point of the
//--- experiment rather than a simple sign flip.
input bool   RESEARCH_INVERT_SIDES    = true;  // Sell at the buy levels, buy at the sell levels (stop orders)
input double RESEARCH_FIX_SL_PIPS     = 100.0; // Legacy/fallback stop
input double RESEARCH_FIX_TP_PIPS     = 150.0; // Legacy fallback TP (R447 uses SL×1.5)
input bool   RESEARCH_INVERT_ATR_SL   = false; // If true, ATR overrides fixed SL ladder
input double RESEARCH_RR_TP_MULT      = 1.5;   // TP = SL × this (1:1.5)
// Per-level SL in pips; TP = SL × RESEARCH_RR_TP_MULT (R447).
input double RESEARCH_INV_TP_L1_PIPS  = 100.0; // L1 SL pips (TP = SL×RR)
input double RESEARCH_INV_TP_L2_PIPS  = 60.0;  // L2 SL pips (TP = SL×RR)
input double RESEARCH_INV_TP_L3_PIPS  = 40.0;  // L3 SL pips (TP = SL×RR)

input bool   RESEARCH_DIRECTIONAL_AUTO   = false; // Legacy SMA router ONLY if Unified OFF (keep false for live)
input int    RESEARCH_DIR_MA_PERIOD      = 50;    // SMA period on H4 and Daily for legacy trend agreement
input double RESEARCH_DIR_NARROW_MAX_PIPS= 250.0; // Narrow method when range <= this (inclusive)
input double RESEARCH_DIR_WIDE_MIN_PIPS  = 300.0; // Wide method when range >= this (inclusive)

input group "=== UNIFIED METHOD ROUTER (R445 RANGE BOTH) ==="
input bool   EnableUnifiedMethodRouter = true;  // H4 range only -> 2 methods (BOTH buy+sell)
input bool   UseD1Direction            = false; // D1 bias log only (never gates)
input bool   UseH4Direction            = true;  // H4 bias log only (never gates)
input int    ROUTER_EMA_Fast_Period    = 50;
input int    ROUTER_EMA_Slow_Period    = 200;
input int    ROUTER_ADX_Period         = 14;
input double ROUTER_ADX_Min            = 20.0;
input double ROUTER_ADX_Strong         = 25.0;
input int    ROUTER_ATR_Period         = 14;
input int    AlignedMinScore           = 70;    // Legacy label (R437+ does not hard-block on score)
input int    PullbackMinScore          = 80;    // Legacy label (R437+ does not hard-block on score)
input int    TrendScoreStrong          = 80;    // Label only
input int    TrendScoreValid           = 70;    // Label only
input int    TrendScoreWeak            = 60;    // Label only (kept for set compatibility)
input double LargeRangePips            = 300.0;
input double SmallRangePips            = 250.0;
input bool   GapTradingEnabled         = false;
input bool   UseSMCConfirmation        = true;
input bool   UseBOSCHoCH               = true;
input bool   UseVWAPConfirmation       = false; // reserved (no VWAP module)

input group "--- Price-Based ($) Profit Engine [XAUUSD: 1.00 price move = $1.00] ---"
input double         InpProfitBE          = 5.00;  // Parent: $ profit -> Break-Even + 80% book + trailing
input double         InpTrailingStopUSD   = 3.00;  // PROFIT: trailing gap $ behind price (3.00 = 30pip)

//--- Legacy Mode A constants (not inputs ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â kept so dead hedge helpers still compile; engine never runs)
const double         InpHedgeTriggerUSD   = 5.00;
const double         InpHedgeStopLossUSD  = 0.00;
const double         InpHedgeBreakEvenUSD = 1.00;
const double         InpHedgeRearmClearUSD = 5.00;
const int            InpHedgeRearmMinSec  = 0;
const double         InpHedgeReturnArmUSD = 0.00;
const bool           Enable_LossCapEngine     = false;
const double         InpLossCapUSD            = 6.00;
const double         InpHedgeReleaseUSD       = 1.00;
const bool           Enable_ParentHardCapSL   = false;
const bool           Enable_Hedge_Protection   = false;
const bool           InpHedgeChopFreezeEnable  = false;
const double         InpHedgeChopRangeUSD    = 2.00;
const int            InpHedgeChopMinDeaths   = 2;
const int            InpHedgeChopWindowSec = 900;
const double         InpHedgeChopBreakoutUSD = 3.00;
const int            InpHedgeChopFreezeMinSec= 180;

input group "--- Account Protection (mandatory safety) ---"
input bool           Enable_Account_Protection = true;  // Master safety switch - limits exposure
input double         Max_Floating_DD_Percent   = 8.0;  // Layer 1: block NEW grid + cancel pendings
const int            Max_Hedge_Cycles_Per_H4   = 0;    // legacy unused (Mode A removed)
const int            Hedge_Retry_Seconds       = 30;   // legacy unused (Mode A removed)
const bool           Enable_Basket_TP          = false; // permanently OFF (Mode A removed)
const double         Basket_TP_Amount          = 500.0;
const bool           Enable_TrendBleedProtect  = false; // OFF — full 3BUY+3SELL (Phase17C E2 rejected)

input group "--- Kill Switch (last resort) ---"
input bool           Enable_Triple_Protection       = true;  // Layer 3 kill switch
const double         Emergency_Parent_SL_Points     = 750.0; // legacy Layer 2 (unused in Mode B)
const int            Unprotected_Hang_Seconds       = 90;    // legacy Layer 2 (unused in Mode B)
input double         Emergency_Close_DD_Percent     = 10.0;  // close ALL bot trades + pendings (was 18 — too late)
input double         Max_Daily_Loss_Percent         = 12.0;  // daily loss cap -> close ALL + pause day

input group "--- Gap / Freeze LIVE SAFE (R440) ---"
input bool           Enable_GapFreeze_Hardening     = true;  // Harden freeze retry + cascade guards
input int            Live_MaxOpenBotPositions       = 6;     // Max filled (both sides up to 3+3)
input int            Live_MaxPendingLevels          = 3;     // 3 levels per side (BUY+SELL = up to 6 pendings)
input double         PendingCancel_DD_Percent       = 0.0;   // 0=OFF (R444 keep levels). >0 cancels pendings at DD%
input double         MaxLossMultipleOfPlannedSL     = 1.25;  // Force-close if loss > planned SL$ * this
input double         Live_MaxSpreadPips             = 80.0;  // Cancel pendings if spread > this (pips)

input group "--- Advanced Trade Management ($ Based) ---"
input bool           Enable_BreakEven        = false; // OFF: +30pip FULL book (no BE runner)
input bool           Enable_PartialClose     = false; // OFF: no partial - full close at +30pip
input double         PartialClose_Percent    = 100.0; // unused while partial OFF

//--- Globals
CTrade              g_trade;
int                 g_atrHandle              = INVALID_HANDLE;
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
bool                g_forceFlattenActive          = false; // retry close until bot flat after freeze/kill
datetime            g_lastFlattenRetryTime        = 0;
datetime            g_emergencyLockH4Open         = 0;     // R441: emergency locks THIS H4 only (not all day)
string              g_emergencyLockReason         = "";
bool                g_h4PlacementDone             = false; // true after initial arm attempt this H4
datetime            g_pendingClaimTime[6];                 // in-flight PENDING(ticket=0) claim stamps
datetime            g_lastPendingMaintainTime     = 0;     // throttle maintain calls
bool                g_marketValidationCompleted = false; // tester: true after Market validation trades done
ENUM_RISK_MODE      g_effectiveRiskMode         = RISK_AUTO_3_PERCENT_EQUITY;
double              g_effectiveManualLotSize    = 0.50;
double              g_effectiveMaxLotSize         = 5.00;

//--- R432 directional auto: per-cycle arm flags (set in ExecuteH4GridStrategy).
bool                g_dirEnableBuyArm             = false;
bool                g_dirEnableSellArm            = false;
bool                g_dirBreakoutPlacement        = false;
int                 g_dirMaH4Handle               = INVALID_HANDLE;
int                 g_dirMaD1Handle               = INVALID_HANDLE;
CUnifiedMethodRouter g_unifiedRouter;
STgmRouterDecision   g_lastRouterDecision;

//--- Forward declarations
bool   ShouldRenderUI();
void   InitBrokerPointModifier();
bool   GetLiveATR(double &atrOut);
double GetLiveAtrStopDistance();
double GetConfiguredStopDistance();
bool   GetSharedGridSideStopLoss(const ENUM_POSITION_TYPE side, double &slOut);
double GetLotSizingCapital();
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
int    MaintainArmedPendings(const string trigger);
int    GridLevelCommentIndex(const string comment);
void   MarkPendingClaim(const string comment);
void   ClearPendingClaim(const string comment);
bool   IsStalePendingClaim(const string comment);
bool   LevelNeedsPendingRestore(const string comment);
bool   AnyLevelNeedsPendingRestore();
void   HealGhostPendingStates(const string reason);
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
void   ProcessBreakEvenPriorityQueue();
void   RunAccountProtectionEngine();
void   EnforceHedgeCoverageScan();
void   MonitorAccountDrawdownProtection();
void   MonitorLiveGapFreezeGuards();
void   RetryForceFlattenUntilFlat();
int    CountBotPendings();
int    CountOpenBotPositions();
bool   LiveSafeAllowsNewPending(const int levelIndex);
int    CountGridPositions();
int    CountHedgePositions();
bool   IsGridPlacementAllowed(const bool freshH4Cycle = false);
bool   IsHedgeOpenAllowedForParent(const ulong parentTicket, const double parentLossPts);
void   ClearHedgeProtectionState(const ulong parentTicket);
void   LogProtectionAlert(const string message);
void   MonitorLayer3HardKillSwitch();
void   EnforceLayer2EmergencyParentProtection();
bool   IsKillSwitchActiveToday();
string KillSwitchDayKey();
bool   StrictH4CycleOnly();
bool   IsEmergencyLockThisH4();
void   SetEmergencyLockThisH4(const string reason);
void   ClearEmergencyLockIfNewH4();
void   MarkH4PlacementDone();
bool   CanPlaceGridThisH4();
bool   ApplyEmergencyParentSL(const ulong ticket);
bool   CloseGridPositionEmergency(const ulong ticket, const string reason);
bool   SafePositionModify(const ulong ticket, const double sl, const double tp, const string operation);
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
void   ApplyEffectiveRiskSettingsFromInputs();
bool   ConfirmManualRiskOverride();
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
bool   HasBotPendingByComment(const string comment);
bool   IsCommentActiveInPositions(const string comment);
bool   IsLevelAlreadySpentInCurrentH4Bar(const string comment);
bool   IsLevelBELockedThisH4(const string comment);
bool   IsLevelActivationExhaustedThisH4(const string comment);
int    GetLevelActivationCountThisH4(const string comment);
int    CountBotPendings();
void   SetGridLevelState(const string comment, const double state, const ulong ticket = 0);
void   ClearGridLevelState(const string comment);
bool   PendingCommentMatchesLevel(const string orderComment, const string levelComment);
int    CancelDuplicatePendingsAtSamePrice();
bool   GetPositionOpeningComments(const ulong positionTicket, string &dealCommentOut, string &orderCommentOut);
bool   WasOpenedAsGridLimit(const ulong positionTicket);
bool   IsOurBotMagicPosition(const ulong ticket);
bool   IsOurBotGridParent(const ulong ticket);
bool   IsForeignOrManualPosition(const ulong ticket);
bool   IsBotHedgePosition(const ulong ticket, const string comment);
bool   IsProfitEngineArmed(const ulong ticket);
bool   IsPartialClosedBeRunner(const ulong ticket);
void   MarkPartialClosedBeRunner(const ulong ticket);
void   LogPhase28A(const string eventName, const ulong ticket, const string detail);
double GetPositionProfitPips(const ulong ticket);
bool   StripPositionTakeProfit(const ulong ticket, const string reason);
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
   if(Emergency_Close_DD_Percent <= Max_Floating_DD_Percent || Emergency_Close_DD_Percent > 40.0)
     {
      Print("The Gold Mind: Emergency_Close_DD_Percent must be > Max_Floating_DD_Percent and <= 40.");
      return INIT_PARAMETERS_INCORRECT;
     }
   if(Enable_GapFreeze_Hardening)
     {
      // 0 = OFF (R444 keep pendings armed). If >0 must be below emergency DD.
      if(PendingCancel_DD_Percent < 0.0 ||
         (PendingCancel_DD_Percent > 0.0 && PendingCancel_DD_Percent >= Emergency_Close_DD_Percent))
        {
         Print("The Gold Mind: PendingCancel_DD_Percent must be 0 (OFF) or >0 and < Emergency_Close_DD_Percent.");
         return INIT_PARAMETERS_INCORRECT;
        }
      if(Live_MaxOpenBotPositions < 1 || Live_MaxOpenBotPositions > 6)
        {
         Print("The Gold Mind: Live_MaxOpenBotPositions must be 1..6.");
         return INIT_PARAMETERS_INCORRECT;
        }
      if(Live_MaxPendingLevels < 1 || Live_MaxPendingLevels > 3)
        {
         Print("The Gold Mind: Live_MaxPendingLevels must be 1..3.");
         return INIT_PARAMETERS_INCORRECT;
        }
      if(MaxLossMultipleOfPlannedSL < 1.0 || MaxLossMultipleOfPlannedSL > 5.0)
        {
         Print("The Gold Mind: MaxLossMultipleOfPlannedSL must be 1.0..5.0.");
         return INIT_PARAMETERS_INCORRECT;
        }
     }
   if(Max_Daily_Loss_Percent <= 0.0 || Max_Daily_Loss_Percent > 40.0)
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
   if(RESEARCH_DIRECTIONAL_AUTO || EnableUnifiedMethodRouter)
     {
      if(!RESEARCH_INVERT_SIDES)
        {
         Print("The Gold Mind: Directional/Unified router requires RESEARCH_INVERT_SIDES=true.");
         return INIT_PARAMETERS_INCORRECT;
        }
      if(RESEARCH_DIRECTIONAL_AUTO)
        {
         if(RESEARCH_DIR_MA_PERIOD < 2)
           {
            Print("The Gold Mind: RESEARCH_DIR_MA_PERIOD must be >= 2.");
            return INIT_PARAMETERS_INCORRECT;
           }
         if(RESEARCH_DIR_NARROW_MAX_PIPS <= 0.0 || RESEARCH_DIR_WIDE_MIN_PIPS <= RESEARCH_DIR_NARROW_MAX_PIPS)
           {
            Print("The Gold Mind: directional range gates must satisfy 0 < narrowMax < wideMin.");
            return INIT_PARAMETERS_INCORRECT;
           }
        }
      if(EnableUnifiedMethodRouter)
        {
         if(SmallRangePips <= 0.0 || LargeRangePips <= SmallRangePips)
           {
            Print("The Gold Mind: Unified router requires 0 < SmallRangePips < LargeRangePips.");
            return INIT_PARAMETERS_INCORRECT;
           }
         if(AlignedMinScore < 1 || PullbackMinScore < AlignedMinScore)
           {
            Print("The Gold Mind: 0 < AlignedMinScore <= PullbackMinScore required.");
            return INIT_PARAMETERS_INCORRECT;
           }
        }
     }

   ApplyEffectiveRiskSettingsFromInputs();

   InitBrokerPointModifier();

   g_trade.SetExpertMagicNumber(EXPERT_MAGIC);
   g_trade.SetDeviationInPoints((ulong)MathRound(TGM_BASE_DEVIATION_PTS * point_modifier));
   SetFillingMode();

   g_atrHandle = iATR(_Symbol, PERIOD_H4, ATR_Period);
   if(g_atrHandle == INVALID_HANDLE)
     {
      Print("The Gold Mind: Failed to create iATR handle. GetLastError=", GetLastError());
      return INIT_FAILED;
     }

   if(EnableUnifiedMethodRouter)
     {
      if(!g_unifiedRouter.Init(_Symbol, ROUTER_EMA_Fast_Period, ROUTER_EMA_Slow_Period,
                               ROUTER_ADX_Period, ROUTER_ATR_Period))
         return INIT_FAILED;
      g_unifiedRouter.Configure(UseD1Direction, UseH4Direction,
                                ROUTER_ADX_Min, ROUTER_ADX_Strong,
                                AlignedMinScore, PullbackMinScore,
                                LargeRangePips, SmallRangePips,
                                GapTradingEnabled, UseSMCConfirmation, UseBOSCHoCH,
                                UseVWAPConfirmation);
      Print("TGM [R445]: Range router ON | <=Small BOTH limits | >=Large BOTH stops | gap skip | direction never blocks.");
     }
   else if(RESEARCH_DIRECTIONAL_AUTO)
     {
      g_dirMaH4Handle = iMA(_Symbol, PERIOD_H4, RESEARCH_DIR_MA_PERIOD, 0, MODE_SMA, PRICE_CLOSE);
      g_dirMaD1Handle = iMA(_Symbol, PERIOD_D1, RESEARCH_DIR_MA_PERIOD, 0, MODE_SMA, PRICE_CLOSE);
      if(g_dirMaH4Handle == INVALID_HANDLE || g_dirMaD1Handle == INVALID_HANDLE)
        {
         Print("The Gold Mind: Failed to create directional MA handles. GetLastError=", GetLastError());
         return INIT_FAILED;
        }
     }

   double initAtr = 0.0;
   if(GetLiveATR(initAtr))
     {
      const int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
      PrintFormat("The Gold Mind: Live H4 ATR(%d)=%.*f | sharedSL last+/-%.0fpip | TP=%.*f (%.1fx ATR) | hedge=OFF",
                  ATR_Period, digits, initAtr,
                  TGM_SHARED_SL_BEYOND_LAST_PIPS,
                  digits, initAtr * TP_ATR_Multiplier, TP_ATR_Multiplier);
     }

   if(ShouldRenderUI())
     {
      DestroyAllChartDashboardUI();
      InitDashboard();
      EnableDashboardChartEvents();
      RefreshGridChartLinesFromH4();
      EventSetTimer(TGM_DASHBOARD_TIMER_SEC);
     }

   GmP11B_OnInit(EXPERT_MAGIC, g_effectiveMaxLotSize, g_atrHandle, g_uiX, g_uiY);
   GmP14_OnInit(g_atrHandle);
   Phase17_OnInit();

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
      ClearEmergencyLockIfNewH4();
      if(IsNewH4GridPeriod())
         RefreshGridOnNewH4Bar("OnInit-Fresh");
      else if(IsGridPlacementAllowed() && !StrictH4CycleOnly())
        {
         if(!MaybeForceRebuildCurrentH4IfEmpty("OnInit-EmptySameH4"))
            ExecuteH4GridStrategy();
        }
      else if(StrictH4CycleOnly() && !IsEmergencyLockThisH4())
        {
         // R444: Mid-H4 attach — arm all enabled levels now; missing ones restore on tick.
         if(IsGridPlacementAllowed(true))
           {
            HealGhostPendingStates("OnInit");
            Print("TGM [R444]: Mid-H4 attach — arm up to 3 pending levels now (manual delete restores while EA active).");
            const int n = ExecuteH4GridStrategy(true);
            MarkH4PlacementDone();
            SaveGridH4BarTime(GetCurrentH4BarOpenTime());
            PrintFormat("TGM [R444]: Initial arm placed=%d pendingNow=%d", n, CountBotPendings());
           }
         else
            Print("TGM [R444]: Mid-H4 attach deferred — waiting for Algo Trading ON (OnTick will arm + keep restoring).");
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

   Print("The Gold Mind v2.155 RESEARCH (build ", TGM_BUILD_SERIAL, "): Initialized on ", _Symbol, " (", _Digits, " digits).");
   PrintFormat("TGM: Max activations/level/H4=%d (ONE shot - no re-arm after SL/TP).",
               MaxLevelActivationsThisH4());
   if(EnableUnifiedMethodRouter && RESEARCH_INVERT_SIDES)
     {
      const double rr = (RESEARCH_RR_TP_MULT > 0.0) ? RESEARCH_RR_TP_MULT : 1.5;
      PrintFormat("TGM [R448]: RANGE BOTH | small<=%.0f | large>=%.0f | risk=%.0f%% EQUITY | SL:TP=1:%.2f | L1 %.0f/%.0f L2 %.0f/%.0f L3 %.0f/%.0f",
                  SmallRangePips, LargeRangePips, TGM_RISK_PER_TRADE_FRACTION * 100.0, rr,
                  RESEARCH_INV_TP_L1_PIPS, RESEARCH_INV_TP_L1_PIPS * rr,
                  RESEARCH_INV_TP_L2_PIPS, RESEARCH_INV_TP_L2_PIPS * rr,
                  RESEARCH_INV_TP_L3_PIPS, RESEARCH_INV_TP_L3_PIPS * rr);
      Print("TGM [H4-POLICY]: last closed H4 high-low ONLY -> method | BUY+SELL together | no direction gate | broker TP.");
      if(RESEARCH_DIRECTIONAL_AUTO)
         Print("TGM [WARN]: RESEARCH_DIRECTIONAL_AUTO=true ignored while Unified router ON — set false in Inputs/.set.");
      if(MathAbs(SmallRangePips - 250.0) > 0.01 || MathAbs(LargeRangePips - 300.0) > 0.01)
         PrintFormat("TGM [WARN]: Range gates Small=%.0f Large=%.0f (intended live lock 250/300).",
                     SmallRangePips, LargeRangePips);
     }
   else if(RESEARCH_DIRECTIONAL_AUTO && RESEARCH_INVERT_SIDES)
     {
      PrintFormat("TGM [R432]: DIRECTIONAL LIVE ON | H4+D1 SMA(%d) | narrow<=%.0f wide>=%.0f | gap SKIP | SL=%.0fpip TP=%0.f/%0.f/%0.f",
                  RESEARCH_DIR_MA_PERIOD, RESEARCH_DIR_NARROW_MAX_PIPS, RESEARCH_DIR_WIDE_MIN_PIPS,
                  RESEARCH_FIX_SL_PIPS, RESEARCH_INV_TP_L1_PIPS, RESEARCH_INV_TP_L2_PIPS, RESEARCH_INV_TP_L3_PIPS);
      Print("TGM [H4-POLICY]: ONE side only per cycle (trend) | wide=breakout stops | narrow=limits | never both buy+sell.");
     }
   else
     {
      PrintFormat("TGM [R422]: Build417 method | sharedSL last+/-%.0fpip | +%.0fpip FULL book | lots=EQUITY %.0f%% | H4 range OFF | hedge OFF.",
                  TGM_SHARED_SL_BEYOND_LAST_PIPS, TGM_FULL_CLOSE_TRIGGER_PIPS,
                  TGM_RISK_PER_TRADE_FRACTION * 100.0);
      Print("TGM [WARN]: DIRECTIONAL_AUTO/INVERT OFF - classic 3BUY+3SELL. Load LIVE_Directional.set for trend method.");
      Print("TGM [H4-POLICY]: Each H4 -> 3 BUY + 3 SELL (any range) | shared SL on all 3 | lot dist = |L1-sharedSL|.");
     }
   PrintFormat("TGM [OWNERSHIP]: Magic=%d ONLY - manual/foreign trades are invisible (no manage, no DD, no block).", EXPERT_MAGIC);
   PrintFormat("TGM [LOT]: Auto uncapped | Manual max=%.2f | AutoRisk=%.0f%% of EQUITY | DD lot scale 70/50/35%%.",
               TGM_AUTO_MAX_LOT_CAP, g_effectiveMaxLotSize, TGM_RISK_PER_TRADE_FRACTION * 100.0);
   if((EnableUnifiedMethodRouter || RESEARCH_DIRECTIONAL_AUTO) && RESEARCH_INVERT_SIDES)
      Print("TGM [METHOD]: Inverted directional | fixed SL/TP ladder | no +30 FULL book | no hedge.");
   else
      Print("TGM [METHOD]: Profit +30pip FULL book | Loss: broker shared SL last+/-50pip | no hedge.");
   if(Enable_GapFreeze_Hardening)
      PrintFormat("TGM [R440 LIVE-SAFE]: flatten-retry ON | maxOpen=%d maxLevels=%d | pendingCancelDD=%.1f%% | killDD=%.1f%% | SL*x=%.2f | maxSpread=%.0fpip",
                  Live_MaxOpenBotPositions, Live_MaxPendingLevels,
                  PendingCancel_DD_Percent, Emergency_Close_DD_Percent,
                  MaxLossMultipleOfPlannedSL, Live_MaxSpreadPips);
   if(StrictH4CycleOnly())
      Print("TGM [R444 PENDING]: Attach => arm 3 levels | manual delete => restore while EA on chart | SPENT only after SL/TP exit | remove EA to stop restore.");
   Print("TGM [P11E]: AI Dynamic Exec Engine DISABLED (removed from strategy).");
   PrintFormat("TGM [P14]: AI_VALIDATION_ENABLED=%s (OFF = unchanged H4 OrderSend path).",
               (AI_VALIDATION_ENABLED ? "true" : "false"));
   Print("TGM [PLACE]: Pendings only when Ask>BuyLevel (BuyLimit) / Bid<SellLevel (SellLimit). Price-through = wait.");
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
   if(g_dirMaH4Handle != INVALID_HANDLE)
     {
      IndicatorRelease(g_dirMaH4Handle);
      g_dirMaH4Handle = INVALID_HANDLE;
     }
   if(g_dirMaD1Handle != INVALID_HANDLE)
     {
      IndicatorRelease(g_dirMaD1Handle);
      g_dirMaD1Handle = INVALID_HANDLE;
     }
   if(EnableUnifiedMethodRouter || g_unifiedRouter.IsReady())
     {
      g_unifiedRouter.LogSummary();
      g_unifiedRouter.Shutdown();
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
      Phase17_LogSummary();
      GmP11B_OnDeinit();
      GmP14_OnDeinit();
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
   GmP11B_OnTick();
   Phase17_OnTickUpdate(); // DD / daily lock / H4 range diagnostics (gates placement separately)
   if(Phase17_ConsumePendingCancelRequest())
     {
      // R444: do NOT wipe method pendings on DD freeze — levels stay while EA is active.
      // Emergency/kill flatten still cancels via dedicated paths.
      if(!StrictH4CycleOnly())
        {
         EnsureAllBotPendingDeletedForced();
         Print("TGM [P17B]: Bot pendings cancelled after DD freeze (open positions untouched).");
        }
      else
         Print("TGM [R444]: DD freeze noted — method pendings kept armed (manual delete restores).");
     }

   if(IsGridOpsAllowed())
     {
      if(IsNewH4GridPeriod())
         RefreshGridOnNewH4Bar("OnTick");
      else if(StrictH4CycleOnly())
        {
         // R444: keep method levels armed while EA is on the chart.
         if(!IsEmergencyLockThisH4())
           {
            if(!g_h4PlacementDone && IsGridPlacementAllowed(true))
              {
               HealGhostPendingStates("OnTick-InitArm");
               Print("TGM [R444]: Same-H4 initial arm (Algo ready).");
               ExecuteH4GridStrategy(true);
               MarkH4PlacementDone();
               SaveGridH4BarTime(GetCurrentH4BarOpenTime());
              }
            MaintainArmedPendings("OnTick");
           }
        }
      else
        {
         // Legacy classic grid only: same-H4 refill allowed
         if(!MaybeForceRebuildCurrentH4IfEmpty("OnTick-EmptySameH4"))
            ExecuteH4GridStrategy();
        }
     }

   if(IsPositionMgmtAllowed() || HasOpenBotPositions())
      RunAccountProtectionEngine();

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

   GmP11B_OnTradeTransaction(trans);

   if((trans.type == TRADE_TRANSACTION_DEAL_ADD || trans.type == TRADE_TRANSACTION_HISTORY_ADD) && trans.deal > 0)
      ProcessModeBLevelExitFromDeal(trans.deal);

   if(trans.type == TRADE_TRANSACTION_ORDER_ADD ||
      trans.type == TRADE_TRANSACTION_ORDER_UPDATE ||
      trans.type == TRADE_TRANSACTION_ORDER_DELETE ||
      trans.type == TRADE_TRANSACTION_DEAL_ADD ||
      trans.type == TRADE_TRANSACTION_HISTORY_ADD ||
      trans.type == TRADE_TRANSACTION_POSITION)
     {
      SynchronizePersistentState("OnTradeTransaction");
      // R444: manual pending delete while EA active → re-arm that level immediately
      if(trans.type == TRADE_TRANSACTION_ORDER_DELETE &&
         StrictH4CycleOnly() &&
         !IsEmergencyLockThisH4() &&
         IsGridOpsAllowed())
         MaintainArmedPendings("OrderDelete");
     }
  }

//+------------------------------------------------------------------+
//| Interactive Chart Events (Drag / Drop & Buttons Engine)          |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
  {
   if(!ShouldRenderUI())
      return;

   // AI DYNAMIC panel (independent drag / minimize) ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â handle first so it doesn't fight main UI.
   if(GmP11B_OnChartEvent(id, lparam, dparam, sparam))
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
         return true; // BUY + SELL done ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â unlock main strategy.
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

   // Broker session can still read "open" during daily breaks ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â confirm with live quotes.
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
   // R440: flatten/close/delete must NEVER trigger 15-min trade pause on freeze
   if(StringFind(operation, "PositionClose") >= 0)
      return true;
   if(StringFind(operation, "OrderDelete") >= 0)
      return true;
   if(StringFind(operation, "KillSwitch") >= 0)
      return true;
   if(StringFind(operation, "ForceFlatten") >= 0)
      return true;
   if(StringFind(operation, "GapGuard") >= 0)
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
      PrintFormat("TGM [SAFE]: %s blocked ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ticket #0 (invalid).", operation);
      return false;
     }

   CPositionInfo pos;
   if(!pos.SelectByTicket(ticket))
      return false;
   if(pos.Symbol() != _Symbol || pos.Magic() != (ulong)EXPERT_MAGIC)
      return false;

   const int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   const double nSL = (sl > 0.0) ? NormalizeDouble(sl, digits) : 0.0;
   const double nTP = (tp > 0.0) ? NormalizeDouble(tp, digits) : 0.0;

   // Reject inverted SL/TP which brokers refuse (seen as Invalid parameters).
   if(nSL > 0.0 && nTP > 0.0)
     {
      if(pos.PositionType() == POSITION_TYPE_BUY && nSL >= nTP)
        {
         PrintFormat("TGM [SAFE]: %s blocked #%I64u ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â BUY SL>=TP (sl=%.*f tp=%.*f).",
                     operation, ticket, digits, nSL, digits, nTP);
         return false;
        }
      if(pos.PositionType() == POSITION_TYPE_SELL && nSL <= nTP)
        {
         PrintFormat("TGM [SAFE]: %s blocked #%I64u ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â SELL SL<=TP (sl=%.*f tp=%.*f).",
                     operation, ticket, digits, nSL, digits, nTP);
         return false;
        }
     }

   return ExecuteTradeOp(operation, g_trade.PositionModify(ticket, nSL, nTP),
                         StringFormat("ticket=%I64u sl=%.*f tp=%.*f", ticket, digits, nSL, digits, nTP));
  }

//--- Parent must never sit naked (blank SL). Restore fixed $3 or ATR SL.
bool EnsureParentHasBrokerSL(const ulong ticket)
  {
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

   PrintFormat("TGM [SL-RESTORE]: Parent #%I64u had NO SL ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â restored %.*f (distÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â°Ãƒâ€¹Ã¢â‚¬Â $%.2f).",
               ticket, digits, targetSL, slDist);
   return true;
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
      // Already tighter or equal ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ done
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

   PrintFormat("TGM [LOSS-CAP]: Parent #%I64u SL capped at %.*f (max adverse ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â°Ãƒâ€¹Ã¢â‚¬Â  $%.2f) | 1:1 hedge locked.",
               parentTicket, digits, targetSL, InpLossCapUSD);
   return true;
  }

//--- Close sticky hedge when parent has recovered so profit path can run (Mode A only).
bool TryReleaseStickyHedge(const ulong parentTicket)
  {
   if(!IsHedgeEngineActive())
      return false;
   if(!HasHedge(parentTicket))
      return false;

   const double loss = GetPositionLossUSD(parentTicket);
   const double release = (InpHedgeReleaseUSD > 0.0) ? InpHedgeReleaseUSD : 1.0;
   if(loss >= release)
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
      PrintFormat("TGM [HEDGE]: Parent #%I64u recovered ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â hedge released.", parentTicket);
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
   MessageBox(
      "WARNING Ã¢â‚¬â€ Manual lot sizing is active.\n\n"
      "Larger lots amplify losses. In adverse moves your account can be wiped out.\n\n"
      "Click OK only if you fully accept this risk.",
      "The Gold Mind Ã¢â‚¬â€ Risk Warning",
      (int)(MB_OK | MB_ICONWARNING));
  }

bool ConfirmManualRiskOverride()
  {
   const int res = (int)MessageBox(
      "WARNING Ã¢â‚¬â€ You are changing lot or risk settings.\n\n"
      "Higher lot sizes can seriously harm your account. "
      "In adverse market moves your balance can be wiped out.\n\n"
      "Click OK to apply your manual settings, or Cancel to keep safe defaults.",
      "The Gold Mind Ã¢â‚¬â€ Risk Warning",
      (int)(MB_OKCANCEL | MB_ICONWARNING));
   return (res == IDOK);
  }

string EffectiveRiskSettingsKey(const string suffix)
  {
   return StringFormat("TGM_Risk_%I64d_%u_%s_%s",
                       AccountInfoInteger(ACCOUNT_LOGIN),
                       EXPERT_MAGIC,
                       _Symbol,
                       suffix);
  }

bool LoadSavedRiskSettings(int &modeOut, double &manualOut, double &maxOut)
  {
   const string kMode   = EffectiveRiskSettingsKey("mode");
   const string kManual = EffectiveRiskSettingsKey("man");
   const string kMax    = EffectiveRiskSettingsKey("max");
   if(!GlobalVariableCheck(kMode))
      return false;
   modeOut   = (int)GlobalVariableGet(kMode);
   manualOut = GlobalVariableGet(kManual);
   maxOut    = GlobalVariableGet(kMax);
   return true;
  }

void SaveRiskSettings(const int mode, const double manual, const double max)
  {
   GlobalVariableSet(EffectiveRiskSettingsKey("mode"), (double)mode);
   GlobalVariableSet(EffectiveRiskSettingsKey("man"), manual);
   GlobalVariableSet(EffectiveRiskSettingsKey("max"), max);
  }

bool RiskInputsChangedFromSaved(const int savedMode, const double savedManual, const double savedMax)
  {
   if((int)RiskMode != savedMode)
      return true;
   if(MathAbs(Manual_Lot_Size - savedManual) > 0.001)
      return true;
   if(MathAbs(Max_Lot_Size - savedMax) > 0.001)
      return true;
   return false;
  }

bool RiskInputsAreRisky()
  {
   return (RiskMode == RISK_MANUAL_LOT);
  }

void ApplyEffectiveRiskSettingsFromInputs()
  {
   if(IsStrategyTester())
     {
      g_effectiveRiskMode      = RiskMode;
      g_effectiveManualLotSize = Manual_Lot_Size;
      g_effectiveMaxLotSize    = Max_Lot_Size;
      return;
     }

   int    savedMode   = RISK_AUTO_3_PERCENT_EQUITY;
   double savedManual = Manual_Lot_Size;
   double savedMax    = Max_Lot_Size;
   const bool hasSaved = LoadSavedRiskSettings(savedMode, savedManual, savedMax);

   const bool changed = hasSaved &&
                        RiskInputsChangedFromSaved(savedMode, savedManual, savedMax);
   const bool risky   = RiskInputsAreRisky();

   // Popup only when the user actually changed a risky setting Ã¢â‚¬â€ not on every attach.
   if(ShouldRenderUI() && changed && risky)
     {
      if(!ConfirmManualRiskOverride())
        {
         g_effectiveRiskMode      = (ENUM_RISK_MODE)savedMode;
         g_effectiveManualLotSize = savedManual;
         g_effectiveMaxLotSize    = savedMax;
         Print("TGM [RISK]: Manual change declined Ã¢â‚¬â€ keeping previously accepted settings.");
         return;
        }
      if(RiskMode == RISK_MANUAL_LOT)
         ShowManualLotWarning();
     }

   g_effectiveRiskMode      = RiskMode;
   g_effectiveManualLotSize = Manual_Lot_Size;
   g_effectiveMaxLotSize    = Max_Lot_Size;

   if(ShouldRenderUI())
      SaveRiskSettings((int)RiskMode, Manual_Lot_Size, Max_Lot_Size);
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
   return true; // Mode B only ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â Mode A removed in v2.067
  }

bool IsLossCapHedgeMode()
  {
   return false; // Mode A permanently disabled
  }

bool IsHedgeEngineActive()
  {
   return false; // Mode A hedge engine permanently disabled
  }

bool IsLossCapEngineActive()
  {
   return false; // Mode A loss-cap permanently disabled
  }

//--- Live ATR-14 H4 SL distance (price). Fallback: fixed InpFixedStopLossUSD.
double GetLiveAtrStopDistance()
  {
   double atr = 0.0;
   if(GetLiveATR(atr) && atr > 0.0 && SL_ATR_Multiplier > 0.0)
      return atr * SL_ATR_Multiplier;
   return (InpFixedStopLossUSD > 0.0) ? InpFixedStopLossUSD : 3.0;
  }

//--- Active SL distance: Excel method = Live ATR (per entry).
//--- Active SL distance: shared last+/-50pip. ATR SL stays OFF.
double GetConfiguredStopDistance()
  {
   const double pip = Phase17_GetPipSize();
   // R428: individual-stop mode owns the width, so healing and lot math must
   // use the same ATR distance the pending was placed with.
   if(RESEARCH_INDIV_SL_TP)
     {
      double atrValue = 0.0;
      if(GetLiveATR(atrValue) && atrValue > 0.0)
         return atrValue * SL_ATR_Multiplier;
     }
   // Inverted method: whichever width the placement helper used is the only
   // risk distance in play, so healing and lot math must reproduce it.
   if(RESEARCH_INVERT_SIDES && RESEARCH_INVERT_ATR_SL)
     {
      double atrValue = 0.0;
      if(GetLiveATR(atrValue) && atrValue > 0.0)
         return atrValue * SL_ATR_Multiplier;
     }
   if(RESEARCH_INVERT_SIDES && pip > 0.0 && RESEARCH_FIX_SL_PIPS > 0.0)
      return RESEARCH_FIX_SL_PIPS * pip;
   if(pip > 0.0)
      return TGM_RISK_DIST_PIPS * pip;
   if(Enable_ATR_StopLoss)
      return GetLiveAtrStopDistance();
   return (InpFixedStopLossUSD > 0.0) ? InpFixedStopLossUSD : 5.0;
  }

//--- Shared SL for side: last grid level +/-50pip (buy3 / sell3).
bool GetSharedGridSideStopLoss(const ENUM_POSITION_TYPE side, double &slOut)
  {
   slOut = 0.0;
   // R428: in individual-stop mode there is no shared side stop at all, so the
   // caller must fall back to sizing the stop off the position's own entry.
   if(RESEARCH_INDIV_SL_TP || RESEARCH_INVERT_SIDES)
      return false;
   double high1, low1, pivot, buy1, buy2, buy3, sell1, sell2, sell3;
   if(!CalculateH4GridLevels(high1, low1, pivot, buy1, buy2, buy3, sell1, sell2, sell3))
      return false;
   const double pip = Phase17_GetPipSize();
   if(pip <= 0.0)
      return false;
   const int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);

   // R428: healing must reproduce the same ATR-derived stop the grid was placed
   // with, otherwise a repaired position would carry the old fixed-pip risk.
   double beyond = TGM_SHARED_SL_BEYOND_LAST_PIPS * pip;
   if(RESEARCH_ATR_SHARED_SLTP)
     {
      double atrValue = 0.0;
      if(!GetLiveATR(atrValue) || atrValue <= 0.0)
         return false;
      beyond = atrValue * SL_ATR_Multiplier;
     }

   if(side == POSITION_TYPE_BUY)
      slOut = NormalizeDouble(buy3 - beyond, digits);
   else
      slOut = NormalizeDouble(sell3 + beyond, digits);
   return (slOut > 0.0);
  }

//--- Mode B: SL distance for lot/heal math.
double GetActiveHedgeTriggerUSD()
  {
   return GetConfiguredStopDistance();
  }

//--- Legacy stub (Mode A removed).
double GetActiveHedgeBreakEvenUSD()
  {
   return (InpHedgeBreakEvenUSD > 0.0) ? InpHedgeBreakEvenUSD : 1.0;
  }

//--- Ensure parent has broker shared SL (last+/-50pip). Heal if cleared.
bool EnsureModeBFixedBrokerSL(const ulong parentTicket)
  {
   if(parentTicket == 0)
      return false;
   if(!IsOurBotGridParent(parentTicket))
      return false;
   if(IsProfitEngineArmed(parentTicket))
      return false;

   CPositionInfo pos;
   if(!pos.SelectByTicket(parentTicket))
      return false;
   if(pos.StopLoss() > 0.0)
      return true;

   const int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   const double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   if(point <= 0.0)
      return false;

   double targetSL = 0.0;
   if(!GetSharedGridSideStopLoss(pos.PositionType(), targetSL) || targetSL <= 0.0)
     {
      const double slDist = GetConfiguredStopDistance();
      if(slDist <= 0.0)
         return false;
      if(pos.PositionType() == POSITION_TYPE_BUY)
         targetSL = NormalizeDouble(pos.PriceOpen() - slDist, digits);
      else
         targetSL = NormalizeDouble(pos.PriceOpen() + slDist, digits);
     }

   const double stops  = GetSymbolStopsPrice();
   const double liveTP = pos.TakeProfit();

   if(pos.PositionType() == POSITION_TYPE_BUY)
     {
      const double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      const double maxValid = NormalizeDouble(bid - stops - point, digits);
      if(targetSL > maxValid)
         targetSL = maxValid;
      if(targetSL >= bid)
         return false;
     }
   else
     {
      const double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      const double minValid = NormalizeDouble(ask + stops + point, digits);
      if(targetSL < minValid)
         targetSL = minValid;
      if(targetSL <= ask)
         return false;
     }

   if(IsTradeModifyCooldownActive())
      return false;
   if(!SafePositionModify(parentTicket, targetSL, liveTP, "ModeB-SharedSL"))
      return false;

   PrintFormat("TGM [MODE-B]: Parent #%I64u shared SL restored at %.*f (last+/-%.0fpip).",
               parentTicket, digits, targetSL, TGM_SHARED_SL_BEYOND_LAST_PIPS);
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
   // R441 strict cycle: one fill per level per H4 — never re-arm after TP/SL
   if(StrictH4CycleOnly())
      return 1;
   return MathMax(1, PHASE18_MAX_LEVEL_ACTIVATIONS_H4);
  }

bool StrictH4CycleOnly()
  {
   return (RESEARCH_INVERT_SIDES || EnableUnifiedMethodRouter || RESEARCH_DIRECTIONAL_AUTO);
  }

bool IsEmergencyLockThisH4()
  {
   if(!Enable_Triple_Protection)
     {
      g_emergencyKillSwitchActive = false;
      return false;
     }
   ClearEmergencyLockIfNewH4();
   const datetime h4 = GetCurrentH4BarOpenTime();
   if(h4 <= 0 || g_emergencyLockH4Open <= 0)
     {
      g_emergencyKillSwitchActive = false;
      return false;
     }
   const bool locked = (g_emergencyLockH4Open == h4);
   g_emergencyKillSwitchActive = locked;
   return locked;
  }

void ClearEmergencyLockIfNewH4()
  {
   const datetime h4 = GetCurrentH4BarOpenTime();
   if(h4 > 0 && g_emergencyLockH4Open > 0 && g_emergencyLockH4Open != h4)
     {
      PrintFormat("TGM [R441]: Emergency H4-lock cleared on new H4 (was %s).",
                  TimeToString(g_emergencyLockH4Open, TIME_DATE|TIME_MINUTES));
      g_emergencyLockH4Open = 0;
      g_emergencyLockReason = "";
      g_emergencyKillSwitchActive = false;
      // Clear legacy day-kill GV so old "until tomorrow" locks die
      const string dayKey = KillSwitchDayKey();
      if(GlobalVariableCheck(dayKey))
         GlobalVariableDel(dayKey);
     }
  }

void SetEmergencyLockThisH4(const string reason)
  {
   const datetime h4 = GetCurrentH4BarOpenTime();
   g_emergencyLockH4Open = h4;
   g_emergencyLockReason = reason;
   g_emergencyKillSwitchActive = true;
   g_accountProtectionActive = true;
   g_accountProtectionReason = "H4 LOCK: " + reason;
   g_h4PlacementDone = true; // no more placement this H4
   PrintFormat("TGM [R441]: Emergency lock THIS H4 only (%s) — next placement on next H4 candle.",
               TimeToString(h4, TIME_DATE|TIME_MINUTES));
  }

void MarkH4PlacementDone()
  {
   g_h4PlacementDone = true;
  }

int GridLevelCommentIndex(const string comment)
  {
   string names[6] = {"GM_BL1","GM_BL2","GM_BL3","GM_SL1","GM_SL2","GM_SL3"};
   for(int i = 0; i < 6; i++)
      if(names[i] == comment)
         return i;
   return -1;
  }

void MarkPendingClaim(const string comment)
  {
   const int idx = GridLevelCommentIndex(comment);
   if(idx >= 0)
      g_pendingClaimTime[idx] = TimeCurrent();
  }

void ClearPendingClaim(const string comment)
  {
   const int idx = GridLevelCommentIndex(comment);
   if(idx >= 0)
      g_pendingClaimTime[idx] = 0;
  }

bool IsStalePendingClaim(const string comment)
  {
   const int idx = GridLevelCommentIndex(comment);
   if(idx < 0)
      return true;
   if(g_pendingClaimTime[idx] <= 0)
      return true;
   return ((TimeCurrent() - g_pendingClaimTime[idx]) >= TGM_PENDING_CLAIM_STALE_SEC);
  }

bool LevelNeedsPendingRestore(const string comment)
  {
   if(comment == "")
      return false;
   if(HasBotPendingByComment(comment))
      return false;
   if(IsCommentActiveInPositions(comment))
      return false;
   if(IsLevelBELockedThisH4(comment) || IsLevelActivationExhaustedThisH4(comment))
      return false;
   if(GetLevelActivationCountThisH4(comment) >= MaxLevelActivationsThisH4())
      return false;
   const double st = GetGridLevelState(comment);
   if(st == TGM_GRID_LEVEL_SPENT || st == TGM_GRID_LEVEL_LIVE)
      return false;
   if(st == TGM_GRID_LEVEL_PENDING && GetGridLevelTicket(comment) == 0 && !IsStalePendingClaim(comment))
      return false;
   return true;
  }

bool AnyLevelNeedsPendingRestore()
  {
   string comments[6] = {"GM_BL1","GM_BL2","GM_BL3","GM_SL1","GM_SL2","GM_SL3"};
   for(int i = 0; i < 6; i++)
      if(LevelNeedsPendingRestore(comments[i]))
         return true;
   return false;
  }

void HealGhostPendingStates(const string reason)
  {
   string comments[6] = {"GM_BL1","GM_BL2","GM_BL3","GM_SL1","GM_SL2","GM_SL3"};
   bool any = false;
   for(int i = 0; i < 6; i++)
     {
      const string comment = comments[i];
      if(GetGridLevelState(comment) != TGM_GRID_LEVEL_PENDING)
         continue;
      if(FindGridPendingTicketByComment(comment) > 0)
         continue;
      if(GetGridLevelTicket(comment) == 0 && !IsStalePendingClaim(comment))
         continue;
      if(IsLevelAlreadySpentInCurrentH4Bar(comment))
        {
         SetGridLevelState(comment, TGM_GRID_LEVEL_SPENT);
         continue;
        }
      ClearGridLevelState(comment);
      ClearPendingClaim(comment);
      any = true;
     }
   if(any)
      PrintFormat("TGM [R444]: Cleared ghost PENDING state(s) (%s).", reason);
  }

int MaintainArmedPendings(const string trigger)
  {
   if(!StrictH4CycleOnly())
      return 0;
   if(IsEmergencyLockThisH4())
      return 0;
   if(!IsGridOpsAllowed())
      return 0;
   if(!g_h4PlacementDone)
      return 0;

   HealGhostPendingStates(trigger);
   if(!AnyLevelNeedsPendingRestore())
      return 0;

   if(trigger == "OnTick")
     {
      const datetime now = TimeCurrent();
      if(g_lastPendingMaintainTime != 0 && (now - g_lastPendingMaintainTime) < 1)
         return 0;
      g_lastPendingMaintainTime = now;
     }

   // fresh=true: bypass floating-DD block so underwater leftovers cannot stop restore
   if(!IsGridPlacementAllowed(true))
      return 0;

   const int n = ExecuteH4GridStrategy(true);
   if(n > 0)
      PrintFormat("TGM [R444]: Restored %d pending level(s) (%s). pendingNow=%d",
                  n, trigger, CountBotPendings());
   return n;
  }

bool CanPlaceGridThisH4()
  {
   if(IsEmergencyLockThisH4())
      return false;
   if(StrictH4CycleOnly() && g_h4PlacementDone)
      return false;
   return true;
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
   const double net = HistoryDealGetDouble(dealTicket, DEAL_PROFIT)
                    + HistoryDealGetDouble(dealTicket, DEAL_SWAP)
                    + HistoryDealGetDouble(dealTicket, DEAL_COMMISSION);

   // Profit OR loss exit: level done for this H4 — NO re-arm (R441 strict cycle)
   if(net > 0.0 || (posId > 0 && IsProfitEngineArmed(posId)))
     {
      if(IsPartialClosedBeRunner(posId) || IsProfitEngineArmed(posId))
         LogPhase28A("RUNNER_SL_CLOSE", posId,
                     StringFormat("level=%s net=%.2f deal_comment=%s", level, net, dealComment));
      MarkLevelBELockedThisH4(level);
      MarkLevelActivationExhaustedThisH4(level);
      SetGridLevelState(level, TGM_GRID_LEVEL_SPENT);
      PrintFormat("TGM [R441]: Level %s PROFIT exit — spent until next H4 (net $%.2f).", level, net);
      return;
     }

   // SL / loss exit: same rule — trade finished, wait next H4
   MarkLevelActivationExhaustedThisH4(level);
   MarkLevelBELockedThisH4(level);
   SetGridLevelState(level, TGM_GRID_LEVEL_SPENT);
   const int cancelled = CancelPendingOrdersForLevel(level);
   PrintFormat("TGM [R441]: Level %s SL/LOSS exit — spent until next H4 | PENDING_CANCELLED=%d | net=$%.2f",
               level, cancelled, net);
   // Intentionally NO ExecuteH4GridStrategy() — next pendings only on new H4 bar
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
   PrintFormat("TGM [MODE-B]: Level %s LOCKED for this H4 (profit BE hit) ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â no more re-entries.", comment);
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
   // Phase28/27: do NOT reset level state here ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â callers reset BEFORE placement.
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
      // Tag as ForceFlatten/KillSwitch so freeze does not arm 15-min pause
      const string op = (StringFind(reason, "Kill") >= 0 || StringFind(reason, "Flatten") >= 0 ||
                         StringFind(reason, "Gap") >= 0)
                        ? "ForceFlattenClose" : "PositionClose";
      if(!ExecuteTradeOp(op, g_trade.PositionClose(ticket),
                         StringFormat("ticket=%I64u reason=%s", ticket, reason)))
         g_forceFlattenActive = true;
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
   if(g_effectiveRiskMode == RISK_MANUAL_LOT && g_effectiveManualLotSize > 0.0)
      return g_effectiveManualLotSize;
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

   PrintFormat("TGM [BASKET-TP]: Locked. New BalanceÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â°Ãƒâ€¹Ã¢â‚¬Â $%.2f EquityÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â°Ãƒâ€¹Ã¢â‚¬Â $%.2f | grid reset.",
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

// sideToRestrict = the losing / opposite side we want to pause.
// Mode B exact method: ALWAYS keep full 3BUY+3SELL ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â never strip opposite side.
bool IsOppositeBleedPaused(const ENUM_POSITION_TYPE sideToRestrict)
  {
   if(IsFixedSlReentryMode())
      return false;
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
   // Mode B: exact method keeps all 6 levels for the full H4 ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â no opposite delete.
   if(IsFixedSlReentryMode())
      return;

   static datetime lastLogSec = 0;
   const datetime now = TimeCurrent();

   if(HasWinningSideArmed(POSITION_TYPE_BUY))
     {
      // Inverted method arms stop orders, so the opposite pending is a sell stop.
      const int n = DeleteBotPendingsOfType(ResearchInvertedUsesBreakoutPlacement() ? ORDER_TYPE_SELL_STOP
                                                                  : ORDER_TYPE_SELL_LIMIT);
      if(n > 0 && now != lastLogSec)
        {
         lastLogSec = now;
         PrintFormat("TGM [BLEED-PROTECT]: BUY side BE/trailing - removed %d opposite SELL limit(s).", n);
        }
     }

   if(HasWinningSideArmed(POSITION_TYPE_SELL))
     {
      const int n = DeleteBotPendingsOfType(ResearchInvertedUsesBreakoutPlacement() ? ORDER_TYPE_BUY_STOP
                                                                  : ORDER_TYPE_BUY_LIMIT);
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

void CleanupEAChartVisuals()
  {
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

      // In-flight claim: PENDING with ticket 0 is only valid for a few seconds after OrderSend.
      // Stale claims (failed send / reconnect) blocked all re-arms — clear them (R444).
      if(oldState == TGM_GRID_LEVEL_PENDING && oldTicket == 0)
        {
         if(!IsStalePendingClaim(comment))
            continue;
         ClearGridLevelState(comment);
         ClearPendingClaim(comment);
         anyChange = true;
        }

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
   // R441 strict: empty book after TP/SL must NOT rebuild until next H4
   if(StrictH4CycleOnly())
      return false;

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

void RefreshGridOnNewH4Bar(const string trigger)
  {
   ClearEmergencyLockIfNewH4();
   g_h4PlacementDone = false;
   g_lastEmptyGridRebuildH4 = 0;
   if(!EnsureAllBotPendingDeleted())
      return;
   ResetAllGridLevelStates();
   LogPhase28A("H4_RESET", 0, StringFormat("trigger=%s acts=0 strict=%s",
                                           trigger, (StrictH4CycleOnly() ? "yes" : "no")));
   if(IsEmergencyLockThisH4())
     {
      Print("TGM [R441]: New H4 but emergency lock still set — skip placement.");
      return;
     }
   ExecuteH4GridStrategy(true);
   MarkH4PlacementDone();
   SaveGridH4BarTime(GetCurrentH4BarOpenTime());
  }

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
   double diff = high1 - low1;
   pivot = NormalizeDouble((high1 + low1) / 2.0, digits);
   // Build 417 Research geometry (outside range):
   //   BUY  = Low  - Diff * {0.20, 0.58, 0.92}
   //   SELL = High + Diff * {0.20, 0.58, 0.92}
   buy1  = NormalizeDouble(low1  - (diff * 0.20), digits);
   buy2  = NormalizeDouble(low1  - (diff * 0.58), digits);
   buy3  = NormalizeDouble(low1  - (diff * 0.92), digits);
   sell1 = NormalizeDouble(high1 + (diff * 0.20), digits);
   sell2 = NormalizeDouble(high1 + (diff * 0.58), digits);
   sell3 = NormalizeDouble(high1 + (diff * 0.92), digits);
   return true;
  }

//--- R428: per-position stop straight off the live ATR, with a fixed target.
//--- This replaces the shared side stop entirely, so each level carries its own
//--- risk rather than dying together with the rest of the grid.
bool ResearchIndivSlTpFor(const bool isBuy, const double entry,
                          double &slOut, double &tpOut, double &lotDistOut)
  {
   if(!RESEARCH_INDIV_SL_TP || entry <= 0.0)
      return false;

   const double pip = Phase17_GetPipSize();
   if(pip <= 0.0 || RESEARCH_TP_PIPS <= 0.0)
      return false;

   double atrValue = 0.0;
   if(!GetLiveATR(atrValue) || atrValue <= 0.0)
      return false;

   const double slDist = atrValue * SL_ATR_Multiplier;
   if(slDist <= 0.0)
      return false;

   const int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   slOut      = NormalizeDouble(isBuy ? (entry - slDist) : (entry + slDist), digits);
   tpOut      = NormalizeDouble(isBuy ? (entry + RESEARCH_TP_PIPS * pip)
                                      : (entry - RESEARCH_TP_PIPS * pip), digits);
   lotDistOut = slDist;
   return true;
  }

//--- Narrow-bar inverted mode (MAX range filter): keep Professional limit placement
//--- at the H4 levels; wide-bar inverted mode (MIN filter) keeps breakout stops.
enum ENUM_RESEARCH_DIR_TREND
  {
   RESEARCH_DIR_TREND_NEUTRAL = 0,
   RESEARCH_DIR_TREND_BULL    = 1,
   RESEARCH_DIR_TREND_BEAR    = -1
  };

ENUM_RESEARCH_DIR_TREND ResearchGetCombinedTrend()
  {
   if(!RESEARCH_DIRECTIONAL_AUTO ||
      g_dirMaH4Handle == INVALID_HANDLE ||
      g_dirMaD1Handle == INVALID_HANDLE)
      return RESEARCH_DIR_TREND_NEUTRAL;

   double closeH4[], maH4[], closeD1[], maD1[];
   ArraySetAsSeries(closeH4, true);
   ArraySetAsSeries(maH4, true);
   ArraySetAsSeries(closeD1, true);
   ArraySetAsSeries(maD1, true);

   if(CopyClose(_Symbol, PERIOD_H4, 1, 1, closeH4) != 1 ||
      CopyBuffer(g_dirMaH4Handle, 0, 1, 1, maH4) != 1 ||
      CopyClose(_Symbol, PERIOD_D1, 1, 1, closeD1) != 1 ||
      CopyBuffer(g_dirMaD1Handle, 0, 1, 1, maD1) != 1)
      return RESEARCH_DIR_TREND_NEUTRAL;

   const bool bullH4 = closeH4[0] > maH4[0];
   const bool bullD1 = closeD1[0] > maD1[0];
   const bool bearH4 = closeH4[0] < maH4[0];
   const bool bearD1 = closeD1[0] < maD1[0];

   if(bullH4 && bullD1)
      return RESEARCH_DIR_TREND_BULL;
   if(bearH4 && bearD1)
      return RESEARCH_DIR_TREND_BEAR;
   return RESEARCH_DIR_TREND_NEUTRAL;
  }

bool ResearchApplyDirectionalCyclePlan(const double rangePips)
  {
   g_dirEnableBuyArm      = false;
   g_dirEnableSellArm     = false;
   g_dirBreakoutPlacement = false;

   //--- R445 Unified Method Router: range class -> BOTH buy+sell arms (2 methods).
   if(EnableUnifiedMethodRouter)
     {
      const datetime h4Open = iTime(_Symbol, PERIOD_H4, 0);
      STgmRouterDecision d;
      const bool ok = g_unifiedRouter.EvaluateForH4Cycle(h4Open, rangePips, d);
      g_lastRouterDecision = d;
      if(!ok)
         return false;
      g_dirEnableBuyArm      = d.armBuyLoop;
      g_dirEnableSellArm     = d.armSellLoop;
      g_dirBreakoutPlacement = d.breakoutPlacement;
      return (g_dirEnableBuyArm || g_dirEnableSellArm);
     }

   //--- Legacy R432 simple SMA agreement router
   if(rangePips > RESEARCH_DIR_NARROW_MAX_PIPS && rangePips < RESEARCH_DIR_WIDE_MIN_PIPS)
     {
      PrintFormat("TGM [R432]: H4 range %.0fpip in dead zone (%.0f-%.0f) - skip cycle.",
                  rangePips, RESEARCH_DIR_NARROW_MAX_PIPS, RESEARCH_DIR_WIDE_MIN_PIPS);
      return false;
     }

   const ENUM_RESEARCH_DIR_TREND trend = ResearchGetCombinedTrend();
   if(trend == RESEARCH_DIR_TREND_NEUTRAL)
     {
      Print("TGM [R432]: H4/Daily trend not aligned - no pendings this cycle.");
      return false;
     }

   if(trend == RESEARCH_DIR_TREND_BULL)
     {
      if(rangePips >= RESEARCH_DIR_WIDE_MIN_PIPS)
        {
         g_dirEnableSellArm     = true;
         g_dirBreakoutPlacement = true;
         PrintFormat("TGM [R432]: BULL + wide >=%.0fpip -> breakout BUY (sell-loop stops).",
                     RESEARCH_DIR_WIDE_MIN_PIPS);
        }
      else if(rangePips <= RESEARCH_DIR_NARROW_MAX_PIPS)
        {
         g_dirEnableBuyArm      = true;
         g_dirBreakoutPlacement = false;
         PrintFormat("TGM [R432]: BULL + narrow <=%.0fpip -> limit BUY (buy-loop limits).",
                     RESEARCH_DIR_NARROW_MAX_PIPS);
        }
      else
         return false;
     }
   else
     {
      if(rangePips >= RESEARCH_DIR_WIDE_MIN_PIPS)
        {
         g_dirEnableBuyArm      = true;
         g_dirBreakoutPlacement = true;
         PrintFormat("TGM [R432]: BEAR + wide >=%.0fpip -> breakout SELL (buy-loop stops).",
                     RESEARCH_DIR_WIDE_MIN_PIPS);
        }
      else if(rangePips <= RESEARCH_DIR_NARROW_MAX_PIPS)
        {
         g_dirEnableSellArm     = true;
         g_dirBreakoutPlacement = false;
         PrintFormat("TGM [R432]: BEAR + narrow <=%.0fpip -> limit SELL (sell-loop limits).",
                     RESEARCH_DIR_NARROW_MAX_PIPS);
        }
      else
         return false;
     }

   return (g_dirEnableBuyArm || g_dirEnableSellArm);
  }

bool ResearchInvertedUsesBreakoutPlacement()
  {
   if(!RESEARCH_INVERT_SIDES)
      return false;
   if(EnableUnifiedMethodRouter || RESEARCH_DIRECTIONAL_AUTO)
      return g_dirBreakoutPlacement;
   if(RESEARCH_MAX_H4_RANGE_PIPS > 0.0)
      return false;
   return true;
  }

bool ResearchInvertedSlTpFor(const bool placingBuy, const double entry,
                             const int levelIndex,
                             double &slOut, double &tpOut, double &lotDistOut)
  {
   if(!RESEARCH_INVERT_SIDES || entry <= 0.0)
      return false;

   const double pip = Phase17_GetPipSize();
   if(pip <= 0.0)
      return false;

   double slPips = RESEARCH_FIX_SL_PIPS;
   const double perLevel[3] = {RESEARCH_INV_TP_L1_PIPS,
                               RESEARCH_INV_TP_L2_PIPS,
                               RESEARCH_INV_TP_L3_PIPS};
   if(levelIndex >= 0 && levelIndex <= 2 && perLevel[levelIndex] > 0.0)
      slPips = perLevel[levelIndex];
   if(slPips <= 0.0)
      return false;

   const double rr = (RESEARCH_RR_TP_MULT > 0.0) ? RESEARCH_RR_TP_MULT : 1.5;
   const double tpPips = slPips * rr;

   const int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);

   // R447: fixed SL per level; TP = SL × RR (default 1.5).
   double slDist = slPips * pip;
   if(RESEARCH_INVERT_ATR_SL)
     {
      double atrValue = 0.0;
      if(!GetLiveATR(atrValue) || atrValue <= 0.0)
         return false;
      slDist = atrValue * SL_ATR_Multiplier;
     }
   if(slDist <= 0.0)
      return false;

   const double tpDist = (RESEARCH_INVERT_ATR_SL ? (slDist * rr) : (tpPips * pip));

   slOut      = NormalizeDouble(placingBuy ? (entry - slDist) : (entry + slDist), digits);
   tpOut      = NormalizeDouble(placingBuy ? (entry + tpDist) : (entry - tpDist), digits);
   lotDistOut = slDist;
   return true;
  }

//--- R428: which levels are armed. Mask lets a middle level be skipped.
bool ResearchLevelEnabled(const int levelIndex)
  {
   if(levelIndex < 0 || levelIndex > 2)
      return false;
   if(RESEARCH_LEVEL_MASK <= 0)
      return true;
   return ((RESEARCH_LEVEL_MASK & (1 << levelIndex)) != 0);
  }

//--- R428: restrict placement to a whitelist of H4 cycles.
bool ResearchCycleAllowed()
  {
   if(StringLen(RESEARCH_CYCLES) == 0)
      return true;

   const datetime h4 = GetCurrentH4BarOpenTime();
   if(h4 <= 0)
      return false;
   MqlDateTime dt;
   TimeToStruct(h4, dt);
   const int cycle = dt.hour - (dt.hour % 4);

   string parts[];
   const int n = StringSplit(RESEARCH_CYCLES, ',', parts);
   for(int i = 0; i < n; i++)
     {
      if(StringLen(parts[i]) == 0)
         continue;
      const int wanted = (int)StringToInteger(parts[i]);
      if(wanted - (wanted % 4) == cycle)
         return true;
     }
   return false;
  }

bool CalculateExcelGridSLTP(const double buy1, const double buy2, const double buy3, const double sell1, const double sell2, const double sell3, const double atrValue, double &buySL, double &sellSL, double &buyTP1, double &buyTP2, double &buyTP3, double &sellTP1, double &sellTP2, double &sellTP3)
  {
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   const double pip = Phase17_GetPipSize();
   if(pip <= 0.0)
      return false;

   if(atrValue <= 0.0)
      return false;

   // R428: one SL and one TP for the whole side, both scaled off the live ATR.
   // The SL anchors on the furthest level and the TP on the nearest one, which
   // is the only pairing that stays valid for every level in the grid.
   if(RESEARCH_ATR_SHARED_SLTP)
     {
      const double slDist = atrValue * SL_ATR_Multiplier;
      const double tpDist = atrValue * TP_ATR_Multiplier;
      if(slDist <= 0.0 || tpDist <= 0.0)
         return false;

      buySL  = NormalizeDouble(buy3  - slDist, digits);
      sellSL = NormalizeDouble(sell3 + slDist, digits);

      const double buyTP  = NormalizeDouble(buy1  + tpDist, digits);
      const double sellTP = NormalizeDouble(sell1 - tpDist, digits);

      buyTP1  = buyTP;
      buyTP2  = buyTP;
      buyTP3  = buyTP;
      sellTP1 = sellTP;
      sellTP2 = sellTP;
      sellTP3 = sellTP;

      return (buySL > 0.0 && sellSL > 0.0 && buyTP > 0.0 && sellTP > 0.0);
     }

   // Shared SL for all 3 levels: 50pip beyond the LAST (furthest) level - also used for lot sizing.
   buySL  = NormalizeDouble(buy3  - (TGM_SHARED_SL_BEYOND_LAST_PIPS * pip), digits);
   sellSL = NormalizeDouble(sell3 + (TGM_SHARED_SL_BEYOND_LAST_PIPS * pip), digits);

   const double tpDist = atrValue * TP_ATR_Multiplier;
   if(tpDist <= 0.0)
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
   if(IsEmergencyLockThisH4())
      return 0;
   // R441: after the one H4 placement shot, never refill mid-candle
   if(StrictH4CycleOnly() && g_h4PlacementDone && !freshH4Cycle)
      return 0;
   if(!IsGridPlacementAllowed(freshH4Cycle))
      return 0;
   if(!ResearchCycleAllowed())
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

   // R428: a very wide previous H4 bar means the grid would be placed into an
   // already-extended move, so the whole cycle is skipped.
   const double pipSize = Phase17_GetPipSize();
   double rangePips = 0.0;
   if(pipSize > 0.0)
      rangePips = (high1 - low1) / pipSize;

   if(EnableUnifiedMethodRouter || RESEARCH_DIRECTIONAL_AUTO)
     {
      if(pipSize <= 0.0)
        {
         g_gridStrategyBusy = false;
         return 0;
        }
      if(!ResearchApplyDirectionalCyclePlan(rangePips))
        {
         g_gridStrategyBusy = false;
         return 0;
        }
     }
   else if(RESEARCH_MAX_H4_RANGE_PIPS > 0.0 || RESEARCH_MIN_H4_RANGE_PIPS > 0.0)
     {
      if(pipSize <= 0.0)
        {
         g_gridStrategyBusy = false;
         return 0;
        }
      if(RESEARCH_MAX_H4_RANGE_PIPS > 0.0 && rangePips > RESEARCH_MAX_H4_RANGE_PIPS)
        {
         PrintFormat("TGM [R428]: H4 range %.0fpip > %.0fpip limit - no pendings this cycle.",
                     rangePips, RESEARCH_MAX_H4_RANGE_PIPS);
         g_gridStrategyBusy = false;
         return 0;
        }
      if(RESEARCH_MIN_H4_RANGE_PIPS > 0.0 && rangePips < RESEARCH_MIN_H4_RANGE_PIPS)
        {
         PrintFormat("TGM [R429]: H4 range %.0fpip < %.0fpip minimum - no pendings this cycle.",
                     rangePips, RESEARCH_MIN_H4_RANGE_PIPS);
         g_gridStrategyBusy = false;
         return 0;
        }
     }

   const bool armBuyLoop  = (EnableUnifiedMethodRouter || RESEARCH_DIRECTIONAL_AUTO) ? g_dirEnableBuyArm : RESEARCH_ENABLE_BUY;
   const bool armSellLoop = (EnableUnifiedMethodRouter || RESEARCH_DIRECTIONAL_AUTO) ? g_dirEnableSellArm : RESEARCH_ENABLE_SELL;

   double buySL, sellSL, buyTP1, buyTP2, buyTP3, sellTP1, sellTP2, sellTP3;
   if(!CalculateExcelGridSLTP(buy1, buy2, buy3, sell1, sell2, sell3, atrValue, buySL, sellSL, buyTP1, buyTP2, buyTP3, sellTP1, sellTP2, sellTP3))
     {
      g_gridStrategyBusy = false;
      return 0;
     }

   const double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   const double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   // Build 417: ALL buy levels use |buy1->sharedSL| for lots; SAME shared SL on all 3.
   const double buyLotDist  = MathAbs(buy1 - buySL);
   const double sellLotDist = MathAbs(sellSL - sell1);

   // Full grid: 3 BUY + 3 SELL. Shared SL = last level +/- 50pip.
   double buyEntries[3] = {buy1, buy2, buy3};
   double buyTPs[3]     = {buyTP1, buyTP2, buyTP3};
   string buyComments[3]= {"GM_BL1", "GM_BL2", "GM_BL3"};

   for(int b = 0; armBuyLoop && b < 3; b++)
     {
      if(!ResearchLevelEnabled(b))
         continue;
      if(!LiveSafeAllowsNewPending(b))
         continue;
      if(IsOppositeBleedPaused(POSITION_TYPE_BUY))
         break;

      const double entry_price   = buyEntries[b];
      double       calculated_SL = buySL; // SAME shared SL on all 3 BUY levels
      double       tp            = buyTPs[b];
      const string comment       = buyComments[b];
      double       slDistLots    = buyLotDist;

      if(RESEARCH_INDIV_SL_TP &&
         !ResearchIndivSlTpFor(true, entry_price, calculated_SL, tp, slDistLots))
         continue;
      // Inverted SL/TP ladder; placement direction follows the order type used.
      if(RESEARCH_INVERT_SIDES &&
         !ResearchInvertedSlTpFor(!ResearchInvertedUsesBreakoutPlacement(), entry_price, b,
                                 calculated_SL, tp, slDistLots))
         continue;

      const double levelState = GetGridLevelState(comment);
      if(HasBotPendingByComment(comment) || levelState == TGM_GRID_LEVEL_PENDING) continue;
      if(levelState == TGM_GRID_LEVEL_LIVE && LevelHasLivePositionThisH4(comment)) continue;
      if(levelState == TGM_GRID_LEVEL_SPENT) continue;
      if(IsLevelBELockedThisH4(comment) || IsLevelActivationExhaustedThisH4(comment)) continue;
      if(GetLevelActivationCountThisH4(comment) >= MaxLevelActivationsThisH4()) continue;
      if(!Phase17_AllowReArm(GetLevelActivationCountThisH4(comment))) continue;
      if(IsGridEntryPriceBlocked(entry_price)) continue;
      if(ResearchInvertedUsesBreakoutPlacement() ? (calculated_SL <= entry_price) : (calculated_SL >= entry_price)) continue;
      if(slDistLots <= 0.0) continue;

      if(ResearchInvertedUsesBreakoutPlacement())
        {
         // Wide-bar inverted: sell stop under the bid at the buy level.
         if(bid > entry_price)
           {
            if(PlaceSellStop(entry_price, calculated_SL, tp, slDistLots, b, comment)) placedCount++;
           }
         else
           {
            LogPriceThroughOnce(comment,
               StringFormat("STOP_INVALID_PRICE_THROUGH SELLSTOP bid=%.3f <= level=%.3f WAIT",
                            bid, entry_price));
           }
        }
      else if(ask > entry_price)
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

   for(int s = 0; armSellLoop && s < 3; s++)
     {
      if(!ResearchLevelEnabled(s))
         continue;
      if(!LiveSafeAllowsNewPending(s))
         continue;
      if(IsOppositeBleedPaused(POSITION_TYPE_SELL))
         break;

      const double entry_price   = sellEntries[s];
      double       calculated_SL = sellSL; // SAME shared SL on all 3 SELL levels
      double       tp            = sellTPs[s];
      const string comment       = sellComments[s];
      double       slDistLots    = sellLotDist;

      if(RESEARCH_INDIV_SL_TP &&
         !ResearchIndivSlTpFor(false, entry_price, calculated_SL, tp, slDistLots))
         continue;
      if(RESEARCH_INVERT_SIDES &&
         !ResearchInvertedSlTpFor(ResearchInvertedUsesBreakoutPlacement(), entry_price, s,
                                 calculated_SL, tp, slDistLots))
         continue;

      const double levelState = GetGridLevelState(comment);
      if(HasBotPendingByComment(comment) || levelState == TGM_GRID_LEVEL_PENDING) continue;
      if(levelState == TGM_GRID_LEVEL_LIVE && LevelHasLivePositionThisH4(comment)) continue;
      if(levelState == TGM_GRID_LEVEL_SPENT) continue;
      if(IsLevelBELockedThisH4(comment) || IsLevelActivationExhaustedThisH4(comment)) continue;
      if(GetLevelActivationCountThisH4(comment) >= MaxLevelActivationsThisH4()) continue;
      if(!Phase17_AllowReArm(GetLevelActivationCountThisH4(comment))) continue;
      if(IsGridEntryPriceBlocked(entry_price)) continue;
      if(ResearchInvertedUsesBreakoutPlacement() ? (calculated_SL >= entry_price) : (calculated_SL <= entry_price)) continue;
      if(slDistLots <= 0.0) continue;

      if(ResearchInvertedUsesBreakoutPlacement())
        {
         // Wide-bar inverted: buy stop above the ask at the sell level.
         if(ask < entry_price)
           {
            if(PlaceBuyStop(entry_price, calculated_SL, tp, slDistLots, s, comment)) placedCount++;
           }
         else
           {
            LogPriceThroughOnce(comment,
               StringFormat("STOP_INVALID_PRICE_THROUGH BUYSTOP ask=%.3f >= level=%.3f WAIT",
                            ask, entry_price));
           }
        }
      else if(bid < entry_price)
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
//| Auto lot: 2% of EQUITY vs per-level SL distance (R448) |
//+------------------------------------------------------------------+
double GetLotSizingCapital()
  {
   double cap = AccountInfoDouble(ACCOUNT_EQUITY);
   if(cap > 0.0)
      return cap;
   return AccountInfoDouble(ACCOUNT_BALANCE);
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
   return NormalizeVolume(lots);
  }

double GetTradeVolume(const double slDistancePrice, const int levelIndex)
  {
   double lots = (g_effectiveRiskMode == RISK_MANUAL_LOT) ? NormalizeVolume(g_effectiveManualLotSize) : CalculateAutoLotSize(slDistancePrice, levelIndex);
   lots *= Phase17_GetLotExposureMultiplier();
   return NormalizeVolume(lots);
  }

double NormalizeVolume(double volume) 
  { 
   double vmin = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN); 
   double vmax = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX); 
   double vstep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   // Broker max + optional manual Max_Lot_Size ceiling; auto path itself is not hard-capped.
   if(g_effectiveMaxLotSize > 0.0 && g_effectiveMaxLotSize < vmax)
      vmax = g_effectiveMaxLotSize;
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
   PrintFormat("TGM [LOTDBG]: %s %s L%d | balance=%.2f risk$=%.2f sl_price=%.3f sl_pips=%.1f raw=%.4f dd_mult=%.2f dd_lots=%.2f final=%.2f",
               tag, comment, levelIndex + 1, equity, riskAmount, slDistancePrice, slPips, rawLots, ddMult, ddLots, finalLots);
  }

bool PlaceBuyLimit(const double price, const double sl, const double tp, const double slDistForLots, const int levelIndex, const string comment)
  {
   if(!PreTradeGuard("BuyLimit"))
      return false;
   if(!GmP11B_AllowPlacement(comment, levelIndex))
      return false;
   // Hard stop: never open a second pending/position at the same entry price.
   if(IsGridEntryPriceBlocked(price) || HasBotPendingByComment(comment) ||
      GetGridLevelState(comment) == TGM_GRID_LEVEL_PENDING)
     {
      PrintFormat("TGM [DEDUP]: Skip BuyLimit %s @ %s ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â level/price already armed.",
                  comment, DoubleToString(price, (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS)));
      return false;
     }

   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   double lots = GmP11B_AdjustLot(GetTradeVolume(slDistForLots, levelIndex), levelIndex, comment, true);
   // Always attach broker SL (fixed $3 or ATR). TP = live ATR.
   const bool attachSL = (sl > 0.0);
   double orderSL = attachSL ? NormalizeDouble(sl, digits) : 0.0;
   double orderTP = NormalizeDouble(tp, digits); // always live ATR TP
   // PHASE 14 ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â Institutional AI Validation (enhancement only; OFF = pass-through)
   if(!GmP14_ValidateBeforeOrderSend(true, price, orderSL, orderTP, comment, levelIndex))
      return false;
   LogLotCalculationDetail("BuyLimit", comment, levelIndex, slDistForLots, lots);
   // Claim slot BEFORE OrderSend so sync/re-entry cannot place a twin.
   SetGridLevelState(comment, TGM_GRID_LEVEL_PENDING, 0);
   MarkPendingClaim(comment);
   bool ok = g_trade.BuyLimit(lots, price, _Symbol, orderSL, orderTP, ORDER_TIME_GTC, 0, comment);
   const bool placed = ExecuteTradeOp("BuyLimit", ok, StringFormat("comment=%s lots=%.2f price=%.*f", comment, lots, digits, price));
   if(placed)
     {
      SetGridLevelState(comment, TGM_GRID_LEVEL_PENDING, g_trade.ResultOrder());
      ClearPendingClaim(comment);
      GmP11B_RegisterPlaced(g_trade.ResultOrder(), comment, levelIndex);
     }
   else
     {
      ClearGridLevelState(comment);
      ClearPendingClaim(comment);
     }
   return placed;
  }

bool PlaceBuyStop(const double price, const double sl, const double tp, const double slDistForLots, const int levelIndex, const string comment)
  {
   if(!PreTradeGuard("BuyStop"))
      return false;
   if(!GmP11B_AllowPlacement(comment, levelIndex))
      return false;
   if(IsGridEntryPriceBlocked(price) || HasBotPendingByComment(comment) ||
      GetGridLevelState(comment) == TGM_GRID_LEVEL_PENDING)
      return false;

   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   double lots = GmP11B_AdjustLot(GetTradeVolume(slDistForLots, levelIndex), levelIndex, comment, true);
   const bool attachSL = (sl > 0.0);
   double orderSL = attachSL ? NormalizeDouble(sl, digits) : 0.0;
   double orderTP = NormalizeDouble(tp, digits);
   if(!GmP14_ValidateBeforeOrderSend(true, price, orderSL, orderTP, comment, levelIndex))
      return false;
   LogLotCalculationDetail("BuyStop", comment, levelIndex, slDistForLots, lots);
   SetGridLevelState(comment, TGM_GRID_LEVEL_PENDING, 0);
   MarkPendingClaim(comment);
   bool ok = g_trade.BuyStop(lots, price, _Symbol, orderSL, orderTP, ORDER_TIME_GTC, 0, comment);
   const bool placed = ExecuteTradeOp("BuyStop", ok, StringFormat("comment=%s lots=%.2f price=%.*f REARM", comment, lots, digits, price));
   if(placed)
     {
      SetGridLevelState(comment, TGM_GRID_LEVEL_PENDING, g_trade.ResultOrder());
      ClearPendingClaim(comment);
      GmP11B_RegisterPlaced(g_trade.ResultOrder(), comment, levelIndex);
      PrintFormat("TGM [REARM]: BUY STOP %s @ %.*f (price was at/below level after SL).", comment, digits, price);
     }
   else
     {
      ClearGridLevelState(comment);
      ClearPendingClaim(comment);
     }
   return placed;
  }

bool PlaceSellLimit(const double price, const double sl, const double tp, const double slDistForLots, const int levelIndex, const string comment)
  {
   if(!PreTradeGuard("SellLimit"))
      return false;
   if(!GmP11B_AllowPlacement(comment, levelIndex))
      return false;
   if(IsGridEntryPriceBlocked(price) || HasBotPendingByComment(comment) ||
      GetGridLevelState(comment) == TGM_GRID_LEVEL_PENDING)
     {
      PrintFormat("TGM [DEDUP]: Skip SellLimit %s @ %s ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â level/price already armed.",
                  comment, DoubleToString(price, (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS)));
      return false;
     }

   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   double lots = GmP11B_AdjustLot(GetTradeVolume(slDistForLots, levelIndex), levelIndex, comment, false);
   // Always attach broker SL (fixed $3 or ATR). TP = live ATR.
   const bool attachSL = (sl > 0.0);
   double orderSL = attachSL ? NormalizeDouble(sl, digits) : 0.0;
   double orderTP = NormalizeDouble(tp, digits); // always live ATR TP
   if(!GmP14_ValidateBeforeOrderSend(false, price, orderSL, orderTP, comment, levelIndex))
      return false;
   LogLotCalculationDetail("SellLimit", comment, levelIndex, slDistForLots, lots);
   SetGridLevelState(comment, TGM_GRID_LEVEL_PENDING, 0);
   MarkPendingClaim(comment);
   bool ok = g_trade.SellLimit(lots, price, _Symbol, orderSL, orderTP, ORDER_TIME_GTC, 0, comment);
   const bool placed = ExecuteTradeOp("SellLimit", ok, StringFormat("comment=%s lots=%.2f price=%.*f", comment, lots, digits, price));
   if(placed)
     {
      SetGridLevelState(comment, TGM_GRID_LEVEL_PENDING, g_trade.ResultOrder());
      ClearPendingClaim(comment);
      GmP11B_RegisterPlaced(g_trade.ResultOrder(), comment, levelIndex);
     }
   else
     {
      ClearGridLevelState(comment);
      ClearPendingClaim(comment);
     }
   return placed;
  }

bool PlaceSellStop(const double price, const double sl, const double tp, const double slDistForLots, const int levelIndex, const string comment)
  {
   if(!PreTradeGuard("SellStop"))
      return false;
   if(!GmP11B_AllowPlacement(comment, levelIndex))
      return false;
   if(IsGridEntryPriceBlocked(price) || HasBotPendingByComment(comment) ||
      GetGridLevelState(comment) == TGM_GRID_LEVEL_PENDING)
      return false;

   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   double lots = GmP11B_AdjustLot(GetTradeVolume(slDistForLots, levelIndex), levelIndex, comment, false);
   const bool attachSL = (sl > 0.0);
   double orderSL = attachSL ? NormalizeDouble(sl, digits) : 0.0;
   double orderTP = NormalizeDouble(tp, digits);
   if(!GmP14_ValidateBeforeOrderSend(false, price, orderSL, orderTP, comment, levelIndex))
      return false;
   LogLotCalculationDetail("SellStop", comment, levelIndex, slDistForLots, lots);
   SetGridLevelState(comment, TGM_GRID_LEVEL_PENDING, 0);
   MarkPendingClaim(comment);
   bool ok = g_trade.SellStop(lots, price, _Symbol, orderSL, orderTP, ORDER_TIME_GTC, 0, comment);
   const bool placed = ExecuteTradeOp("SellStop", ok, StringFormat("comment=%s lots=%.2f price=%.*f REARM", comment, lots, digits, price));
   if(placed)
     {
      SetGridLevelState(comment, TGM_GRID_LEVEL_PENDING, g_trade.ResultOrder());
      ClearPendingClaim(comment);
      GmP11B_RegisterPlaced(g_trade.ResultOrder(), comment, levelIndex);
      PrintFormat("TGM [REARM]: SELL STOP %s @ %.*f (price was at/above level after SL).", comment, digits, price);
     }
   else
     {
      ClearGridLevelState(comment);
      ClearPendingClaim(comment);
     }
   return placed;
  }

bool ExecutePartialClose(const ulong ticket, const double partialPercent)
  {
   if(!PreProtectionTradeGuard("PositionClosePartial"))
      return false;

   if(IsTicketPartialCloseDone(ticket) || IsPartialClosedBeRunner(ticket))
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
      // Unexpected full close ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â do NOT mark runner complete.
      LogPhase28A("PARTIAL_CLOSE_REQUEST", ticket, "REJECT fully_closed_no_runner");
      PrintFormat("TGM [PARTIAL]: Position #%I64u fully closed after partial on %s ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â runner state NOT marked.",
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
      // Parent still needs protection ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â never close hedge during deep parent loss.
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

//--- A position is our HEDGE when its comment says so OR it is registered as a
//    hedge in the GV table.
bool IsBotHedgePosition(const ulong ticket, const string comment)
  {
   if(WasOpenedAsGridLimit(ticket))
      return false;

   if(IsHedgePositionComment(comment))
      return true;
   if(IsTrackedHedgeTicket(ticket))
      return true;
   if(FindParentForLinkedHedge(ticket) > 0)
      return true;
   if(HasHedgeOpeningEvidence(ticket))
      return true;
   return WasOpenedAsMarketHedge(ticket);
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
      return false; // manual or foreign EA ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ blind

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

//--- Grid trades are ALWAYS opened from Buy/Sell LIMIT pendings (GM_BL/GM_SL).
//    Hedge trades are ALWAYS market Buy/Sell (GM_HEDGE). This split survives
//    broker comment stripping on the live position object.
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
      // Unknown history but OUR magic + not hedge comment ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ still our grid parent.
      // Do NOT return true for foreign tickets (already blocked above).
      if(pos.SelectByTicket(positionTicket) && !IsHedgePositionComment(pos.Comment()))
         return true;
      return false;
     }

   if(IsGridPositionComment(dealComment) || IsGridPositionComment(orderComment))
      return true;
   if(IsHedgePositionComment(dealComment) || IsHedgePositionComment(orderComment))
      return false;

   return (orderType == ORDER_TYPE_BUY_LIMIT || orderType == ORDER_TYPE_SELL_LIMIT ||
           orderType == ORDER_TYPE_BUY_STOP  || orderType == ORDER_TYPE_SELL_STOP);
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
      // JAIL: only OUR grid parents ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â manual trades are invisible here.
      if(!IsOurBotGridParent(pos.Ticket()))
         continue;
      if(pos.PositionType() != parentType)
         continue;
      if(MathAbs(pos.Volume() - hedgeVol) > 0.0001)
         continue;

      ulong linked = 0;
      if(GetLinkedHedgeTicket(pos.Ticket(), linked) && linked != hedgeTicket)
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

ulong ResolveHedgeParentTicket(const ulong hedgeTicket, const string comment)
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

   if(parentTicket == 0)
      parentTicket = InferHedgeParentTicket(hedgeTicket);

   // JAIL: parent must be OUR open grid trade. Manual/foreign ticket IDs are discarded.
   if(parentTicket > 0 && !IsOurBotGridParent(parentTicket))
      return 0;
   return parentTicket;
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
   ulong parentTickets[];
   ArrayResize(parentTickets, 0);

   CPositionInfo pos;
   for(int i = 0; i < PositionsTotal(); i++)
     {
      if(!pos.SelectByIndex(i))
         continue;
      if(pos.Symbol() != _Symbol || pos.Magic() != (ulong)EXPERT_MAGIC)
         continue;
      if(!WasOpenedAsGridLimit(pos.Ticket()))
         continue;

      bool dup = false;
      for(int p = 0; p < ArraySize(parentTickets); p++)
        {
         if(parentTickets[p] == pos.Ticket())
           {
            dup = true;
            break;
           }
        }
      if(!dup)
        {
         const int n = ArraySize(parentTickets);
         ArrayResize(parentTickets, n + 1);
         parentTickets[n] = pos.Ticket();
        }
     }

   for(int g = 0; g < ArraySize(parentTickets); g++)
      ConsolidateDuplicateHedgesForParent(parentTickets[g]);
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

//--- Collect every open hedge belonging to one parent (comment OR GV link).
int CollectHedgesForParent(const ulong parentTicket, ulong &hedgeTickets[])
  {
   ArrayResize(hedgeTickets, 0);
   // JAIL: never collect/manage hedges for manual or foreign parents.
   if(!IsOurBotGridParent(parentTicket))
      return 0;

   const string expected = BuildHedgeComment(parentTicket);

   CPositionInfo pos;
   for(int i = 0; i < PositionsTotal(); i++)
     {
      if(!pos.SelectByIndex(i))
         continue;
      if(pos.Symbol() != _Symbol || pos.Magic() != (ulong)EXPERT_MAGIC)
         continue;
      if(!IsBotHedgePosition(pos.Ticket(), pos.Comment()))
         continue;

      const ulong parsedParent = ResolveHedgeParentTicket(pos.Ticket(), pos.Comment());
      if(parsedParent != parentTicket && pos.Comment() != expected)
         continue;

      bool dup = false;
      for(int d = 0; d < ArraySize(hedgeTickets); d++)
        {
         if(hedgeTickets[d] == pos.Ticket())
           {
            dup = true;
            break;
           }
        }
      if(!dup)
        {
         const int n = ArraySize(hedgeTickets);
         ArrayResize(hedgeTickets, n + 1);
         hedgeTickets[n] = pos.Ticket();
        }
     }

   ulong linked = 0;
   if(GetLinkedHedgeTicket(parentTicket, linked))
     {
      bool dup = false;
      for(int d = 0; d < ArraySize(hedgeTickets); d++)
        {
         if(hedgeTickets[d] == linked)
           {
            dup = true;
            break;
           }
        }
      if(!dup)
        {
         const int n = ArraySize(hedgeTickets);
         ArrayResize(hedgeTickets, n + 1);
         hedgeTickets[n] = linked;
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
      return 0.0; // manual/foreign ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ zero shortfall ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ never hedge
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

//--- Trim only OVER-hedge. Multiple hedge legs that sum to parent volume (1:1 top-up) are kept.
void ConsolidateDuplicateHedgesForParent(const ulong parentTicket)
  {
   ulong hedges[];
   const int n = CollectHedgesForParent(parentTicket, hedges);
   if(n <= 1)
      return;

   CPositionInfo parent;
   if(!parent.SelectByTicket(parentTicket))
      return;

   const double parentVol = parent.Volume();
   const double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double covered = GetHedgedVolumeForParent(parentTicket);

   // Under-hedged or exact 1:1 with multiple legs ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ do NOT close top-up legs.
   if(covered <= parentVol + step)
      return;

   // Over-hedged: close newest extras until coverage ~= parent volume.
   PrintFormat("TGM [HEDGE]: Parent #%I64u OVER-hedged (covered=%.2f parent=%.2f) - trimming extras.",
               parentTicket, covered, parentVol);

   for(int i = n - 1; i >= 0 && covered > parentVol + step; i--)
     {
      CPositionInfo hp;
      if(!hp.SelectByTicket(hedges[i]))
         continue;
      const double hv = hp.Volume();
      if(CloseHedgePosition(hedges[i], "DuplicateCleanup"))
         covered -= hv;
     }
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
   // No LOCK / no rapid-death pause ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â clear state so next tick can re-hedge if loss >= trigger.
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

   // Clear any legacy LOCK state ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â recurrent re-hedge uses cooldown + loss>=trigger only.
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
      LogHedgeBlockOnce(parentTicket, "FOREIGN/MANUAL trade ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â EA is blind (not our magic)");
      return false;
     }

   // Allow open/top-up whenever coverage is incomplete (not merely "any hedge exists").
   const double shortfall = GetHedgeVolumeShortfall(parentTicket);
   if(shortfall <= 0.0)
     {
      LogHedgeBlockOnce(parentTicket, "hedge fully covers parent lots (1:1)");
      return false;
     }

   const double parentLoss = GetPositionLossUSD(parentTicket);
   const double trigger = GetActiveHedgeTriggerUSD();
   if(parentLoss < trigger)
     {
      LogHedgeBlockOnce(parentTicket,
                        StringFormat("loss $%.2f < trigger $%.2f", parentLoss, trigger));
      return false;
     }

   if(IsHedgeReopenCooldownActive(parentTicket))
     {
      // Top-up of an already-live under-hedge must not wait for the 20s gap.
      if(CountHedgesForParent(parentTicket) <= 0)
        {
         LogHedgeBlockOnce(parentTicket, "hedge cooldown (re-open soon if loss >= trigger)");
         return false;
        }
     }

   if(IsHedgeBarLockActive(parentTicket))
     {
      LogHedgeBlockOnce(parentTicket, "H4 hedge cycle limit reached");
      return false;
     }

   if(IsHedgeCycleLimitReached(parentTicket))
     {
      LogHedgeBlockOnce(parentTicket, "max hedge cycles this H4 bar");
      return false;
     }

   if(IsHedgeChopFrozen(parentTicket))
     {
      const double center = GlobalVariableGet(HedgeChopCenterKey(parentTicket));
      LogHedgeBlockOnce(parentTicket,
                        StringFormat("CHOP FREEZE active (zone center %.2f)", center));
      return false;
     }

   CPositionInfo parentPos;
   if(parentPos.SelectByTicket(parentTicket))
     {
      if(IsOppositeBleedPaused(parentPos.PositionType()))
        {
         LogHedgeBlockOnce(parentTicket, "BLEED-PROTECT: winning opposite side is BE/trailing");
         return false;
        }
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
//    Manual / foreign trades never counted ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â protection & DD governor stay bot-only.
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

int CountOpenBotPositions()
  {
   int count = 0;
   CPositionInfo pos;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(!pos.SelectByIndex(i))
         continue;
      if(pos.Symbol() != _Symbol || pos.Magic() != (ulong)EXPERT_MAGIC)
         continue;
      count++;
     }
   return count;
  }

int CountBotPendings()
  {
   int count = 0;
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      const ulong ticket = OrderGetTicket(i);
      if(ticket == 0)
         continue;
      if(OrderGetString(ORDER_SYMBOL) != _Symbol)
         continue;
      if((ulong)OrderGetInteger(ORDER_MAGIC) != (ulong)EXPERT_MAGIC)
         continue;
      count++;
     }
   return count;
  }

bool LiveSafeAllowsNewPending(const int levelIndex)
  {
   if(!Enable_GapFreeze_Hardening)
      return true;
   if(g_forceFlattenActive || IsKillSwitchActiveToday())
      return false;
   // Level index 0,1,2 → allow when Live_MaxPendingLevels is 3
   if(Live_MaxPendingLevels > 0 && levelIndex >= Live_MaxPendingLevels)
      return false;
   // Cap FILLED positions only — do NOT count pendings here (that blocked L2/L3)
   if(Live_MaxOpenBotPositions > 0 && CountOpenBotPositions() >= Live_MaxOpenBotPositions)
      return false;
   return true;
  }

void RetryForceFlattenUntilFlat()
  {
   if(!g_forceFlattenActive && !IsKillSwitchActiveToday())
      return;

   const datetime now = TimeCurrent();
   // Retry every second while market may be frozen/recovering
   if(g_lastFlattenRetryTime != 0 && (now - g_lastFlattenRetryTime) < 1)
      return;
   g_lastFlattenRetryTime = now;

   // Clear long "server pause" so flatten is not blocked by IsGridOpsAllowed side-effects
   if(g_serverTradePausedUntil > now)
     {
      g_serverTradePausedUntil = 0;
      g_lastServerPauseReason = "";
     }

   EnsureAllBotPendingDeletedForced();
   if(HasOpenBotPositions())
      CloseAllBotPositionsForced("ForceFlattenRetry");
   EnsureAllBotPendingDeletedForced();

   if(!HasOpenBotPositions() && CountBotPendings() == 0)
     {
      if(g_forceFlattenActive)
        {
         g_forceFlattenActive = false;
         Print("TGM [R440]: Force-flatten complete — bot flat.");
        }
     }
   else
     {
      LogProtectionAlert(StringFormat("Force-flatten retry — open=%d pending=%d (freeze/gap recovery)",
                                      CountOpenBotPositions(), CountBotPendings()));
     }
  }

void MonitorLiveGapFreezeGuards()
  {
   if(!Enable_GapFreeze_Hardening || !Enable_Account_Protection)
      return;
   if(IsKillSwitchActiveToday())
      return;

   const double pip = Phase17_GetPipSize();
   if(pip <= 0.0)
      return;

   // 1) Abnormal spread → cancel pendings (avoid filling into chaos)
   const double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   const double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(ask > 0.0 && bid > 0.0 && Live_MaxSpreadPips > 0.0)
     {
      const double spreadPips = (ask - bid) / pip;
      if(spreadPips >= Live_MaxSpreadPips && CountBotPendings() > 0)
        {
         EnsureAllBotPendingDeletedForced();
         LogProtectionAlert(StringFormat("GapGuard: spread %.1fpip >= %.1f — pendings cancelled",
                                         spreadPips, Live_MaxSpreadPips));
        }
     }

   // 2) Early pending cancel before kill switch (cascade fill prevention)
   const double ddPct = GetFloatingDrawdownPercent();
   if(PendingCancel_DD_Percent > 0.0 && ddPct >= PendingCancel_DD_Percent && CountBotPendings() > 0)
     {
      EnsureAllBotPendingDeletedForced();
      LogProtectionAlert(StringFormat("GapGuard: floating DD %.1f%% >= %.1f%% — ALL pendings cancelled",
                                      ddPct, PendingCancel_DD_Percent));
     }

   // 3) Per-position: loss beyond planned SL × multiple → force close + flatten flag
   if(MaxLossMultipleOfPlannedSL <= 1.0)
      return;

   CPositionInfo pos;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(!pos.SelectByIndex(i))
         continue;
      if(pos.Symbol() != _Symbol || pos.Magic() != (ulong)EXPERT_MAGIC)
         continue;
      if(!IsOurBotGridParent(pos.Ticket()))
         continue;

      const double entry = pos.PriceOpen();
      const double sl = pos.StopLoss();
      if(entry <= 0.0 || sl <= 0.0)
         continue;

      const double plannedSlDist = MathAbs(entry - sl);
      if(plannedSlDist <= 0.0)
         continue;

      const double cur = (pos.PositionType() == POSITION_TYPE_BUY) ? bid : ask;
      if(cur <= 0.0)
         continue;

      double adverse = 0.0;
      if(pos.PositionType() == POSITION_TYPE_BUY)
         adverse = entry - cur;
      else
         adverse = cur - entry;

      if(adverse < plannedSlDist * MaxLossMultipleOfPlannedSL)
         continue;

      const ulong ticket = pos.Ticket();
      PrintFormat("TGM [R440 GapGuard]: #%I64u adverse=%.3f > SL*%.2f (%.3f) — EmergencyClose",
                  ticket, adverse, MaxLossMultipleOfPlannedSL, plannedSlDist * MaxLossMultipleOfPlannedSL);
      g_forceFlattenActive = true;
      EnsureAllBotPendingDeletedForced();
      if(!ExecuteTradeOp("GapGuardClose", g_trade.PositionClose(ticket),
                         StringFormat("ticket=%I64u reason=SL_MULTIPLE_BREACH", ticket)))
        {
         // freeze — keep retrying via force flatten
        }
     }
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
      g_accountProtectionReason = StringFormat("Bot floating DD %.1f%% >= limit %.1f%% - same-H4 NEW arm blocked (R444 keeps existing pendings)",
                                               ddPct, Max_Floating_DD_Percent);
      LogProtectionAlert(g_accountProtectionReason);
      // R444: do NOT wipe armed pendings on floating DD — only Emergency/Kill flatten may.
     }
   else
     {
      g_accountProtectionActive = false;
      g_accountProtectionReason = "";
     }
  }

bool IsGridPlacementAllowed(const bool freshH4Cycle = false)
  {
   if(IsKillSwitchActiveToday())
      return false;

   if(!IsGridOpsAllowed())
      return false;

   // Fresh H4 bar: equity 9% + 6 pendings ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â manual trades never block; skip DD/daily gates.
   if(freshH4Cycle)
      return Phase17_AllowFreshH4GridPlacement("H4FreshGrid");

   // Same-H4 refill: bot-only DD pause, daily lock, range filter.
   if(!Phase17_AllowNewExposureSimple("GridPlacement"))
      return false;

   // Bot-only floating loss vs balance ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â manual open P/L invisible.
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
   // R441: NO full-day ban — lock current H4 only; next H4 trades normally
   SetEmergencyLockThisH4(reason);
  }

bool IsKillSwitchActiveToday()
  {
   // Legacy name kept for call sites — meaning is now "emergency lock this H4"
   return IsEmergencyLockThisH4();
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
   Print("TGM [KILL SWITCH LAYER 3]: ", reason, " - flatten bot now; lock THIS H4 only (next H4 OK).");
   g_forceFlattenActive = true;
   EnsureAllBotPendingDeletedForced();
   CloseAllBotPositionsForced("KillSwitch");
   EnsureAllBotPendingDeletedForced();
   SetEmergencyLockThisH4(reason);
   LogProtectionAlert("LAYER 3: " + reason + " | Flatten ON | H4 locked — next candle can trade.");
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
   // Mode B: shared Live ATR-14 H4 broker SL is the loss exit ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â do not overlay emergency SL.
   if(IsFixedSlReentryMode())
      return;
   // Mode A: still run while hedge engine is ON ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â only parents WITHOUT a live hedge
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

//--- Simplified per-tick engine (Mode B only).
//    Order: flatten retry -> kill switch -> gap guards -> DD flag -> ATR SL heal -> lifecycle.
void RunAccountProtectionEngine()
  {
   if(Enable_GapFreeze_Hardening)
      MonitorLiveGapFreezeGuards();

   // R440: NEVER stop flatten retries after kill switch — freeze/gap needs continuous close attempts
   if(g_forceFlattenActive || IsKillSwitchActiveToday())
     {
      RetryForceFlattenUntilFlat();
      if(IsKillSwitchActiveToday() && !HasOpenBotPositions() && CountBotPendings() == 0)
         return;
      if(IsKillSwitchActiveToday())
         return; // still flattening or flat — no new grid logic
     }

   MonitorLayer3HardKillSwitch();          // Layer 3: daily-loss / equity kill switch (last resort)
   if(IsKillSwitchActiveToday())
     {
      RetryForceFlattenUntilFlat();
      return;
     }

   MonitorAccountDrawdownProtection();      // Layer 1: flag high floating DD (blocks NEW grid only)

   // Mode B only: close leftover GM_HEDGE + restore fixed/ATR broker SL. No hedge engine.
   CloseStrayHedgesInFixedSlMode();
   CPositionInfo posB;
   for(int i = 0; i < PositionsTotal(); i++)
     {
      if(!posB.SelectByIndex(i))
         continue;
      if(posB.Symbol() != _Symbol || posB.Magic() != (ulong)EXPERT_MAGIC)
         continue;
      if(!IsOurBotGridParent(posB.Ticket()))
         continue;
      EnsureModeBFixedBrokerSL(posB.Ticket());
     }

   UniversalGoldTrailingEngine();
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
         SetHedgeTriggerReady(parentTicket, true); // recurrent: re-open after gap if still >= trigger
         if(reason == "HedgeLoss100")
            ScheduleHedgeRetry(parentTicket);
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
      LogProtectionAlert(StringFormat("Hedge BLOCKED ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ticket #%I64u is manual/foreign (magic gate).", parentTicket));
      return false;
     }
   if(IsBotHedgePosition(parentTicket, pos.Comment()))
      return false;
   if(!CanOpenHedgeForParent(parentTicket))
      return false;

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
   const double hedgeSLDist = GetEffectiveHedgeStopLossUSD();
   const string cmt    = BuildHedgeComment(parentTicket);
   const double bid    = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   const double ask    = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

   bool   ok    = false;
   double entry = 0.0;
   double sl    = 0.0;
   ENUM_ORDER_TYPE hedgeSide;
   const bool stickyNoSL = (hedgeSLDist <= 0.0); // Loss Cap Engine: no $1 death SL

   if(pos.PositionType() == POSITION_TYPE_BUY)
     {
      hedgeSide = ORDER_TYPE_SELL;
      entry     = bid;
      if(!stickyNoSL)
        {
         sl = NormalizeDouble(entry + hedgeSLDist, digits);
         const double minSL = NormalizeDouble(ask + stops, digits);
         if(sl < minSL)
            sl = minSL;
        }
      ok = g_trade.Sell(lots, _Symbol, entry, sl, 0.0, cmt);
     }
   else
     {
      hedgeSide = ORDER_TYPE_BUY;
      entry     = ask;
      if(!stickyNoSL)
        {
         sl = NormalizeDouble(entry - hedgeSLDist, digits);
         const double maxSL = NormalizeDouble(bid - stops, digits);
         if(sl > maxSL)
            sl = maxSL;
        }
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
      PrintFormat("TGM [LOSS-CAP]: opened %s sticky hedge #%I64u for parent #%I64u | lots=%.2f/%.2f | hedgeSL=%s.",
                  (hedgeSide == ORDER_TYPE_SELL) ? "SELL" : "BUY",
                  openedHedgeTicket, parentTicket, filledLots, parentLots,
                  stickyNoSL ? "NONE(sticky)" : DoubleToString(sl, digits));
      if(MathAbs(filledLots - lots) > SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP))
         LogProtectionAlert(StringFormat("HEDGE LOT MISMATCH parent #%I64u requested=%.2f filled=%.2f ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â will top-up.",
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

      ulong parentTicket = ResolveHedgeParentTicket(pos.Ticket(), pos.Comment());
      CPositionInfo parent;
      if(parentTicket == 0 || !parent.SelectByTicket(parentTicket))
         CloseHedgePosition(pos.Ticket(), "ParentClosed");
     }
  }

//--- Manage hedge SL: sticky mode (SL=0) skips death-SL restore; arms BE at +$1 (Mode B).
void ManageHedgeStopLoss(const ulong hedgeTicket)
  {
   CPositionInfo pos;
   if(!pos.SelectByTicket(hedgeTicket))
      return;

   const int    digits   = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   const double point    = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   const double stops    = GetSymbolStopsPrice();
   const double open     = pos.PriceOpen();
   const double bid      = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   const double ask      = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   const double buffer   = GetSymbolSpreadPrice();
   const double profitUSD = GetPositionProfitUSD(hedgeTicket);
   const double hedgeBE  = GetActiveHedgeBreakEvenUSD();
   const ENUM_POSITION_TYPE posType = pos.PositionType();
   const double hedgeSLDist = GetEffectiveHedgeStopLossUSD();

   // Already BE-armed: do not spam-modify with live spread; only repair if SL left BE zone.
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

   if(profitUSD >= hedgeBE || IsHedgeBreakEvenArmed(hedgeTicket))
     {
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
         room = ((bid - beSL) > stops);
      else
         room = ((beSL - ask) > stops);

      if(!room || IsTradeModifyCooldownActive())
         return;

      if(SafePositionModify(hedgeTicket, beSL, 0.0, "HedgeBE"))
        {
         MarkHedgeBreakEvenArmed(hedgeTicket);
         PrintFormat("TGM [HEDGE-BE]: Hedge #%I64u +$%.2f >= $%.2f -> SL to break-even %.*f.",
                     hedgeTicket, profitUSD, hedgeBE, digits, beSL);
        }
      return;
     }

   // Sticky mode (Mode B always / Mode A when SL=0): strip any death SL left on hedge.
   // Do not restore $1 SL. BE arming above still runs when profit hits +$2.
   if(hedgeSLDist <= 0.0)
     {
      const double curSticky = pos.StopLoss();
      if(curSticky != 0.0 && !IsHedgeBreakEvenArmed(hedgeTicket) && !IsTradeModifyCooldownActive())
        {
         // Remove death SL so chop cannot burn the hedge before BE.
         if(SafePositionModify(hedgeTicket, 0.0, 0.0, "HedgeStripDeathSL"))
            PrintFormat("TGM [HEDGE-STICKY]: Stripped death SL on hedge #%I64u (Mode B / sticky).", hedgeTicket);
        }
      return;
     }

   double wantSL;
   bool   room;
   if(pos.PositionType() == POSITION_TYPE_SELL)
     {
      wantSL = NormalizeDouble(open + hedgeSLDist, digits);
      room   = ((wantSL - ask) > stops);
     }
   else
     {
      wantSL = NormalizeDouble(open - hedgeSLDist, digits);
      room   = ((bid - wantSL) > stops);
     }

   const double curSL2 = pos.StopLoss();
   if(curSL2 != 0.0 && MathAbs(curSL2 - wantSL) <= point)
      return;
   if(!room || IsTradeModifyCooldownActive())
      return;

   if(SafePositionModify(hedgeTicket, wantSL, 0.0, "HedgeSLRestore"))
      PrintFormat("TGM [HEDGE-LOCK]: Restored hedge SL %.*f (-$%.2f) on #%I64u.",
                  digits, wantSL, hedgeSLDist, hedgeTicket);
  }

//--- Live hedge management (ATR parent SL untouched):
//    1) keep $1 SL until +InpHedgeBreakEvenUSD ($2) -> BE
//    2) entry-return is OFF by default (InpHedgeReturnArmUSD=0) so hedges can reach +$2 BE
//    3) if entry-return enabled, only after BE is armed (never cut hedge before $2 BE)
void ManageLiveHedge(const ulong hedgeTicket)
  {
   if(hedgeTicket == 0)
      return;

   ManageHedgeStopLoss(hedgeTicket);

   // Entry-return OFF: preserves your method (survive to +$2 BE instead of dying in chop).
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
         TryReleaseStickyHedge(parentTicket);

      const bool hedgeLive = HasHedge(parentTicket);

      if(hedgeLive && HasFullHedgeCoverage(parentTicket))
         ApplyParentHardLossCap(parentTicket);
      else
         EnsureParentHasBrokerSL(parentTicket);

      // Hedge closed: re-arm trigger latch for Mode A recurrent hedge.
      if(WasHedgeLive(parentTicket) && !hedgeLive)
        {
         const int lifeSec = GetHedgeLifeSeconds(parentTicket);
         const double lossNow = GetPositionLossUSD(parentTicket);
         ClearHedgeLive(parentTicket);
         ClearLinkedHedgeTicket(parentTicket);
         ClearHedgeRearmState(parentTicket);
         ApplyHedgeRecycleCooldown(parentTicket, lifeSec);
         SetHedgeTriggerReady(parentTicket, true);
         PrintFormat("TGM [HEDGE]: Hedge gone on parent #%I64u (lived %ds, loss $%.2f) - re-lock if still >= $%.2f.",
                     parentTicket, lifeSec, lossNow, GetActiveHedgeTriggerUSD());
        }

      if(HasHedge(parentTicket))
        {
         MarkHedgeLive(parentTicket);
         if(!HasFullHedgeCoverage(parentTicket) && CanOpenHedgeForParent(parentTicket))
           {
            PrintFormat("TGM [HEDGE]: Parent #%I64u under-hedged (covered=%.2f) - topping up 1:1.",
                        parentTicket, GetHedgedVolumeForParent(parentTicket));
            OpenHedgeForParent(parentTicket);
           }
         ApplyParentHardLossCap(parentTicket);
         continue;
        }

      if(GetPositionLossUSD(parentTicket) < GetActiveHedgeTriggerUSD())
         SetHedgeTriggerReady(parentTicket, true);

      if(IsProfitEngineArmed(parentTicket) && GetPositionProfitUSD(parentTicket) > 0.0)
         continue;

      if(!CanOpenHedgeForParent(parentTicket))
         continue;

      OpenHedgeForParent(parentTicket);
     }
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

   const double profitPips = GetPositionProfitPips(ticket);
   const ENUM_POSITION_TYPE posType = pos.PositionType();

   // R428: the shared ATR take-profit books the trade, so instead of closing at
   // +30 the position is walked forward in two stages - break-even first, then a
   // part-book with the stop locked in profit.
   if(RESEARCH_BE_MODE)
     {
      const double pip = Phase17_GetPipSize();
      if(pip <= 0.0)
         return;

      const int    digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
      const double entry  = NormalizeDouble(pos.PriceOpen(), digits);
      const double curSL  = pos.StopLoss();
      const double tol    = SymbolInfoDouble(_Symbol, SYMBOL_POINT) * 0.5;
      const bool   isBuy  = (posType == POSITION_TYPE_BUY);

      // Stage 2: book part of the lot and lock the stop well into profit.
      if(RESEARCH_PARTIAL_AT_PIPS > 0.0 && profitPips + 1e-9 >= RESEARCH_PARTIAL_AT_PIPS)
        {
         const string partKey = StringFormat("TGM_R428_PART_%I64u", ticket);

         // The book-out is flagged separately from the stop move, so a failed
         // stop modify cannot cause the lot to be booked a second time.
         if(RESEARCH_PARTIAL_PERCENT > 0.0 && !GlobalVariableCheck(partKey))
           {
            const double vmin = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
            const double part = NormalizeVolume(pos.Volume() * RESEARCH_PARTIAL_PERCENT / 100.0);
            if(part >= vmin && part < pos.Volume())
              {
               if(!ExecuteTradeOp("PositionClosePartial",
                                  g_trade.PositionClosePartial(ticket, part),
                                  StringFormat("ticket=%I64u reason=R428_Book%.0f", ticket, RESEARCH_PARTIAL_PERCENT)))
                  return;
               GlobalVariableSet(partKey, 1.0);
               PrintFormat("TGM [R428]: %s #%I64u +%.1fpip -> booked %.2f of %.2f lot.",
                           (isBuy ? "BUY" : "SELL"), ticket, profitPips, part, pos.Volume());
              }
            else
              {
               // Volume cannot be split at the broker minimum; lock only.
               GlobalVariableSet(partKey, 1.0);
              }
           }

         if(RESEARCH_LOCK_SL_PIPS > 0.0)
           {
            const double lockSL = NormalizeDouble(isBuy ? entry + (RESEARCH_LOCK_SL_PIPS * pip)
                                                        : entry - (RESEARCH_LOCK_SL_PIPS * pip), digits);
            const bool already = (curSL > 0.0 && (isBuy ? (curSL >= lockSL - tol) : (curSL <= lockSL + tol)));
            if(!already && ExecuteTradeOp("PositionModify",
                                          g_trade.PositionModify(ticket, lockSL, pos.TakeProfit()),
                                          StringFormat("ticket=%I64u reason=R428_Lock%.0f", ticket, RESEARCH_LOCK_SL_PIPS)))
              {
               PrintFormat("TGM [R428]: %s #%I64u +%.1fpip -> SL locked at +%.0fpip (%.5f).",
                           (isBuy ? "BUY" : "SELL"), ticket, profitPips, RESEARCH_LOCK_SL_PIPS, lockSL);
              }
           }
         return;
        }

      // Stage 1: break-even.
      if(RESEARCH_BE_PIPS <= 0.0 || profitPips + 1e-9 < RESEARCH_BE_PIPS)
         return;

      // Only ever tighten: if the stop already sits at or beyond entry, stop.
      if(curSL > 0.0 && (isBuy ? (curSL >= entry - tol) : (curSL <= entry + tol)))
         return;

      if(ExecuteTradeOp("PositionModify",
                        g_trade.PositionModify(ticket, entry, pos.TakeProfit()),
                        StringFormat("ticket=%I64u reason=R428_BE%.0f", ticket, RESEARCH_BE_PIPS)))
        {
         PrintFormat("TGM [R428]: %s #%I64u +%.1fpip -> SL moved to break-even %.5f.",
                     (isBuy ? "BUY" : "SELL"), ticket, profitPips, entry);
        }
      return;
     }

   // Invert / directional methods use fixed broker TP ladder (100/60/40).
   // Do NOT force +30 FULL close — that killed L1/L2 targets before TP.
   if(RESEARCH_INVERT_SIDES)
      return;

   // Classic Research path only: +30 pips -> FULL close (no float runner).
   if(profitPips + 1e-9 >= TGM_FULL_CLOSE_TRIGGER_PIPS)
     {
      LogPhase28A("+30PIP_FULL_CLOSE", ticket,
                  StringFormat("pips=%.2f vol=%.2f TP=%.5f SL=%.5f",
                               profitPips, pos.Volume(), pos.TakeProfit(), pos.StopLoss()));
      if(ExecuteTradeOp("PositionClose",
                        g_trade.PositionClose(ticket),
                        StringFormat("ticket=%I64u reason=R422_FullBook30", ticket)))
        {
         PrintFormat("TGM [R422]: %s #%I64u +%.1fpip -> FULL booked.",
                     (posType == POSITION_TYPE_BUY) ? "BUY" : "SELL", ticket, profitPips);
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
      if(!isPart && !isPeak && !isHedge && !isBePending && !isHedgePeak && !isArmed && !isRunner &&
         !isHedgeRearm && !isHedgeLive && !isHedgeTrigReady && !isHedgeBE && !isHedgeRet && !isGridState && !isGridTicket)
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
   CreateUILabel("LblTrail", "Method / Engine", labelColor, 9, "Arial");

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
   string riskStr  = (g_effectiveRiskMode == RISK_AUTO_3_PERCENT_EQUITY)
                     ? StringFormat("Auto %.0f%% Equity", TGM_RISK_PER_TRADE_FRACTION * 100.0)
                     : "Manual Lot";
   string trailStatus = "OFF";
   if(EnableUnifiedMethodRouter && g_unifiedRouter.HasLock())
     {
      const STgmRouterDecision rd = g_lastRouterDecision;
      if(rd.status == TGM_ROUTER_ACTIVE)
         trailStatus = (rd.methodLabel != "" ? rd.methodLabel : rd.marketModeLabel);
      else if(rd.status == TGM_ROUTER_NO_TRADE_GAP)
         trailStatus = StringFormat("GAP %.0f-%.0f", SmallRangePips, LargeRangePips);
      else if(rd.status == TGM_ROUTER_WAIT_WEAK_PULLBACK)
         trailStatus = "WEAK PULLBACK";
      else
         trailStatus = rd.trendState;
     }
   else if(Enable_BreakEven || Enable_PartialClose)
      trailStatus = StringFormat("+%.0f %.0f%%+BE", TGM_PARTIAL_BE_TRIGGER_PIPS, TGM_PARTIAL_CLOSE_AT_30_PCT);
   else if((EnableUnifiedMethodRouter || RESEARCH_DIRECTIONAL_AUTO) && RESEARCH_INVERT_SIDES)
      trailStatus = "DIR FILTER";
   else
      trailStatus = StringFormat("+%.0f FULL", TGM_FULL_CLOSE_TRIGGER_PIPS);
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

   GmP11B_UpdatePanel(g_uiX, g_uiY);

   if(g_isDragging) RenderDashboardLayout();
  }

string GetDashboardMarketStatus()
  {
   if(g_emergencyKillSwitchActive || IsKillSwitchActiveToday())
      return "H4 LOCK";

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
   if(status == "H4 LOCK" || status == "KILL SWITCH")
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

