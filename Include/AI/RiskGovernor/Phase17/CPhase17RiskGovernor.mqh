//+------------------------------------------------------------------+
//|                   CPhase17RiskGovernor.mqh                       |
//|  Phase 18 consolidation of Phase17/17B proven protection filters |
//|  Filters ONLY. Does not change H4 level geometry or OrderSend path|
//|  beyond denying NEW exposure when a higher-priority gate fires.  |
//|  E1/E2 experimental changes are NOT merged.                      |
//+------------------------------------------------------------------+
#ifndef GM_CPHASE17_RISK_GOVERNOR_MQH
#define GM_CPHASE17_RISK_GOVERNOR_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

//--- PHASE 18 permanent protections (not optimization parameters)
input group "--- PHASE 18 Protection Consolidation ---"
input bool   PHASE18_ENABLE_DD_GOVERNOR         = true;   // Hard account DD governor for NEW exposure
input double PHASE18_DD_FREEZE_PERCENT          = 30.0;   // >= freeze: block new exposure + cancel pendings
input double PHASE18_DD_HARD_LIMIT_PERCENT      = 35.0;   // Hard safety ceiling (HALT tier)
input double PHASE18_DD_RISK_REDUCTION_PERCENT  = 25.0;   // Risk-reduction tier (re-arm block)
input bool   PHASE18_ENABLE_DAILY_PROFIT_LOCK   = true;   // Lock NEW exposure after realized daily target
input double PHASE18_DAILY_PROFIT_LOCK_PERCENT  = 5.0;    // % of day-start capital (realized only)
input bool   PHASE18_ENABLE_H4_RANGE_FILTER     = true;   // Reject H4 cycle if closed range too wide
input double PHASE18_MAX_H4_RANGE_PIPS          = 250.0;  // Max closed-H4 range (LOCKED 250 — Phase34 rejected 400)
input int    PHASE18_MAX_LEVEL_ACTIVATIONS_H4   = 1;      // 1 = no re-arm (Phase30: max=2 re-arm REJECTED vs control)

enum ENUM_P17_DD_LEVEL
  {
   P17_DD_NORMAL = 0,
   P17_DD_RISK_REDUCTION = 1,
   P17_DD_DEFENSIVE = 2,
   P17_DD_HALT = 3
  };

double   g_p17_peakEquity           = 0.0;
double   g_p17_equityDdPercent      = 0.0;
ENUM_P17_DD_LEVEL g_p17_ddLevel     = P17_DD_NORMAL;
bool     g_p17_ddTradingHalted      = false;

datetime g_p17_dayKey               = 0;
double   g_p17_dayStartCapital      = 0.0;
double   g_p17_dailyProfit          = 0.0;
double   g_p17_dailyTarget          = 0.0;
bool     g_p17_dailyProfitLocked    = false;
datetime g_p17_dailyLockTime        = 0;

datetime g_p17_h4BarOpenLogged      = 0;
bool     g_p17_h4RangeRejected      = false;
double   g_p17_h4High               = 0.0;
double   g_p17_h4Low                = 0.0;
double   g_p17_h4Close              = 0.0;
double   g_p17_h4RangePrice         = 0.0;
double   g_p17_h4RangePoints        = 0.0;
double   g_p17_h4RangePips          = 0.0;
double   g_p17_pipSize              = 0.0;
datetime g_p17_h4CandleOpenTime     = 0;
datetime g_p17_h4CandleCloseTime    = 0;

string   g_p17_lastRejectReason     = "";

int g_p17_cnt_h4_cycles             = 0;
int g_p17_cnt_h4_rejected           = 0;
int g_p17_cnt_h4_accepted           = 0;
int g_p17_cnt_daily_locks           = 0;
int g_p17_cnt_dd_defensive          = 0;
int g_p17_cnt_dd_hard_halts         = 0;
int g_p17_cnt_block_daily           = 0;
int g_p17_cnt_block_h4_range        = 0;
int g_p17_cnt_block_dd              = 0;

bool g_p17_logged_defensive         = false;
bool g_p17_logged_halt              = false;
datetime g_p17_lastBlockLogTime     = 0;
datetime g_p17_lastDailyProfitScan  = 0;
datetime g_p17_lastFullUpdate       = 0;
bool     g_p17_pendingCancelRequest = false; // set on rising-edge Defensive/Halt — EA cancels pendings
int      g_p17_cnt_pending_cancels  = 0;
int      g_p17_cnt_block_rearm      = 0;

