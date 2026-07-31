//+------------------------------------------------------------------+
//|                   CPhase11BExecutionAuthority.mqh              |
//|     Intelligent Execution Supervisor — PRE-ACTIVATION ONLY       |
//|     Trading Engine formulas untouched; lot/freeze/cancel only      |
//+------------------------------------------------------------------+
#ifndef GM_CPHASE11B_EXECUTION_AUTHORITY_MQH
#define GM_CPHASE11B_EXECUTION_AUTHORITY_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include <Trade\Trade.mqh>
#include "Phase11BConstants.mqh"
#include "SGmPreActivationSnapshot.mqh"

struct SGmP11BFrozenPending
  {
   ulong    original_ticket;
   string   comment;
   int      level_index;
   ENUM_ORDER_TYPE order_type;
   double   price;
   double   sl;
   double   tp;
   double   lots;
   double   sl_dist_lots;
   datetime frozen_at;
   double   confidence_at_freeze;
   string   why;
   bool     active;
  };

class CPhase11BExecutionAuthority
  {
private:
   CTrade              m_trade;
   ulong               m_magic;
   double              m_max_lot_cap;
   int                 m_atr_handle;
   bool                m_enabled;
   bool                m_supervisor_active;
   datetime            m_last_ok_analysis;
   datetime            m_last_tick_run;
   ulong               m_last_tick_ms;

   double              m_max_lot_increase_pct;
   double              m_max_lot_reduce_pct;
   int                 m_max_freeze_min;
   bool                m_emergency_cancel;
   bool                m_news_protection;
   bool                m_broker_protection;
   bool                m_weekend_protection;
   double              m_min_lot;

   SGmPreActivationSnapshot m_global;
   SGmP11BFrozenPending m_frozen[GM_P11B_MAX_FROZEN];
   int                 m_frozen_count;
   int                 m_cancelled_session;
   int                 m_frozen_session;
   double              m_last_spread_pts;
   double              m_last_atr;
   int                 m_broker_fail_streak;
   datetime            m_panel_init;

   double              m_tick_buf[8];
   int                 m_tick_idx;

   bool                IsFinite(const double v) const { return (v == v && v != DBL_MAX && v != -DBL_MAX); }

   double ReadAtr(void)
     {
      if(m_atr_handle == INVALID_HANDLE)
         return 0.0;
      double buf[];
      ArraySetAsSeries(buf, true);
      if(CopyBuffer(m_atr_handle, 0, 0, 3, buf) < 2)
         return 0.0;
      return buf[0];
     }

   double ReadAtrPrev(void)
     {
      if(m_atr_handle == INVALID_HANDLE)
         return 0.0;
      double buf[];
      ArraySetAsSeries(buf, true);
      if(CopyBuffer(m_atr_handle, 0, 1, 5, buf) < 4)
         return 0.0;
      double sum = 0.0;
      for(int i = 0; i < 4; i++) sum += buf[i];
      return sum / 4.0;
     }

   void DisableSupervisor(const string reason)
     {
      m_supervisor_active = false;
      m_global.health = GM_P11B_HEALTH_DISABLED;
      m_global.why = "FAILSAFE: AI disabled — " + reason + " | Trading Engine continues normally.";
      PrintFormat("TGM [P11B FAILSAFE]: %s", m_global.why);
     }

   void RecordBrokerOutcome(const bool ok)
     {
      if(ok)
         m_broker_fail_streak = 0;
      else
         m_broker_fail_streak++;
      if(m_broker_protection && m_broker_fail_streak >= 5)
         DisableSupervisor("broker execution quality degraded");
     }

   double ScoreSpread(const double spread_pts, const double atr)
     {
      if(atr <= 0.0) return 50.0;
      const double ratio = spread_pts * _Point / atr;
      return GmP11BClamp01(100.0 - ratio * 400.0);
     }

   double ScoreSession(void)
     {
      MqlDateTime dt;
      TimeToStruct(TimeCurrent(), dt);
      const int h = dt.hour;
      if(h >= 8 && h <= 11) return 85.0;
      if(h >= 13 && h <= 17) return 90.0;
      if(h >= 3 && h <= 6) return 70.0;
      return 55.0;
     }

   double ScoreNewsRisk(void)
     {
      if(m_weekend_protection)
        {
         MqlDateTime dt;
         TimeToStruct(TimeCurrent(), dt);
         if(dt.day_of_week == 0 || dt.day_of_week == 6)
            return 25.0;
        }
      if(m_news_protection)
        {
         const int secs = (int)(TimeCurrent() % 86400);
         if(secs < 3600 || secs > 82800)
            return 45.0;
        }
      return 75.0;
     }

   double ScoreTrend(void)
     {
      double close[];
      ArraySetAsSeries(close, true);
      if(CopyClose(_Symbol, PERIOD_H4, 0, 5, close) < 5)
         return 50.0;
      const double slope = close[0] - close[4];
      const double atr = ReadAtr();
      if(atr <= 0.0) return 50.0;
      return GmP11BClamp01(50.0 + (slope / atr) * 25.0);
     }

   double ScoreMomentum(void)
     {
      int rsiHandle = iRSI(_Symbol, PERIOD_H4, 14, PRICE_CLOSE);
      if(rsiHandle == INVALID_HANDLE)
         return 50.0;
      double buf[];
      ArraySetAsSeries(buf, true);
      if(CopyBuffer(rsiHandle, 0, 0, 1, buf) < 1)
        {
         IndicatorRelease(rsiHandle);
         return 50.0;
        }
      IndicatorRelease(rsiHandle);
      return GmP11BClamp01(MathAbs(buf[0] - 50.0) * 2.0);
     }

   double ScoreLiquidity(void)
     {
      long vol[];
      ArraySetAsSeries(vol, true);
      if(CopyTickVolume(_Symbol, PERIOD_H4, 0, 10, vol) < 10)
         return 50.0;
      long sum = 0;
      for(int i = 0; i < 10; i++) sum += vol[i];
      if(sum <= 0) return 40.0;
      return GmP11BClamp01(40.0 + (double)vol[0] / (double)(sum / 10) * 30.0);
     }

   double ScoreTickSpeed(void)
     {
      m_tick_buf[m_tick_idx % 8] = (double)GetTickCount();
      m_tick_idx++;
      if(m_tick_idx < 4) return 50.0;
      double dt = m_tick_buf[(m_tick_idx - 1) % 8] - m_tick_buf[(m_tick_idx - 4) % 8];
      if(dt <= 0.0) return 50.0;
      const double tps = 3000.0 / dt;
      return GmP11BClamp01(tps * 15.0);
     }

   double ScoreAcceleration(void)
     {
      double close[];
      ArraySetAsSeries(close, true);
      if(CopyClose(_Symbol, PERIOD_M5, 0, 4, close) < 4)
         return 50.0;
      const double a = (close[0] - close[1]) - (close[1] - close[2]);
      const double atr = ReadAtr();
      if(atr <= 0.0) return 50.0;
      return GmP11BClamp01(50.0 + (a / atr) * 40.0);
     }

   double ScoreStructure(void)
     {
      double high[], low[];
      ArraySetAsSeries(high, true);
      ArraySetAsSeries(low, true);
      if(CopyHigh(_Symbol, PERIOD_H4, 0, 3, high) < 3 || CopyLow(_Symbol, PERIOD_H4, 0, 3, low) < 3)
         return 50.0;
      const double range = high[0] - low[0];
      const double atr = ReadAtr();
      if(atr <= 0.0 || range <= 0.0) return 50.0;
      return GmP11BClamp01(100.0 - (range / atr) * 20.0);
     }

   double ScoreFalseBreakout(void)
     {
      double high[], low[], close[];
      ArraySetAsSeries(high, true);
      ArraySetAsSeries(low, true);
      ArraySetAsSeries(close, true);
      if(CopyHigh(_Symbol, PERIOD_H4, 0, 2, high) < 2 ||
         CopyLow(_Symbol, PERIOD_H4, 0, 2, low) < 2 ||
         CopyClose(_Symbol, PERIOD_H4, 0, 2, close) < 2)
         return 50.0;
      const double body = MathAbs(close[0] - close[1]);
      const double wick = (high[0] - low[0]) - body;
      if(body <= 0.0) return 60.0;
      return GmP11BClamp01(100.0 - (wick / body) * 25.0);
     }

   SGmPreActivationSnapshot AnalyzePending(const ulong ticket, const string comment, const int level_index)
     {
      SGmPreActivationSnapshot s;
      s.Reset();
      s.stamped_at = TimeCurrent();
      s.symbol = _Symbol;
      s.ticket = ticket;
      s.comment = comment;
      s.level_index = level_index;

      const double atr = ReadAtr();
      const double atr_prev = ReadAtrPrev();
      m_last_atr = atr;
      s.current_atr = atr;

      const double spread_pts = (SymbolInfoDouble(_Symbol, SYMBOL_ASK) - SymbolInfoDouble(_Symbol, SYMBOL_BID)) / _Point;
      m_last_spread_pts = spread_pts;
      s.current_spread_pts = spread_pts;

      if(!IsFinite(atr) || atr <= 0.0)
        {
         DisableSupervisor("invalid ATR");
         return s;
        }

      s.trend_strength = ScoreTrend();
      s.momentum = ScoreMomentum();
      s.liquidity = ScoreLiquidity();
      s.spread_score = ScoreSpread(spread_pts, atr);
      s.volatility = GmP11BClamp01((atr / _Point) / 500.0 * 100.0);
      s.atr_expansion = (atr_prev > 0.0) ? GmP11BClamp01((atr / atr_prev) * 50.0) : 50.0;
      s.atr_compression = GmP11BClamp01(100.0 - s.atr_expansion);
      s.tick_speed = ScoreTickSpeed();
      s.price_acceleration = ScoreAcceleration();
      s.broker_quality = GmP11BClamp01(100.0 - m_broker_fail_streak * 12.0);
      s.slippage_probability = GmP11BClamp01(100.0 - s.spread_score * 0.6 - s.volatility * 0.2);
      s.false_breakout_probability = ScoreFalseBreakout();
      s.session_strength = ScoreSession();
      s.news_risk = ScoreNewsRisk();
      s.market_structure = ScoreStructure();
      s.market_confidence = GmP11BClamp01((s.trend_strength + s.momentum + s.market_structure) / 3.0);

      s.execution_confidence = GmP11BClamp01(
         s.market_confidence * 0.18 +
         s.trend_strength * 0.12 +
         s.momentum * 0.08 +
         s.liquidity * 0.06 +
         s.spread_score * 0.10 +
         s.volatility * 0.05 +
         s.atr_expansion * 0.04 +
         s.tick_speed * 0.04 +
         s.price_acceleration * 0.05 +
         s.broker_quality * 0.10 +
         s.session_strength * 0.06 +
         s.news_risk * 0.06 +
         s.market_structure * 0.06 +
         (100.0 - s.false_breakout_probability) * 0.06
      );
      s.ai_confidence = s.execution_confidence;
      s.execution_score = s.execution_confidence;

      if(s.news_risk < 40.0) s.market_condition = "NEWS/WEEKEND RISK";
      else if(s.spread_score < 45.0) s.market_condition = "WIDE SPREAD";
      else if(s.volatility > 75.0) s.market_condition = "HIGH VOLATILITY";
      else if(s.trend_strength > 70.0) s.market_condition = "TRENDING";
      else s.market_condition = "BALANCED";

      s.band = GmP11BBandFromConfidence(s.execution_confidence);
      s.action = DecideAction(s);
      s.lot_multiplier = LotMultiplierForAction(s.action);
      s.recommendation = GmP11BActionName(s.action);
      BuildWhy(s);
      s.health = m_supervisor_active ? GM_P11B_HEALTH_OK : GM_P11B_HEALTH_DISABLED;
      s.frozen_count = m_frozen_session;
      s.cancelled_count = m_cancelled_session;
      s.valid = m_supervisor_active;
      return s;
     }

   ENUM_GM_P11B_ACTION DecideAction(const SGmPreActivationSnapshot &s)
     {
      switch(s.band)
        {
         case GM_P11B_BAND_EXTREMELY_STRONG: return GM_P11B_ACT_INCREASE_LOT;
         case GM_P11B_BAND_STRONG:           return GM_P11B_ACT_NORMAL;
         case GM_P11B_BAND_CAUTION:          return GM_P11B_ACT_REDUCE_LOT;
         case GM_P11B_BAND_HIGH_RISK:        return GM_P11B_ACT_FREEZE;
         case GM_P11B_BAND_EXTREME_RISK:     return m_emergency_cancel ? GM_P11B_ACT_CANCEL : GM_P11B_ACT_FREEZE;
        }
      return GM_P11B_ACT_NORMAL;
     }

   double LotMultiplierForAction(const ENUM_GM_P11B_ACTION act)
     {
      switch(act)
        {
         case GM_P11B_ACT_INCREASE_LOT:
            return 1.0 + m_max_lot_increase_pct / 100.0;
         case GM_P11B_ACT_REDUCE_LOT:
            return 1.0 - m_max_lot_reduce_pct / 100.0;
        }
      return 1.0;
     }

   void BuildWhy(SGmPreActivationSnapshot &s)
     {
      string why = StringFormat(
         "ExecConf=%.0f Band=%s Spread=%.0f Vol=%.0f Trend=%.0f News=%.0f Broker=%.0f | ",
         s.execution_confidence, GmP11BBandName(s.band),
         s.spread_score, s.volatility, s.trend_strength, s.news_risk, s.broker_quality);
      if(s.action == GM_P11B_ACT_INCREASE_LOT)
         why += "Strong conditions — lot +up to " + DoubleToString(m_max_lot_increase_pct, 0) + "% BEFORE activation.";
      else if(s.action == GM_P11B_ACT_REDUCE_LOT)
         why += "Caution — lot reduced up to " + DoubleToString(m_max_lot_reduce_pct, 0) + "% BEFORE activation.";
      else if(s.action == GM_P11B_ACT_FREEZE)
         why += "High risk — pending frozen (max " + IntegerToString(m_max_freeze_min) + " min). Engine math unchanged.";
      else if(s.action == GM_P11B_ACT_CANCEL)
         why += "Extreme risk — pending cancelled BEFORE activation. Active trades untouched.";
      else
         why += "Strong/normal — trade exactly as Engine calculated.";
      if(StringLen(why) > GM_P11B_WHY_MAX)
         why = StringSubstr(why, 0, GM_P11B_WHY_MAX);
      s.why = why;
     }

   int FindFrozenSlot(const string comment)
     {
      for(int i = 0; i < m_frozen_count; i++)
         if(m_frozen[i].active && m_frozen[i].comment == comment)
            return i;
      return -1;
     }

   void StoreFrozen(const SGmPreActivationSnapshot &s, const ENUM_ORDER_TYPE ot,
                    const double price, const double sl, const double tp, const double lots, const double sl_dist)
     {
      if(m_frozen_count >= GM_P11B_MAX_FROZEN)
         return;
      SGmP11BFrozenPending f;
      f.original_ticket = s.ticket;
      f.comment = s.comment;
      f.level_index = s.level_index;
      f.order_type = ot;
      f.price = price;
      f.sl = sl;
      f.tp = tp;
      f.lots = lots;
      f.sl_dist_lots = sl_dist;
      f.frozen_at = TimeCurrent();
      f.confidence_at_freeze = s.execution_confidence;
      f.why = s.why;
      f.active = true;
      m_frozen[m_frozen_count] = f;
      m_frozen_count++;
      m_frozen_session++;
     }

   bool DeletePendingTicket(const ulong ticket)
     {
      if(ticket == 0 || !OrderSelect(ticket))
         return false;
      if(OrderGetString(ORDER_SYMBOL) != _Symbol || (long)OrderGetInteger(ORDER_MAGIC) != (long)m_magic)
         return false;
      const ENUM_ORDER_TYPE ot = (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
      if(ot == ORDER_TYPE_BUY || ot == ORDER_TYPE_SELL)
         return false;
      ResetLastError();
      const bool ok = m_trade.OrderDelete(ticket);
      RecordBrokerOutcome(ok);
      return ok;
     }

   bool PlaceStoredPending(const SGmP11BFrozenPending &f)
     {
      m_trade.SetExpertMagicNumber(m_magic);
      bool ok = false;
      switch(f.order_type)
        {
         case ORDER_TYPE_BUY_LIMIT:  ok = m_trade.BuyLimit(f.lots, f.price, _Symbol, f.sl, f.tp, ORDER_TIME_GTC, 0, f.comment); break;
         case ORDER_TYPE_BUY_STOP:   ok = m_trade.BuyStop(f.lots, f.price, _Symbol, f.sl, f.tp, ORDER_TIME_GTC, 0, f.comment); break;
         case ORDER_TYPE_SELL_LIMIT: ok = m_trade.SellLimit(f.lots, f.price, _Symbol, f.sl, f.tp, ORDER_TIME_GTC, 0, f.comment); break;
         case ORDER_TYPE_SELL_STOP:  ok = m_trade.SellStop(f.lots, f.price, _Symbol, f.sl, f.tp, ORDER_TIME_GTC, 0, f.comment); break;
        }
      RecordBrokerOutcome(ok);
      return ok;
     }

   void LearnOutcome(const string event, const double confidence, const string detail)
     {
      int h = FileOpen(GM_P11B_LEARN_FILE, FILE_READ|FILE_WRITE|FILE_CSV|FILE_COMMON|FILE_ANSI, ',');
      if(h == INVALID_HANDLE)
        {
         h = FileOpen(GM_P11B_LEARN_FILE, FILE_WRITE|FILE_CSV|FILE_COMMON|FILE_ANSI, ',');
         if(h != INVALID_HANDLE)
            FileWrite(h, "time", "event", "confidence", "detail");
        }
      if(h == INVALID_HANDLE)
         return;
      FileSeek(h, 0, SEEK_END);
      FileWrite(h, TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS), event, DoubleToString(confidence, 1), detail);
      FileClose(h);
     }

   void EnsurePanelObject(const string name, const ENUM_OBJECT type, const int x, const int y, const string text, const color clr, const int fontSize)
     {
      const string obj = GM_P11B_UI_PREFIX + name;
      const long chart = ChartID();
      if(ObjectFind(chart, obj) < 0)
        {
         ObjectCreate(chart, obj, type, 0, 0, 0);
         ObjectSetInteger(chart, obj, OBJPROP_CORNER, CORNER_LEFT_UPPER);
         ObjectSetInteger(chart, obj, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
         ObjectSetString(chart, obj, OBJPROP_FONT, "Arial");
         ObjectSetInteger(chart, obj, OBJPROP_SELECTABLE, false);
         ObjectSetInteger(chart, obj, OBJPROP_HIDDEN, true);
        }
      ObjectSetInteger(chart, obj, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(chart, obj, OBJPROP_YDISTANCE, y);
      ObjectSetString(chart, obj, OBJPROP_TEXT, text);
      ObjectSetInteger(chart, obj, OBJPROP_COLOR, clr);
      ObjectSetInteger(chart, obj, OBJPROP_FONTSIZE, fontSize);
     }

public:
                     CPhase11BExecutionAuthority(void)
     {
      m_magic = 0;
      m_max_lot_cap = 5.0;
      m_atr_handle = INVALID_HANDLE;
      m_enabled = true;
      m_supervisor_active = true;
      m_last_ok_analysis = 0;
      m_last_tick_run = 0;
      m_last_tick_ms = 0;
      m_max_lot_increase_pct = GM_P11B_DEF_MAX_LOT_INCREASE_PCT;
      m_max_lot_reduce_pct = GM_P11B_DEF_MAX_LOT_REDUCE_PCT;
      m_max_freeze_min = GM_P11B_DEF_MAX_FREEZE_MIN;
      m_emergency_cancel = GM_P11B_DEF_EMERGENCY_CANCEL;
      m_news_protection = GM_P11B_DEF_NEWS_PROTECTION;
      m_broker_protection = GM_P11B_DEF_BROKER_PROTECTION;
      m_weekend_protection = GM_P11B_DEF_WEEKEND_PROTECTION;
      m_min_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
      m_frozen_count = 0;
      m_cancelled_session = 0;
      m_frozen_session = 0;
      m_last_spread_pts = 0.0;
      m_last_atr = 0.0;
      m_broker_fail_streak = 0;
      m_panel_init = 0;
      m_tick_idx = 0;
      m_global.Reset();
      for(int i = 0; i < GM_P11B_MAX_FROZEN; i++)
         m_frozen[i].active = false;
      for(int j = 0; j < 8; j++)
         m_tick_buf[j] = 0.0;
     }

   void Configure(const ulong magic, const double maxLotCap, const int atrHandle,
                  const double maxIncreasePct, const double maxReducePct, const int maxFreezeMin,
                  const bool emergencyCancel, const bool newsProt, const bool brokerProt, const bool weekendProt,
                  const bool enabled)
     {
      m_magic = magic;
      m_max_lot_cap = maxLotCap;
      m_atr_handle = atrHandle;
      m_max_lot_increase_pct = maxIncreasePct;
      m_max_lot_reduce_pct = maxReducePct;
      m_max_freeze_min = maxFreezeMin;
      m_emergency_cancel = emergencyCancel;
      m_news_protection = newsProt;
      m_broker_protection = brokerProt;
      m_weekend_protection = weekendProt;
      m_enabled = enabled;
      m_supervisor_active = enabled;
      m_trade.SetExpertMagicNumber(m_magic);
      m_min_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
      if(m_enabled)
         PrintFormat("TGM [P11B]: AI Execution Supervisor ACTIVE | %s | PRE-ACTIVATION ONLY", GM_P11B_VERSION);
     }

   bool IsEnabled(void) const { return m_enabled; }
   bool IsSupervisorActive(void) const { return m_supervisor_active && m_enabled; }
   SGmPreActivationSnapshot GlobalSnapshot(void) const { return m_global; }

   double AdjustLotForPlacement(const double engineLots, const int levelIndex, const string comment, const bool isBuy)
     {
      if(!IsSupervisorActive())
         return engineLots;

      SGmPreActivationSnapshot s = AnalyzePending(0, comment, levelIndex);
      m_global = s;
      m_last_ok_analysis = TimeCurrent();

      if(s.action == GM_P11B_ACT_FREEZE || s.action == GM_P11B_ACT_CANCEL)
         return engineLots;

      double lots = engineLots;
      if(s.action == GM_P11B_ACT_INCREASE_LOT || s.action == GM_P11B_ACT_REDUCE_LOT)
         lots = engineLots * s.lot_multiplier;

      const double vmin = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
      const double vmax = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
      const double vstep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
      if(m_max_lot_cap > 0.0 && m_max_lot_cap < vmax)
         lots = MathMin(lots, m_max_lot_cap);
      lots = MathMax(m_min_lot, lots);
      lots = MathFloor(lots / vstep) * vstep;
      lots = NormalizeDouble(MathMax(vmin, MathMin(vmax, lots)), 2);
      LearnOutcome("LOT_ADJUST", s.execution_confidence, s.why);
      return lots;
     }

   bool AllowPlacement(const string comment, const int levelIndex)
     {
      if(!IsSupervisorActive())
         return true;
      SGmPreActivationSnapshot s = AnalyzePending(0, comment, levelIndex);
      m_global = s;
      m_last_ok_analysis = TimeCurrent();
      if(s.action == GM_P11B_ACT_CANCEL)
        {
         LearnOutcome("BLOCK_CANCEL_BAND", s.execution_confidence, s.why);
         return false;
        }
      return true;
     }

   void RegisterPlacedOrder(const ulong ticket, const string comment, const int levelIndex)
     {
      if(ticket == 0 || !IsSupervisorActive())
         return;
      SGmPreActivationSnapshot s = AnalyzePending(ticket, comment, levelIndex);
      m_global = s;
      m_last_ok_analysis = TimeCurrent();
     }

   void OnPositionActivated(const ulong ticket)
     {
      if(ticket == 0)
         return;
      m_global.why = "Pending activated — AI authority ENDED. Trading Engine 100% control.";
      m_global.recommendation = "READ ONLY";
      LearnOutcome("ACTIVATED_READONLY", m_global.execution_confidence, "ticket=" + IntegerToString((long)ticket));
     }

   void OnTickMonitor(void)
     {
      if(!m_enabled)
         return;

      const ulong nowMs = GetTickCount();
      if(nowMs - m_last_tick_ms < GM_P11B_THROTTLE_MS)
         return;
      m_last_tick_ms = nowMs;

      if(m_supervisor_active && m_last_ok_analysis > 0 &&
         (TimeCurrent() - m_last_ok_analysis) > GM_P11B_FAILSAFE_TIMEOUT_SEC)
        {
         DisableSupervisor("analysis timeout");
         return;
        }

      if(!IsSupervisorActive())
         return;

      for(int i = OrdersTotal() - 1; i >= 0; i--)
        {
         const ulong ticket = OrderGetTicket(i);
         if(ticket == 0 || !OrderSelect(ticket))
            continue;
         if(OrderGetString(ORDER_SYMBOL) != _Symbol || (long)OrderGetInteger(ORDER_MAGIC) != (long)m_magic)
            continue;
         const ENUM_ORDER_TYPE ot = (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
         if(ot == ORDER_TYPE_BUY || ot == ORDER_TYPE_SELL)
            continue;

         const string comment = OrderGetString(ORDER_COMMENT);
         const int level = 0;
         SGmPreActivationSnapshot s = AnalyzePending(ticket, comment, level);
         m_global = s;
         m_last_ok_analysis = TimeCurrent();

         if(s.action == GM_P11B_ACT_CANCEL)
           {
            if(DeletePendingTicket(ticket))
             {
              m_cancelled_session++;
              LearnOutcome("CANCEL_PENDING", s.execution_confidence, s.why);
             }
           }
         else if(s.action == GM_P11B_ACT_FREEZE)
           {
            if(FindFrozenSlot(comment) < 0)
              {
               const double price = OrderGetDouble(ORDER_PRICE_OPEN);
               const double sl = OrderGetDouble(ORDER_SL);
               const double tp = OrderGetDouble(ORDER_TP);
               const double lots = OrderGetDouble(ORDER_VOLUME_CURRENT);
               if(DeletePendingTicket(ticket))
                 {
                  StoreFrozen(s, ot, price, sl, tp, lots, 0.0);
                  LearnOutcome("FREEZE_PENDING", s.execution_confidence, s.why);
                 }
              }
           }
        }

      for(int f = 0; f < m_frozen_count; f++)
        {
         if(!m_frozen[f].active)
            continue;
         const int elapsedMin = (int)((TimeCurrent() - m_frozen[f].frozen_at) / 60);
         SGmPreActivationSnapshot s = AnalyzePending(0, m_frozen[f].comment, m_frozen[f].level_index);
         const bool resume = (s.execution_confidence >= 60.0) || (elapsedMin >= m_max_freeze_min);
         if(resume)
           {
            if(PlaceStoredPending(m_frozen[f]))
              {
               LearnOutcome("RESUME_FROZEN", s.execution_confidence, m_frozen[f].why);
               m_frozen[f].active = false;
              }
           }
        }
     }

   void InitPanel(const int x, const int y)
     {
      m_panel_init = TimeCurrent();
      const color gold = C'198,168,86';
      const color lbl = C'160,150,120';
      EnsurePanelObject("BG", OBJ_RECTANGLE_LABEL, x, y, "", C'12,10,8', 8);
      const long chart = ChartID();
      ObjectSetInteger(chart, GM_P11B_UI_PREFIX + "BG", OBJPROP_XSIZE, 250);
      ObjectSetInteger(chart, GM_P11B_UI_PREFIX + "BG", OBJPROP_YSIZE, 188);
      ObjectSetInteger(chart, GM_P11B_UI_PREFIX + "BG", OBJPROP_BGCOLOR, C'12,10,8');
      ObjectSetInteger(chart, GM_P11B_UI_PREFIX + "BG", OBJPROP_BORDER_COLOR, gold);
      EnsurePanelObject("Title", OBJ_LABEL, x + 8, y + 6, "AI EXECUTION SUPERVISOR", gold, 9);
      EnsurePanelObject("L1", OBJ_LABEL, x + 8, y + 24, "AI Confidence:", lbl, 8);
      EnsurePanelObject("V1", OBJ_LABEL, x + 130, y + 24, "---", clrWhite, 8);
      EnsurePanelObject("L2", OBJ_LABEL, x + 8, y + 40, "Exec Confidence:", lbl, 8);
      EnsurePanelObject("V2", OBJ_LABEL, x + 130, y + 40, "---", clrWhite, 8);
      EnsurePanelObject("L3", OBJ_LABEL, x + 8, y + 56, "Recommendation:", lbl, 8);
      EnsurePanelObject("V3", OBJ_LABEL, x + 130, y + 56, "---", clrWhite, 8);
      EnsurePanelObject("L4", OBJ_LABEL, x + 8, y + 72, "Lot Adjustment:", lbl, 8);
      EnsurePanelObject("V4", OBJ_LABEL, x + 130, y + 72, "---", clrWhite, 8);
      EnsurePanelObject("L5", OBJ_LABEL, x + 8, y + 88, "Frozen / Cancelled:", lbl, 8);
      EnsurePanelObject("V5", OBJ_LABEL, x + 130, y + 88, "---", clrWhite, 8);
      EnsurePanelObject("L6", OBJ_LABEL, x + 8, y + 104, "Spread / Volatility:", lbl, 8);
      EnsurePanelObject("V6", OBJ_LABEL, x + 130, y + 104, "---", clrWhite, 8);
      EnsurePanelObject("L7", OBJ_LABEL, x + 8, y + 120, "Market / Broker:", lbl, 8);
      EnsurePanelObject("V7", OBJ_LABEL, x + 130, y + 120, "---", clrWhite, 8);
      EnsurePanelObject("L8", OBJ_LABEL, x + 8, y + 136, "AI Health:", lbl, 8);
      EnsurePanelObject("V8", OBJ_LABEL, x + 130, y + 136, "---", clrWhite, 8);
      EnsurePanelObject("Why", OBJ_LABEL, x + 8, y + 152, "WHY: —", C'140,200,160', 7);
     }

   void UpdatePanel(const int x, const int y)
     {
      if(m_panel_init == 0)
         InitPanel(x, y);
      // MQL5: no class-member references — copy snapshot for panel bind.
      SGmPreActivationSnapshot s = m_global;
      const long chart = ChartID();
      ObjectSetString(chart, GM_P11B_UI_PREFIX + "V1", OBJPROP_TEXT, DoubleToString(s.ai_confidence, 0));
      ObjectSetString(chart, GM_P11B_UI_PREFIX + "V2", OBJPROP_TEXT, DoubleToString(s.execution_confidence, 0));
      ObjectSetString(chart, GM_P11B_UI_PREFIX + "V3", OBJPROP_TEXT, s.recommendation);
      ObjectSetString(chart, GM_P11B_UI_PREFIX + "V4", OBJPROP_TEXT,
                      (s.lot_multiplier == 1.0) ? "NONE" : DoubleToString((s.lot_multiplier - 1.0) * 100.0, 0) + "%");
      ObjectSetString(chart, GM_P11B_UI_PREFIX + "V5", OBJPROP_TEXT,
                      IntegerToString(m_frozen_session) + " / " + IntegerToString(m_cancelled_session));
      ObjectSetString(chart, GM_P11B_UI_PREFIX + "V6", OBJPROP_TEXT,
                      DoubleToString(m_last_spread_pts, 1) + " / " + DoubleToString(s.volatility, 0));
      ObjectSetString(chart, GM_P11B_UI_PREFIX + "V7", OBJPROP_TEXT, s.market_condition + " / " + DoubleToString(s.broker_quality, 0));
      string health = (s.health == GM_P11B_HEALTH_OK) ? "OK" : "DISABLED";
      ObjectSetString(chart, GM_P11B_UI_PREFIX + "V8", OBJPROP_TEXT, health + " | " + DoubleToString(s.execution_score, 0));
      string why = s.why;
      if(StringLen(why) > 120)
         why = StringSubstr(why, 0, 117) + "...";
      ObjectSetString(chart, GM_P11B_UI_PREFIX + "Why", OBJPROP_TEXT, "WHY: " + why);
     }

   void DestroyPanel(void)
     {
      const long chart = ChartID();
      for(int i = ObjectsTotal(chart, 0, -1) - 1; i >= 0; i--)
        {
         const string name = ObjectName(chart, i, 0, -1);
         if(StringFind(name, GM_P11B_UI_PREFIX) == 0)
            ObjectDelete(chart, name);
        }
     }
  };

#endif // GM_CPHASE11B_EXECUTION_AUTHORITY_MQH
//+------------------------------------------------------------------+