double Phase17_GetPipSize()
  {
   const double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   if(point <= 0.0)
      return 0.0;
   const int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   const double digitsMod = (digits == 3 || digits == 5) ? 10.0 : 1.0;
   // Product convention: $3 SL = 30 pip → 1 pip = 0.10 price on typical XAU
   // = Point × digitsMod × 10
   return point * digitsMod * 10.0;
  }

double Phase17_PriceToPoints(const double priceMove)
  {
   const double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   if(point <= 0.0) return 0.0;
   return priceMove / point;
  }

datetime Phase17_DayFloor(const datetime t)
  {
   MqlDateTime dt;
   TimeToStruct(t, dt);
   dt.hour = 0; dt.min = 0; dt.sec = 0;
   return StructToTime(dt);
  }

double Phase17_GetRealizedDailyProfit()
  {
   const datetime dayStart = Phase17_DayFloor(TimeCurrent());
   const datetime dayEnd   = dayStart + 86400;

   if(!HistorySelect(dayStart, dayEnd))
      return 0.0;

   double net = 0.0;
   const int total = HistoryDealsTotal();
   for(int i = 0; i < total; i++)
     {
      const ulong ticket = HistoryDealGetTicket(i);
      if(ticket == 0) continue;
      if(HistoryDealGetString(ticket, DEAL_SYMBOL) != _Symbol) continue;
      if((long)HistoryDealGetInteger(ticket, DEAL_MAGIC) != (long)EXPERT_MAGIC) continue;

      const long entry = HistoryDealGetInteger(ticket, DEAL_ENTRY);
      if(entry != DEAL_ENTRY_OUT && entry != DEAL_ENTRY_OUT_BY && entry != DEAL_ENTRY_INOUT)
         continue;

      net += HistoryDealGetDouble(ticket, DEAL_PROFIT)
           + HistoryDealGetDouble(ticket, DEAL_SWAP)
           + HistoryDealGetDouble(ticket, DEAL_COMMISSION);
     }
   return net;
  }

void Phase17_EnsureDayStart()
  {
   const datetime dayFloor = Phase17_DayFloor(TimeCurrent());
   if(g_p17_dayKey == dayFloor && g_p17_dayStartCapital > 0.0)
      return;

   g_p17_dayKey = dayFloor;
   g_p17_dayStartCapital = AccountInfoDouble(ACCOUNT_EQUITY);
   if(g_p17_dayStartCapital <= 0.0)
      g_p17_dayStartCapital = AccountInfoDouble(ACCOUNT_BALANCE);
   g_p17_dailyTarget = g_p17_dayStartCapital * PHASE18_DAILY_PROFIT_LOCK_PERCENT / 100.0;
   g_p17_dailyProfit = 0.0;
   g_p17_dailyProfitLocked = false;
   g_p17_dailyLockTime = 0;
   g_p17_lastDailyProfitScan = 0;

   PrintFormat("TGM [P18]: DAY_START_CAPITAL=%.2f DAILY_TARGET=%.2f (%.2f%%) date=%s",
               g_p17_dayStartCapital, g_p17_dailyTarget, PHASE18_DAILY_PROFIT_LOCK_PERCENT,
               TimeToString(dayFloor, TIME_DATE));
  }

void Phase17_UpdateDailyProfitLock()
  {
   Phase17_EnsureDayStart();

   if(!PHASE18_ENABLE_DAILY_PROFIT_LOCK)
     {
      g_p17_dailyProfitLocked = false;
      return;
     }

   // Throttle history scan — once locked, no need to rescan until next day.
   if(g_p17_dailyProfitLocked)
      return;

   const datetime now = TimeCurrent();
   if(g_p17_lastDailyProfitScan != 0 && (now - g_p17_lastDailyProfitScan) < 1)
      return;
   g_p17_lastDailyProfitScan = now;

   g_p17_dailyProfit = Phase17_GetRealizedDailyProfit();

   if(!g_p17_dailyProfitLocked && g_p17_dailyProfit >= g_p17_dailyTarget && g_p17_dailyTarget > 0.0)
     {
      g_p17_dailyProfitLocked = true;
      g_p17_dailyLockTime = TimeCurrent();
      g_p17_cnt_daily_locks++;
      PrintFormat("TGM [P18]: DAILY_PROFIT_LOCKED | DAY_START_CAPITAL=%.2f DAILY_PROFIT=%.2f DAILY_TARGET=%.2f time=%s",
                  g_p17_dayStartCapital, g_p17_dailyProfit, g_p17_dailyTarget,
                  TimeToString(g_p17_dailyLockTime, TIME_DATE|TIME_SECONDS));
     }
  }

string Phase17_DdLevelToString()
  {
   switch(g_p17_ddLevel)
     {
      case P17_DD_RISK_REDUCTION: return "RISK_REDUCTION";
      case P17_DD_DEFENSIVE:      return "DEFENSIVE";
      case P17_DD_HALT:           return "HALT";
      default:                    return "NORMAL";
     }
  }

void Phase17_UpdateDrawdownGovernor()
  {
   const double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   if(equity > g_p17_peakEquity)
      g_p17_peakEquity = equity;
   if(g_p17_peakEquity <= 0.0)
      g_p17_peakEquity = equity;

   if(g_p17_peakEquity > 0.0 && equity < g_p17_peakEquity)
      g_p17_equityDdPercent = (g_p17_peakEquity - equity) / g_p17_peakEquity * 100.0;
   else
      g_p17_equityDdPercent = 0.0;

   if(!PHASE18_ENABLE_DD_GOVERNOR)
     {
      g_p17_ddLevel = P17_DD_NORMAL;
      g_p17_ddTradingHalted = false;
      return;
     }

   const ENUM_P17_DD_LEVEL prev = g_p17_ddLevel;
   if(g_p17_equityDdPercent >= PHASE18_DD_HARD_LIMIT_PERCENT)
      g_p17_ddLevel = P17_DD_HALT;
   else if(g_p17_equityDdPercent >= PHASE18_DD_FREEZE_PERCENT)
      g_p17_ddLevel = P17_DD_DEFENSIVE;
   else if(g_p17_equityDdPercent >= PHASE18_DD_RISK_REDUCTION_PERCENT)
      g_p17_ddLevel = P17_DD_RISK_REDUCTION;
   else
      g_p17_ddLevel = P17_DD_NORMAL;

   // Phase 17B Cycle-1: freeze NEW exposure at Defensive (30%), not only at 35% Halt.
   // Gives open-book headroom under the hard 35% ceiling. Does NOT force-close positions.
   g_p17_ddTradingHalted = (g_p17_ddLevel >= P17_DD_DEFENSIVE);

   // Rising-edge into Defensive or Halt → request pending cancel (EA executes; no position close).
   if(g_p17_ddTradingHalted && prev < P17_DD_DEFENSIVE)
     {
      g_p17_pendingCancelRequest = true;
      g_p17_cnt_pending_cancels++;
      PrintFormat("TGM [P17B]: NEW_EXPOSURE_FREEZE + PENDING_CANCEL requested | EQUITY_DD=%.2f LEVEL=%s (opens not force-closed)",
                  g_p17_equityDdPercent, Phase17_DdLevelToString());
     }

   if(g_p17_ddLevel == P17_DD_DEFENSIVE && prev != P17_DD_DEFENSIVE && !g_p17_logged_defensive)
     {
      g_p17_cnt_dd_defensive++;
      g_p17_logged_defensive = true;
      PrintFormat("TGM [P18]: DD_RISK_LEVEL=DEFENSIVE EQUITY_DD_PERCENT=%.2f peak=%.2f equity=%.2f",
                  g_p17_equityDdPercent, g_p17_peakEquity, equity);
     }
   if(g_p17_ddLevel == P17_DD_HALT && prev != P17_DD_HALT)
     {
      g_p17_cnt_dd_hard_halts++;
      g_p17_logged_halt = true;
      PrintFormat("TGM [P18]: DD_TRADING_HALTED=true EQUITY_DD_PERCENT=%.2f >= %.2f | no new exposure (no force-close)",
                  g_p17_equityDdPercent, PHASE18_DD_HARD_LIMIT_PERCENT);
     }
   if(g_p17_ddLevel < P17_DD_DEFENSIVE)
      g_p17_logged_defensive = false;
  }

bool Phase17_ConsumePendingCancelRequest()
  {
   if(!g_p17_pendingCancelRequest)
      return false;
   g_p17_pendingCancelRequest = false;
   return true;
  }

// Risk Reduction (25%): block re-arm only (activation>=1). First fill still allowed until Defensive.
bool Phase17_AllowReArm(const int activationCountThisH4)
  {
   if(!PHASE18_ENABLE_DD_GOVERNOR)
      return true;
   if(g_p17_ddLevel >= P17_DD_DEFENSIVE)
     {
      g_p17_cnt_block_rearm++;
      return false;
     }
   if(g_p17_ddLevel >= P17_DD_RISK_REDUCTION && activationCountThisH4 >= 1)
     {
      g_p17_cnt_block_rearm++;
      return false;
     }
   return true;
  }

bool Phase17_EvaluateH4RangeFilter()
  {
   g_p17_pipSize = Phase17_GetPipSize();
   g_p17_h4High  = iHigh(_Symbol, PERIOD_H4, 1);
   g_p17_h4Low   = iLow(_Symbol, PERIOD_H4, 1);
   g_p17_h4Close = iClose(_Symbol, PERIOD_H4, 1);
   g_p17_h4CandleOpenTime  = iTime(_Symbol, PERIOD_H4, 1);
   g_p17_h4CandleCloseTime = g_p17_h4CandleOpenTime + PeriodSeconds(PERIOD_H4);

   if(g_p17_h4High <= 0.0 || g_p17_h4Low <= 0.0 || g_p17_h4High <= g_p17_h4Low || g_p17_pipSize <= 0.0)
     {
      g_p17_h4RangeRejected = true;
      return false;
     }

   g_p17_h4RangePrice  = g_p17_h4High - g_p17_h4Low;
   g_p17_h4RangePoints = Phase17_PriceToPoints(g_p17_h4RangePrice);
   g_p17_h4RangePips   = g_p17_h4RangePrice / g_p17_pipSize;

   const bool reject = (PHASE18_ENABLE_H4_RANGE_FILTER && g_p17_h4RangePips > PHASE18_MAX_H4_RANGE_PIPS);
   g_p17_h4RangeRejected = reject;

   if(g_p17_h4BarOpenLogged != g_p17_h4CandleOpenTime)
     {
      g_p17_h4BarOpenLogged = g_p17_h4CandleOpenTime;
      g_p17_cnt_h4_cycles++;
      if(reject)
         g_p17_cnt_h4_rejected++;
      else
         g_p17_cnt_h4_accepted++;

      PrintFormat("TGM [P18]: H4_CANDLE_OPEN_TIME=%s H4_CANDLE_CLOSE_TIME=%s",
                  TimeToString(g_p17_h4CandleOpenTime, TIME_DATE|TIME_MINUTES),
                  TimeToString(g_p17_h4CandleCloseTime, TIME_DATE|TIME_MINUTES));
      PrintFormat("TGM [P18]: H4_HIGH=%.5f H4_LOW=%.5f H4_CLOSE=%.5f H4_RANGE_PRICE=%.5f H4_RANGE_POINTS=%.1f H4_RANGE_PIPS=%.1f",
                  g_p17_h4High, g_p17_h4Low, g_p17_h4Close,
                  g_p17_h4RangePrice, g_p17_h4RangePoints, g_p17_h4RangePips);
      PrintFormat("TGM [P18]: PIP_SIZE=%.5f DIGITS=%d POINT=%.5f TICK_SIZE=%.5f H4_RANGE_REJECTED=%s (max=%.1f)",
                  g_p17_pipSize,
                  (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS),
                  SymbolInfoDouble(_Symbol, SYMBOL_POINT),
                  SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE),
                  (reject ? "true" : "false"),
                  PHASE18_MAX_H4_RANGE_PIPS);
     }

   return !reject;
  }

void Phase17_OnTickUpdate()
  {
   const datetime now = TimeCurrent();
   // Same-second reentry (OnTick + placement gate) reuses cached governor state.
   if(g_p17_lastFullUpdate == now && g_p17_lastFullUpdate != 0)
      return;
   g_p17_lastFullUpdate = now;

   Phase17_UpdateDrawdownGovernor();
   Phase17_UpdateDailyProfitLock();
   Phase17_EvaluateH4RangeFilter();
  }

void Phase17_OnInit()
  {
   g_p17_peakEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   Phase17_EnsureDayStart();
   Phase17_EvaluateH4RangeFilter();
   PrintFormat("TGM [P18]: RiskGovernor ON | DD_freeze=%.1f%% DD_hard=%.1f%% DailyLock=%s(%.1f%%) H4RangeFilter=%s(max=%.1f pips) MaxActPerLevelH4=%d PIP_SIZE=%.5f",
               PHASE18_DD_FREEZE_PERCENT, PHASE18_DD_HARD_LIMIT_PERCENT,
               (PHASE18_ENABLE_DAILY_PROFIT_LOCK ? "ON" : "OFF"), PHASE18_DAILY_PROFIT_LOCK_PERCENT,
               (PHASE18_ENABLE_H4_RANGE_FILTER ? "ON" : "OFF"), PHASE18_MAX_H4_RANGE_PIPS,
               PHASE18_MAX_LEVEL_ACTIVATIONS_H4,
               Phase17_GetPipSize());
  }

bool Phase17_AllowNewExposure(const string context, string &rejectReason)
  {
   rejectReason = "";
   Phase17_OnTickUpdate();

   if(PHASE18_ENABLE_DD_GOVERNOR && g_p17_ddTradingHalted)
     {
      rejectReason = StringFormat("DD_NEW_EXPOSURE_FROZEN LEVEL=%s EQUITY_DD_PERCENT=%.2f (freeze>=%.1f hard_ceil=%.1f)",
                                  Phase17_DdLevelToString(), g_p17_equityDdPercent,
                                  PHASE18_DD_FREEZE_PERCENT, PHASE18_DD_HARD_LIMIT_PERCENT);
      if(g_p17_lastRejectReason != rejectReason)
         g_p17_cnt_block_dd++;
      g_p17_lastRejectReason = rejectReason;
      return false;
     }

   if(PHASE18_ENABLE_DAILY_PROFIT_LOCK && g_p17_dailyProfitLocked)
     {
      rejectReason = StringFormat("DAILY_PROFIT_LOCKED profit=%.2f target=%.2f",
                                  g_p17_dailyProfit, g_p17_dailyTarget);
      if(g_p17_lastRejectReason != rejectReason)
         g_p17_cnt_block_daily++;
      g_p17_lastRejectReason = rejectReason;
      return false;
     }

   if(PHASE18_ENABLE_H4_RANGE_FILTER && g_p17_h4RangeRejected)
     {
      rejectReason = StringFormat("H4_RANGE_REJECTED pips=%.1f>%.1f",
                                  g_p17_h4RangePips, PHASE18_MAX_H4_RANGE_PIPS);
      if(g_p17_lastRejectReason != rejectReason)
         g_p17_cnt_block_h4_range++;
      g_p17_lastRejectReason = rejectReason;
      return false;
     }

   g_p17_lastRejectReason = "";
   return true;
  }

bool Phase17_AllowNewExposureSimple(const string context)
  {
   string reason = "";
   const bool ok = Phase17_AllowNewExposure(context, reason);
   if(!ok)
     {
      const datetime now = TimeCurrent();
      if((now - g_p17_lastBlockLogTime) >= 60)
        {
         g_p17_lastBlockLogTime = now;
         PrintFormat("TGM [P18]: %s blocked — %s", context, reason);
        }
     }
   return ok;
  }

void Phase17_LogSummary()
  {
   PrintFormat("TGM [P17 SUMMARY]: H4_cycles=%d rejected=%d accepted=%d | daily_locks=%d | dd_defensive=%d dd_halts=%d pending_cancels=%d",
               g_p17_cnt_h4_cycles, g_p17_cnt_h4_rejected, g_p17_cnt_h4_accepted,
               g_p17_cnt_daily_locks, g_p17_cnt_dd_defensive, g_p17_cnt_dd_hard_halts, g_p17_cnt_pending_cancels);
   PrintFormat("TGM [P17 SUMMARY]: blocked_by_daily=%d blocked_by_h4=%d blocked_by_dd=%d blocked_rearm=%d | EQUITY_DD=%.2f LEVEL=%s",
               g_p17_cnt_block_daily, g_p17_cnt_block_h4_range, g_p17_cnt_block_dd, g_p17_cnt_block_rearm,
               g_p17_equityDdPercent, Phase17_DdLevelToString());
  }

#endif
