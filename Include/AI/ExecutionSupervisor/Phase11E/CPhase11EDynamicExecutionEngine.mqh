//+------------------------------------------------------------------+
//|              CPhase11EDynamicExecutionEngine.mqh                 |
//|  Dynamic AI Pre-Activation Execution Engine — Phase 11E          |
//|  Continuous confidence + lot control BEFORE activation ONLY      |
//|  NEVER touches price / SL / TP / direction / Trading Engine       |
//+------------------------------------------------------------------+
#ifndef GM_CPHASE11E_DYNAMIC_EXECUTION_ENGINE_MQH
#define GM_CPHASE11E_DYNAMIC_EXECUTION_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include <Trade\Trade.mqh>
#include "Phase11EConstants.mqh"
#include "SGmDynamicConfidence.mqh"
#include "SGmTrackedPending.mqh"

class CPhase11EDynamicExecutionEngine
  {
private:
   CTrade                 m_trade;
   ulong                  m_magic;
   double                 m_max_lot_cap;
   int                    m_atr_handle;
   int                    m_rsi_handle;
   bool                   m_enabled;
   bool                   m_supervisor_active;
   bool                   m_dynamic_lot;
   datetime               m_last_ok_analysis;
   datetime               m_last_schedule;
   ulong                  m_last_tick_ms;

   double                 m_max_lot_increase_pct;
   double                 m_max_lot_reduce_pct;
   int                    m_max_freeze_min;
   bool                   m_emergency_cancel;
   bool                   m_news_protection;
   bool                   m_broker_protection;
   bool                   m_weekend_protection;
   double                 m_min_lot;

   SGmDynamicConfidence   m_global;
   SGmTrackedPending      m_tracked[GM_P11E_MAX_TRACKED];
   double                 m_orig_lot_by_comment_key[GM_P11E_MAX_TRACKED];
   string                 m_orig_comment_key[GM_P11E_MAX_TRACKED];
   int                    m_orig_count;

   int                    m_cancelled_session;
   int                    m_frozen_session;
   int                    m_lot_modify_session;
   double                 m_last_spread_pts;
   double                 m_last_atr;
   int                    m_broker_fail_streak;
   datetime               m_panel_init;
   int                    m_panel_x;
   int                    m_panel_y;
   bool                   m_panel_minimized;
   bool                   m_panel_dragging;
   int                    m_panel_drag_ox;
   int                    m_panel_drag_oy;
   bool                   m_panel_pos_ready;
   double                 m_tick_buf[8];
   int                    m_tick_idx;

   bool IsFinite(const double v) const { return (v == v && v != DBL_MAX && v != -DBL_MAX); }

   double NormalizeLots(double lots)
     {
      const double vmin = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
      const double vmax = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
      double vstep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
      if(vstep <= 0.0)
         vstep = 0.01;
      if(m_max_lot_cap > 0.0 && m_max_lot_cap < vmax)
         lots = MathMin(lots, m_max_lot_cap);
      lots = MathMax(m_min_lot > 0.0 ? m_min_lot : vmin, lots);
      lots = MathFloor(lots / vstep + 1e-9) * vstep;
      return NormalizeDouble(MathMax(vmin, MathMin(vmax, lots)), 2);
     }

   double ReadAtr(void)
     {
      if(m_atr_handle == INVALID_HANDLE) return 0.0;
      double buf[];
      ArraySetAsSeries(buf, true);
      if(CopyBuffer(m_atr_handle, 0, 0, 3, buf) < 2) return 0.0;
      return buf[0];
     }

   double ReadAtrPrev(void)
     {
      if(m_atr_handle == INVALID_HANDLE) return 0.0;
      double buf[];
      ArraySetAsSeries(buf, true);
      if(CopyBuffer(m_atr_handle, 0, 1, 5, buf) < 4) return 0.0;
      double sum = 0.0;
      for(int i = 0; i < 4; i++) sum += buf[i];
      return sum / 4.0;
     }

   double ReadRsi(void)
     {
      if(m_rsi_handle == INVALID_HANDLE)
         m_rsi_handle = iRSI(_Symbol, PERIOD_H4, 14, PRICE_CLOSE);
      if(m_rsi_handle == INVALID_HANDLE) return 50.0;
      double buf[];
      ArraySetAsSeries(buf, true);
      if(CopyBuffer(m_rsi_handle, 0, 0, 1, buf) < 1) return 50.0;
      return buf[0];
     }

   void DisableSupervisor(const string reason)
     {
      m_supervisor_active = false;
      m_global.health = GM_P11E_HEALTH_DISABLED;
      m_global.why = "FAILSAFE: AI disabled — " + reason + " | Trading Engine continues normally.";
      m_global.recommendation = "DISABLED";
      PrintFormat("TGM [P11E FAILSAFE]: %s", m_global.why);
     }

   void RecordBrokerOutcome(const bool ok)
     {
      if(ok) m_broker_fail_streak = 0;
      else m_broker_fail_streak++;
      if(m_broker_protection && m_broker_fail_streak >= 5)
         DisableSupervisor("broker execution quality degraded");
     }

   //--- Multi-factor scoring ------------------------------------------------
   double ScoreSpread(const double spread_pts, const double atr)
     {
      if(atr <= 0.0) return 50.0;
      const double ratio = spread_pts * _Point / atr;
      return GmP11EClamp01(100.0 - ratio * 400.0);
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

   double ScoreTrendSigned(double &buyBias, double &sellBias)
     {
      double close[];
      ArraySetAsSeries(close, true);
      if(CopyClose(_Symbol, PERIOD_H4, 0, 5, close) < 5)
        {
         buyBias = sellBias = 50.0;
         return 50.0;
        }
      const double slope = close[0] - close[4];
      const double atr = ReadAtr();
      if(atr <= 0.0)
        {
         buyBias = sellBias = 50.0;
         return 50.0;
        }
      const double strength = GmP11EClamp01(50.0 + MathAbs(slope / atr) * 25.0);
      if(slope >= 0.0)
        {
         buyBias = GmP11EClamp01(50.0 + (slope / atr) * 35.0);
         sellBias = GmP11EClamp01(50.0 - (slope / atr) * 35.0);
        }
      else
        {
         sellBias = GmP11EClamp01(50.0 + (MathAbs(slope) / atr) * 35.0);
         buyBias = GmP11EClamp01(50.0 - (MathAbs(slope) / atr) * 35.0);
        }
      return strength;
     }

   double ScoreMomentum(double &buyMom, double &sellMom)
     {
      const double rsi = ReadRsi();
      const double strength = GmP11EClamp01(MathAbs(rsi - 50.0) * 2.0);
      buyMom = GmP11EClamp01(rsi);           // higher RSI supports buy continuation cautiously
      sellMom = GmP11EClamp01(100.0 - rsi);  // lower RSI supports sell
      // Cap extremes: overbought/oversold reduce side confidence
      if(rsi > 70.0) buyMom = GmP11EClamp01(buyMom - (rsi - 70.0));
      if(rsi < 30.0) sellMom = GmP11EClamp01(sellMom - (30.0 - rsi));
      return strength;
     }

   double ScoreLiquidity(void)
     {
      long vol[];
      ArraySetAsSeries(vol, true);
      if(CopyTickVolume(_Symbol, PERIOD_H4, 0, 10, vol) < 10) return 50.0;
      long sum = 0;
      for(int i = 0; i < 10; i++) sum += vol[i];
      if(sum <= 0) return 40.0;
      return GmP11EClamp01(40.0 + (double)vol[0] / (double)(sum / 10) * 30.0);
     }

   double ScoreTickSpeed(void)
     {
      m_tick_buf[m_tick_idx % 8] = (double)GetTickCount();
      m_tick_idx++;
      if(m_tick_idx < 4) return 50.0;
      double dt = m_tick_buf[(m_tick_idx - 1) % 8] - m_tick_buf[(m_tick_idx - 4) % 8];
      if(dt <= 0.0) return 50.0;
      return GmP11EClamp01((3000.0 / dt) * 15.0);
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
      return GmP11EClamp01(100.0 - (range / atr) * 20.0);
     }

   SGmDynamicConfidence AnalyzeMarket(const ulong ticket, const string comment, const int levelIndex, const bool isBuySide)
     {
      SGmDynamicConfidence s;
      s.Reset();
      s.stamped_at = TimeCurrent();
      s.symbol = _Symbol;
      s.ticket = ticket;
      s.comment = comment;
      s.level_index = levelIndex;
      s.is_buy_side = isBuySide;

      const double atr = ReadAtr();
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

      double buyTrend = 50.0, sellTrend = 50.0;
      double buyMom = 50.0, sellMom = 50.0;
      s.trend_strength = ScoreTrendSigned(buyTrend, sellTrend);
      s.momentum_strength = ScoreMomentum(buyMom, sellMom);
      s.liquidity_score = ScoreLiquidity();
      s.spread_health = ScoreSpread(spread_pts, atr);
      s.volatility_score = GmP11EClamp01((atr / _Point) / 500.0 * 100.0);
      s.news_risk = ScoreNewsRisk();
      s.session_strength = ScoreSession();
      s.broker_quality = GmP11EClamp01(100.0 - m_broker_fail_streak * 12.0);
      s.market_structure = ScoreStructure();
      const double tickSpeed = ScoreTickSpeed();

      s.buy_confidence = GmP11EClamp01(
         buyTrend * 0.30 + buyMom * 0.20 + s.market_structure * 0.15 +
         s.liquidity_score * 0.10 + s.spread_health * 0.10 + s.session_strength * 0.08 +
         s.news_risk * 0.07);

      s.sell_confidence = GmP11EClamp01(
         sellTrend * 0.30 + sellMom * 0.20 + s.market_structure * 0.15 +
         s.liquidity_score * 0.10 + s.spread_health * 0.10 + s.session_strength * 0.08 +
         s.news_risk * 0.07);

      s.overall_ai_confidence = GmP11EClamp01(
         (s.buy_confidence + s.sell_confidence) * 0.20 +
         s.trend_strength * 0.12 +
         s.momentum_strength * 0.10 +
         s.liquidity_score * 0.08 +
         s.spread_health * 0.12 +
         s.volatility_score * 0.06 +
         s.news_risk * 0.10 +
         s.session_strength * 0.08 +
         s.broker_quality * 0.08 +
         tickSpeed * 0.06);

      // Side-specific decision confidence for the pending under review
      const double sideConf = isBuySide ? s.buy_confidence : s.sell_confidence;
      s.decision_confidence = GmP11EClamp01(
         sideConf * 0.55 +
         s.spread_health * 0.12 +
         s.news_risk * 0.10 +
         s.broker_quality * 0.10 +
         s.liquidity_score * 0.08 +
         s.overall_ai_confidence * 0.05);

      if(s.news_risk < 40.0) s.market_condition = "NEWS/WEEKEND RISK";
      else if(s.spread_health < 45.0) s.market_condition = "WIDE SPREAD";
      else if(s.volatility_score > 75.0) s.market_condition = "HIGH VOLATILITY";
      else if(s.trend_strength > 70.0) s.market_condition = "TRENDING";
      else s.market_condition = "BALANCED";

      s.market_evidence = StringFormat(
         "Buy=%.0f Sell=%.0f Trend=%.0f Mom=%.0f Liq=%.0f Spread=%.0f Vol=%.0f News=%.0f",
         s.buy_confidence, s.sell_confidence, s.trend_strength, s.momentum_strength,
         s.liquidity_score, s.spread_health, s.volatility_score, s.news_risk);

      s.band = GmP11EBandFromConfidence(s.decision_confidence);
      s.action = DecideAction(s.band);
      s.recommendation = GmP11EActionName(s.action);
      s.health = m_supervisor_active ? GM_P11E_HEALTH_OK : GM_P11E_HEALTH_DISABLED;
      s.frozen_count = m_frozen_session;
      s.cancelled_count = m_cancelled_session;
      s.lot_modify_count = m_lot_modify_session;
      s.valid = m_supervisor_active;
      return s;
     }

   ENUM_GM_P11E_ACTION DecideAction(const ENUM_GM_P11E_DECISION_BAND band)
     {
      switch(band)
        {
         case GM_P11E_BAND_EXTREMELY_STRONG: return GM_P11E_ACT_INCREASE_LOT;
         case GM_P11E_BAND_STRONG:           return GM_P11E_ACT_RESTORE_LOT;
         case GM_P11E_BAND_CAUTION:          return GM_P11E_ACT_REDUCE_LOT;
         case GM_P11E_BAND_HIGH_RISK:        return GM_P11E_ACT_FREEZE;
         case GM_P11E_BAND_EXTREME_RISK:     return m_emergency_cancel ? GM_P11E_ACT_CANCEL : GM_P11E_ACT_FREEZE;
        }
      return GM_P11E_ACT_PASS;
     }

   double TargetLotFromAction(const double originalLot, const ENUM_GM_P11E_ACTION act)
     {
      if(originalLot <= 0.0) return 0.0;
      double lots = originalLot;
      switch(act)
        {
         case GM_P11E_ACT_INCREASE_LOT:
            lots = originalLot * (1.0 + m_max_lot_increase_pct / 100.0);
            break;
         case GM_P11E_ACT_RESTORE_LOT:
            lots = originalLot;
            break;
         case GM_P11E_ACT_REDUCE_LOT:
            lots = originalLot * (1.0 - m_max_lot_reduce_pct / 100.0);
            break;
         default:
            lots = originalLot;
            break;
        }
      return NormalizeLots(lots);
     }

   void BuildWhy(SGmDynamicConfidence &s)
     {
      string why = StringFormat(
         "DecConf=%.0f Overall=%.0f Band=%s Side=%s | %s | ",
         s.decision_confidence, s.overall_ai_confidence, GmP11EBandName(s.band),
         (s.is_buy_side ? "BUY" : "SELL"), s.market_evidence);
      switch(s.action)
        {
         case GM_P11E_ACT_INCREASE_LOT:
            why += StringFormat("High confidence — lot up to +%.0f%% of original BEFORE activation.", m_max_lot_increase_pct);
            break;
         case GM_P11E_ACT_RESTORE_LOT:
            why += "Strong conditions — restore original Engine lot. Price/SL/TP untouched.";
            break;
         case GM_P11E_ACT_REDUCE_LOT:
            why += StringFormat("Caution — lot reduced up to %.0f%% of original BEFORE activation.", m_max_lot_reduce_pct);
            break;
         case GM_P11E_ACT_FREEZE:
            why += StringFormat("High risk — freeze pending (max %d min). Geometry immutable.", m_max_freeze_min);
            break;
         case GM_P11E_ACT_CANCEL:
            why += "Extreme risk — cancel pending BEFORE activation. Active trades untouched.";
            break;
         default:
            why += "Pass — no AI lot action.";
            break;
        }
      if(StringLen(why) > GM_P11E_WHY_MAX)
         why = StringSubstr(why, 0, GM_P11E_WHY_MAX);
      s.why = why;
     }

   //--- Tracking helpers ----------------------------------------------------
   void RememberOriginalLot(const string comment, const double engineLots)
     {
      for(int i = 0; i < m_orig_count; i++)
        {
         if(m_orig_comment_key[i] == comment)
           {
            m_orig_lot_by_comment_key[i] = engineLots;
            return;
           }
        }
      if(m_orig_count >= GM_P11E_MAX_TRACKED) return;
      m_orig_comment_key[m_orig_count] = comment;
      m_orig_lot_by_comment_key[m_orig_count] = engineLots;
      m_orig_count++;
     }

   double LookupOriginalLot(const string comment, const double fallback)
     {
      for(int i = 0; i < m_orig_count; i++)
         if(m_orig_comment_key[i] == comment)
            return m_orig_lot_by_comment_key[i];
      return fallback;
     }

   int FindTrackedByTicket(const ulong ticket)
     {
      for(int i = 0; i < GM_P11E_MAX_TRACKED; i++)
         if(m_tracked[i].used && m_tracked[i].ticket == ticket)
            return i;
      return -1;
     }

   int FindTrackedByCommentLive(const string comment)
     {
      for(int i = 0; i < GM_P11E_MAX_TRACKED; i++)
         if(m_tracked[i].used && m_tracked[i].comment == comment &&
            (m_tracked[i].state == GM_P11E_STATE_LIVE || m_tracked[i].state == GM_P11E_STATE_FROZEN))
            return i;
      return -1;
     }

   int AllocTrackedSlot(void)
     {
      for(int i = 0; i < GM_P11E_MAX_TRACKED; i++)
         if(!m_tracked[i].used)
            return i;
      // Reuse oldest activated/cancelled/expired
      for(int j = 0; j < GM_P11E_MAX_TRACKED; j++)
        {
         if(m_tracked[j].state == GM_P11E_STATE_ACTIVATED_READONLY ||
            m_tracked[j].state == GM_P11E_STATE_CANCELLED ||
            m_tracked[j].state == GM_P11E_STATE_EXPIRED)
            return j;
        }
      return -1;
     }

   bool IsBuyOrderType(const ENUM_ORDER_TYPE ot) const
     {
      return (ot == ORDER_TYPE_BUY_LIMIT || ot == ORDER_TYPE_BUY_STOP ||
              ot == ORDER_TYPE_BUY_STOP_LIMIT || ot == ORDER_TYPE_BUY);
     }

   bool DeletePendingTicket(const ulong ticket)
     {
      if(ticket == 0 || !OrderSelect(ticket)) return false;
      if(OrderGetString(ORDER_SYMBOL) != _Symbol || (long)OrderGetInteger(ORDER_MAGIC) != (long)m_magic)
         return false;
      const ENUM_ORDER_TYPE ot = (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
      if(ot == ORDER_TYPE_BUY || ot == ORDER_TYPE_SELL) return false; // never touch market positions
      ResetLastError();
      const bool ok = m_trade.OrderDelete(ticket);
      RecordBrokerOutcome(ok);
      return ok;
     }

   bool PlacePendingExact(const ENUM_ORDER_TYPE ot, const double lots,
                          const double price, const double sl, const double tp, const string comment)
     {
      // Price/SL/TP must be the Engine values already captured — AI does not recalculate them.
      m_trade.SetExpertMagicNumber(m_magic);
      bool ok = false;
      switch(ot)
        {
         case ORDER_TYPE_BUY_LIMIT:  ok = m_trade.BuyLimit(lots, price, _Symbol, sl, tp, ORDER_TIME_GTC, 0, comment); break;
         case ORDER_TYPE_BUY_STOP:   ok = m_trade.BuyStop(lots, price, _Symbol, sl, tp, ORDER_TIME_GTC, 0, comment); break;
         case ORDER_TYPE_SELL_LIMIT: ok = m_trade.SellLimit(lots, price, _Symbol, sl, tp, ORDER_TIME_GTC, 0, comment); break;
         case ORDER_TYPE_SELL_STOP:  ok = m_trade.SellStop(lots, price, _Symbol, sl, tp, ORDER_TIME_GTC, 0, comment); break;
         default: ok = false; break;
        }
      RecordBrokerOutcome(ok);
      return ok;
     }

   void LearnDecision(const string event,
                      const double prevConf, const double newConf,
                      const double prevLot, const double newLot,
                      const string evidence, const string reason)
     {
      int h = FileOpen(GM_P11E_LEARN_FILE, FILE_READ|FILE_WRITE|FILE_CSV|FILE_COMMON|FILE_ANSI, ',');
      if(h == INVALID_HANDLE)
        {
         h = FileOpen(GM_P11E_LEARN_FILE, FILE_WRITE|FILE_CSV|FILE_COMMON|FILE_ANSI, ',');
         if(h != INVALID_HANDLE)
            FileWrite(h, "time", "event", "prev_conf", "new_conf", "prev_lot", "new_lot", "evidence", "reason");
        }
      if(h == INVALID_HANDLE) return;
      FileSeek(h, 0, SEEK_END);
      FileWrite(h,
                TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS),
                event,
                DoubleToString(prevConf, 1),
                DoubleToString(newConf, 1),
                DoubleToString(prevLot, 2),
                DoubleToString(newLot, 2),
                evidence,
                reason);
      FileClose(h);

      // Dual-write Phase 11B learn file for continuity with prior evidence collectors
      int h2 = FileOpen("GM_P11B_EXEC_LEARN.csv", FILE_READ|FILE_WRITE|FILE_CSV|FILE_COMMON|FILE_ANSI, ',');
      if(h2 == INVALID_HANDLE)
         h2 = FileOpen("GM_P11B_EXEC_LEARN.csv", FILE_WRITE|FILE_CSV|FILE_COMMON|FILE_ANSI, ',');
      if(h2 != INVALID_HANDLE)
        {
         FileSeek(h2, 0, SEEK_END);
         FileWrite(h2, TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS), event,
                   DoubleToString(newConf, 1),
                   StringFormat("prev=%.1f lots %.2f->%.2f | %s | %s", prevConf, prevLot, newLot, evidence, reason));
         FileClose(h2);
        }
     }

   bool ApplyLotChange(SGmTrackedPending &t, const double targetLot, SGmDynamicConfidence &s)
     {
      if(!m_dynamic_lot) return false;
      if(MathAbs(targetLot - t.current_lot) < GM_P11E_LOT_EPS) return false;
      if(t.ticket == 0 || !OrderSelect(t.ticket)) return false;

      // Re-read immutable geometry from live order — never invent prices
      const double price = OrderGetDouble(ORDER_PRICE_OPEN);
      const double sl = OrderGetDouble(ORDER_SL);
      const double tp = OrderGetDouble(ORDER_TP);
      const ENUM_ORDER_TYPE ot = (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
      const double prevLot = t.current_lot;
      const double prevConf = t.last_decision_confidence;

      // Guard: geometry must still match tracked frozen values (tolerance 1 point)
      if(MathAbs(price - t.frozen_price) > _Point * 2.0 ||
         MathAbs(sl - t.frozen_sl) > _Point * 2.0 ||
         MathAbs(tp - t.frozen_tp) > _Point * 2.0)
        {
         // Prefer live broker geometry if Engine already set it; keep immutable going forward
         t.frozen_price = price;
         t.frozen_sl = sl;
         t.frozen_tp = tp;
        }

      if(!DeletePendingTicket(t.ticket))
         return false;

      if(!PlacePendingExact(ot, targetLot, t.frozen_price, t.frozen_sl, t.frozen_tp, t.comment))
        {
         // Attempt restore previous lot on same immutable geometry
         PlacePendingExact(ot, prevLot, t.frozen_price, t.frozen_sl, t.frozen_tp, t.comment);
         return false;
        }

      // Update ticket to newest matching comment
      ulong newTicket = 0;
      for(int i = OrdersTotal() - 1; i >= 0; i--)
        {
         const ulong tk = OrderGetTicket(i);
         if(tk == 0 || !OrderSelect(tk)) continue;
         if(OrderGetString(ORDER_SYMBOL) != _Symbol) continue;
         if((long)OrderGetInteger(ORDER_MAGIC) != (long)m_magic) continue;
         if(OrderGetString(ORDER_COMMENT) != t.comment) continue;
         if(MathAbs(OrderGetDouble(ORDER_PRICE_OPEN) - t.frozen_price) > _Point * 2.0) continue;
         newTicket = tk;
         break;
        }

      t.ticket = newTicket;
      t.current_lot = targetLot;
      t.last_target_lot = targetLot;
      t.lot_modify_count++;
      m_lot_modify_session++;
      t.last_action = s.action;
      t.last_decision_confidence = s.decision_confidence;
      t.last_overall_confidence = s.overall_ai_confidence;
      t.last_why = s.why;
      t.last_eval_at = TimeCurrent();

      s.current_lot = targetLot;
      s.target_lot = targetLot;
      s.original_lot = t.original_lot;
      s.lot_multiplier = (t.original_lot > 0.0) ? (targetLot / t.original_lot) : 1.0;

      LearnDecision("LOT_MODIFY", prevConf, s.decision_confidence, prevLot, targetLot, s.market_evidence, s.why);
      PrintFormat("TGM [P11E]: LOT_MODIFY %s %.2f -> %.2f | price=%.5f SL=%.5f TP=%.5f UNCHANGED | %s",
                  t.comment, prevLot, targetLot, t.frozen_price, t.frozen_sl, t.frozen_tp, GmP11EBandName(s.band));
      return true;
     }

   bool FreezeTracked(SGmTrackedPending &t, SGmDynamicConfidence &s)
     {
      if(t.state == GM_P11E_STATE_FROZEN) return false;
      if(t.ticket == 0 || !OrderSelect(t.ticket)) return false;
      const double prevLot = t.current_lot;
      const double prevConf = t.last_decision_confidence;
      t.frozen_price = OrderGetDouble(ORDER_PRICE_OPEN);
      t.frozen_sl = OrderGetDouble(ORDER_SL);
      t.frozen_tp = OrderGetDouble(ORDER_TP);
      t.order_type = (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
      if(!DeletePendingTicket(t.ticket))
         return false;
      t.ticket = 0;
      t.state = GM_P11E_STATE_FROZEN;
      t.frozen_at = TimeCurrent();
      t.last_action = GM_P11E_ACT_FREEZE;
      t.last_decision_confidence = s.decision_confidence;
      t.last_overall_confidence = s.overall_ai_confidence;
      t.last_why = s.why;
      m_frozen_session++;
      s.pending_state = GM_P11E_STATE_FROZEN;
      LearnDecision("FREEZE", prevConf, s.decision_confidence, prevLot, prevLot, s.market_evidence, s.why);
      return true;
     }

   bool CancelTracked(SGmTrackedPending &t, SGmDynamicConfidence &s)
     {
      if(t.state == GM_P11E_STATE_CANCELLED) return false;
      const double prevLot = t.current_lot;
      const double prevConf = t.last_decision_confidence;
      if(t.state == GM_P11E_STATE_LIVE && t.ticket != 0)
        {
         if(!DeletePendingTicket(t.ticket))
            return false;
        }
      t.ticket = 0;
      t.state = GM_P11E_STATE_CANCELLED;
      t.last_action = GM_P11E_ACT_CANCEL;
      t.last_decision_confidence = s.decision_confidence;
      t.last_why = s.why;
      m_cancelled_session++;
      s.pending_state = GM_P11E_STATE_CANCELLED;
      LearnDecision("CANCEL", prevConf, s.decision_confidence, prevLot, 0.0, s.market_evidence, s.why);
      return true;
     }

   bool ResumeTracked(SGmTrackedPending &t, SGmDynamicConfidence &s)
     {
      if(t.state != GM_P11E_STATE_FROZEN) return false;
      // Resume only when band is no longer freeze/cancel
      ENUM_GM_P11E_ACTION act = DecideAction(s.band);
      if(act == GM_P11E_ACT_FREEZE || act == GM_P11E_ACT_CANCEL)
         return false;
      const double lots = TargetLotFromAction(t.original_lot, act);
      if(!PlacePendingExact(t.order_type, lots, t.frozen_price, t.frozen_sl, t.frozen_tp, t.comment))
         return false;

      ulong newTicket = 0;
      for(int i = OrdersTotal() - 1; i >= 0; i--)
        {
         const ulong tk = OrderGetTicket(i);
         if(tk == 0 || !OrderSelect(tk)) continue;
         if(OrderGetString(ORDER_COMMENT) != t.comment) continue;
         if((long)OrderGetInteger(ORDER_MAGIC) != (long)m_magic) continue;
         newTicket = tk;
         break;
        }
      const double prevLot = t.current_lot;
      const double prevConf = t.last_decision_confidence;
      t.ticket = newTicket;
      t.current_lot = lots;
      t.state = GM_P11E_STATE_LIVE;
      t.last_action = GM_P11E_ACT_RESUME;
      t.last_decision_confidence = s.decision_confidence;
      t.last_why = s.why;
      t.last_eval_at = TimeCurrent();
      s.action = GM_P11E_ACT_RESUME;
      s.recommendation = "RESUME";
      s.pending_state = GM_P11E_STATE_LIVE;
      s.current_lot = lots;
      s.target_lot = lots;
      LearnDecision("RESUME", prevConf, s.decision_confidence, prevLot, lots, s.market_evidence, s.why);
      return true;
     }

   void EvaluateTracked(const int idx, const bool force)
     {
      if(idx < 0 || idx >= GM_P11E_MAX_TRACKED) return;
      if(!m_tracked[idx].used) return;
      if(m_tracked[idx].activated_readonly) return;
      if(m_tracked[idx].state == GM_P11E_STATE_CANCELLED ||
         m_tracked[idx].state == GM_P11E_STATE_EXPIRED ||
         m_tracked[idx].state == GM_P11E_STATE_ACTIVATED_READONLY)
         return;

      SGmTrackedPending t = m_tracked[idx];
      // Sync live ticket if still open
      if(t.state == GM_P11E_STATE_LIVE)
        {
         bool stillOpen = false;
         if(t.ticket != 0 && OrderSelect(t.ticket))
           {
            stillOpen = true;
            t.current_lot = OrderGetDouble(ORDER_VOLUME_CURRENT);
           }
         else
           {
            // Ticket may have been replaced; find by comment+price
            for(int i = OrdersTotal() - 1; i >= 0; i--)
              {
               const ulong tk = OrderGetTicket(i);
               if(tk == 0 || !OrderSelect(tk)) continue;
               if(OrderGetString(ORDER_SYMBOL) != _Symbol) continue;
               if((long)OrderGetInteger(ORDER_MAGIC) != (long)m_magic) continue;
               if(OrderGetString(ORDER_COMMENT) != t.comment) continue;
               t.ticket = tk;
               t.current_lot = OrderGetDouble(ORDER_VOLUME_CURRENT);
               stillOpen = true;
               break;
              }
           }
         if(!stillOpen)
           {
            // Pending gone: if a matching open position exists, mark READ ONLY; else expired.
            bool activated = false;
            for(int p = PositionsTotal() - 1; p >= 0; p--)
              {
               const ulong posTicket = PositionGetTicket(p);
               if(posTicket == 0 || !PositionSelectByTicket(posTicket)) continue;
               if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
               if((long)PositionGetInteger(POSITION_MAGIC) != (long)m_magic) continue;
               const string posComment = PositionGetString(POSITION_COMMENT);
               if(posComment == t.comment || StringFind(posComment, t.comment) == 0)
                 {
                  activated = true;
                  break;
                 }
              }
            if(activated)
              {
               t.state = GM_P11E_STATE_ACTIVATED_READONLY;
               t.activated_readonly = true;
               t.last_action = GM_P11E_ACT_READONLY;
               t.used = true;
               m_tracked[idx] = t;
               LearnDecision("ACTIVATED_READONLY", t.last_decision_confidence, t.last_decision_confidence,
                             t.current_lot, t.current_lot, "position matched comment",
                             "track=" + t.comment);
              }
            else
              {
               t.state = GM_P11E_STATE_EXPIRED;
               t.used = true;
               m_tracked[idx] = t;
              }
            return;
           }
        }

      SGmDynamicConfidence s = AnalyzeMarket(t.ticket, t.comment, t.level_index, t.is_buy_side);
      s.original_lot = t.original_lot;
      s.current_lot = t.current_lot;
      s.pending_state = t.state;
      BuildWhy(s);
      const double target = TargetLotFromAction(t.original_lot, s.action);
      s.target_lot = target;
      s.lot_multiplier = (t.original_lot > 0.0) ? (target / t.original_lot) : 1.0;

      if(t.state == GM_P11E_STATE_FROZEN)
        {
         const int elapsedMin = (int)((TimeCurrent() - t.frozen_at) / 60);
         const bool canResume = (s.decision_confidence >= 60.0) || (elapsedMin >= m_max_freeze_min && s.decision_confidence >= 50.0);
         if(canResume)
           {
            if(ResumeTracked(t, s))
               m_tracked[idx] = t;
           }
         m_global = s;
         m_last_ok_analysis = TimeCurrent();
         return;
        }

      // LIVE pending continuous control
      if(s.action == GM_P11E_ACT_CANCEL)
        {
         if(CancelTracked(t, s))
            m_tracked[idx] = t;
        }
      else if(s.action == GM_P11E_ACT_FREEZE)
        {
         if(FreezeTracked(t, s))
            m_tracked[idx] = t;
        }
      else if(s.action == GM_P11E_ACT_INCREASE_LOT ||
              s.action == GM_P11E_ACT_RESTORE_LOT ||
              s.action == GM_P11E_ACT_REDUCE_LOT)
        {
         if(MathAbs(target - t.current_lot) >= SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP) * 0.5)
            ApplyLotChange(t, target, s);
         else
           {
            t.last_action = s.action;
            t.last_decision_confidence = s.decision_confidence;
            t.last_overall_confidence = s.overall_ai_confidence;
            t.last_why = s.why;
            t.last_eval_at = TimeCurrent();
           }
         m_tracked[idx] = t;
        }

      m_global = s;
      m_global.original_lot = t.original_lot;
      m_global.current_lot = t.current_lot;
      m_global.target_lot = target;
      m_last_ok_analysis = TimeCurrent();
     }

   void EnsurePanelObject(const string name, const ENUM_OBJECT type, const int x, const int y,
                          const string text, const color clr, const int fontSize)
     {
      const string obj = GM_P11E_UI_PREFIX + name;
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

   void SetPanelBodyVisibility(const long chart, const long visibilityState)
     {
      string body[] = {"L01","V01","L02","V02","L03","V03","L04","V04","L05","V05","L06","V06",
                       "L07","V07","L08","V08","L09","V09","L10","V10","L11","V11","L12","V12","Why","Ev"};
      for(int i = 0; i < ArraySize(body); i++)
         ObjectSetInteger(chart, GM_P11E_UI_PREFIX + body[i], OBJPROP_TIMEFRAMES, visibilityState);
     }

   void RenderPanelLayout(void)
     {
      const long chart = ChartID();
      const int px = m_panel_x;
      const int py = m_panel_y;
      const int height = m_panel_minimized ? GM_P11E_PANEL_H_MIN : GM_P11E_PANEL_H;
      const long bodyVis = m_panel_minimized ? OBJ_NO_PERIODS : OBJ_ALL_PERIODS;

      ObjectSetInteger(chart, GM_P11E_UI_PREFIX + "BG", OBJPROP_XDISTANCE, px);
      ObjectSetInteger(chart, GM_P11E_UI_PREFIX + "BG", OBJPROP_YDISTANCE, py);
      ObjectSetInteger(chart, GM_P11E_UI_PREFIX + "BG", OBJPROP_XSIZE, GM_P11E_PANEL_W);
      ObjectSetInteger(chart, GM_P11E_UI_PREFIX + "BG", OBJPROP_YSIZE, height);
      ObjectSetInteger(chart, GM_P11E_UI_PREFIX + "BG", OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);

      ObjectSetInteger(chart, GM_P11E_UI_PREFIX + "Header", OBJPROP_XDISTANCE, px);
      ObjectSetInteger(chart, GM_P11E_UI_PREFIX + "Header", OBJPROP_YDISTANCE, py);
      ObjectSetInteger(chart, GM_P11E_UI_PREFIX + "Header", OBJPROP_XSIZE, GM_P11E_PANEL_W);
      ObjectSetInteger(chart, GM_P11E_UI_PREFIX + "Header", OBJPROP_YSIZE, GM_P11E_PANEL_HEADER_H);
      ObjectSetInteger(chart, GM_P11E_UI_PREFIX + "Header", OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);

      ObjectSetInteger(chart, GM_P11E_UI_PREFIX + "Title", OBJPROP_XDISTANCE, px + 8);
      ObjectSetInteger(chart, GM_P11E_UI_PREFIX + "Title", OBJPROP_YDISTANCE, py + 6);
      ObjectSetInteger(chart, GM_P11E_UI_PREFIX + "Title", OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);

      ObjectSetInteger(chart, GM_P11E_UI_PREFIX + "BtnMin", OBJPROP_XDISTANCE, px + GM_P11E_PANEL_W - 30);
      ObjectSetInteger(chart, GM_P11E_UI_PREFIX + "BtnMin", OBJPROP_YDISTANCE, py + 6);
      ObjectSetString(chart, GM_P11E_UI_PREFIX + "BtnMin", OBJPROP_TEXT, m_panel_minimized ? "[+]" : "[-]");
      ObjectSetInteger(chart, GM_P11E_UI_PREFIX + "BtnMin", OBJPROP_COLOR, m_panel_minimized ? clrLime : clrSilver);
      ObjectSetInteger(chart, GM_P11E_UI_PREFIX + "BtnMin", OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);

      string names[] = {"L01","V01","L02","V02","L03","V03","L04","V04","L05","V05","L06","V06",
                        "L07","V07","L08","V08","L09","V09","L10","V10","L11","V11","L12","V12","Why","Ev"};
      int ys[] = {36,36,52,52,68,68,84,84,100,100,116,116,132,132,148,148,164,164,180,180,196,196,212,212,232,260};
      int xs[] = {8,150,8,150,8,150,8,150,8,150,8,150,8,150,8,150,8,150,8,150,8,150,8,150,8,8};
      for(int n = 0; n < ArraySize(names); n++)
        {
         ObjectSetInteger(chart, GM_P11E_UI_PREFIX + names[n], OBJPROP_XDISTANCE, px + xs[n]);
         ObjectSetInteger(chart, GM_P11E_UI_PREFIX + names[n], OBJPROP_YDISTANCE, py + ys[n]);
        }
      SetPanelBodyVisibility(chart, bodyVis);
     }

   bool IsPointInsideAiMinButton(const int mouseX, const int mouseY) const
     {
      const int btnX = m_panel_x + GM_P11E_PANEL_W - 30;
      const int btnY = m_panel_y + 4;
      return (mouseX >= btnX && mouseX <= btnX + GM_P11E_PANEL_BTN_W &&
              mouseY >= btnY && mouseY <= btnY + GM_P11E_PANEL_BTN_H);
     }

   bool IsPointInsideAiHeader(const int mouseX, const int mouseY) const
     {
      return (mouseX >= m_panel_x && mouseX <= m_panel_x + GM_P11E_PANEL_W &&
              mouseY >= m_panel_y && mouseY <= m_panel_y + GM_P11E_PANEL_HEADER_H);
     }

   void RefreshPanelValues(void)
     {
      SGmDynamicConfidence s = m_global;
      const long chart = ChartID();
      ObjectSetString(chart, GM_P11E_UI_PREFIX + "V01", OBJPROP_TEXT, DoubleToString(s.overall_ai_confidence, 0));
      ObjectSetString(chart, GM_P11E_UI_PREFIX + "V02", OBJPROP_TEXT,
                      DoubleToString(s.buy_confidence, 0) + " / " + DoubleToString(s.sell_confidence, 0));
      ObjectSetString(chart, GM_P11E_UI_PREFIX + "V03", OBJPROP_TEXT,
                      DoubleToString(s.decision_confidence, 0) + " (" + GmP11EBandName(s.band) + ")");
      ObjectSetString(chart, GM_P11E_UI_PREFIX + "V04", OBJPROP_TEXT,
                      DoubleToString(s.trend_strength, 0) + " / " + DoubleToString(s.momentum_strength, 0));
      ObjectSetString(chart, GM_P11E_UI_PREFIX + "V05", OBJPROP_TEXT,
                      DoubleToString(s.liquidity_score, 0) + " / " + DoubleToString(s.spread_health, 0));
      ObjectSetString(chart, GM_P11E_UI_PREFIX + "V06", OBJPROP_TEXT,
                      DoubleToString(s.volatility_score, 0) + " / " + DoubleToString(s.news_risk, 0));
      ObjectSetString(chart, GM_P11E_UI_PREFIX + "V07", OBJPROP_TEXT, s.recommendation);
      ObjectSetString(chart, GM_P11E_UI_PREFIX + "V08", OBJPROP_TEXT, DoubleToString(s.original_lot, 2));
      ObjectSetString(chart, GM_P11E_UI_PREFIX + "V09", OBJPROP_TEXT,
                      DoubleToString(s.current_lot, 2) + " / " + DoubleToString(s.target_lot, 2));
      ObjectSetString(chart, GM_P11E_UI_PREFIX + "V10", OBJPROP_TEXT,
                      IntegerToString(m_frozen_session) + " / " + IntegerToString(m_cancelled_session) + " / " + IntegerToString(m_lot_modify_session));
      string health = (s.health == GM_P11E_HEALTH_OK) ? "OK" : "DISABLED";
      ObjectSetString(chart, GM_P11E_UI_PREFIX + "V11", OBJPROP_TEXT, health + " | " + GmP11EStateName(s.pending_state));
      ObjectSetString(chart, GM_P11E_UI_PREFIX + "V12", OBJPROP_TEXT, s.market_condition);

      string why = s.why;
      if(StringLen(why) > 140) why = StringSubstr(why, 0, 137) + "...";
      ObjectSetString(chart, GM_P11E_UI_PREFIX + "Why", OBJPROP_TEXT, "WHY: " + why);
      string ev = s.market_evidence;
      if(StringLen(ev) > 140) ev = StringSubstr(ev, 0, 137) + "...";
      ObjectSetString(chart, GM_P11E_UI_PREFIX + "Ev", OBJPROP_TEXT, "EVIDENCE: " + ev);
     }

public:
                     CPhase11EDynamicExecutionEngine(void)
     {
      m_magic = 0;
      m_max_lot_cap = 5.0;
      m_atr_handle = INVALID_HANDLE;
      m_rsi_handle = INVALID_HANDLE;
      m_enabled = true;
      m_supervisor_active = true;
      m_dynamic_lot = true;
      m_last_ok_analysis = 0;
      m_last_schedule = 0;
      m_last_tick_ms = 0;
      m_max_lot_increase_pct = GM_P11E_DEF_MAX_LOT_INCREASE_PCT;
      m_max_lot_reduce_pct = GM_P11E_DEF_MAX_LOT_REDUCE_PCT;
      m_max_freeze_min = GM_P11E_DEF_MAX_FREEZE_MIN;
      m_emergency_cancel = GM_P11E_DEF_EMERGENCY_CANCEL;
      m_news_protection = GM_P11E_DEF_NEWS_PROTECTION;
      m_broker_protection = GM_P11E_DEF_BROKER_PROTECTION;
      m_weekend_protection = GM_P11E_DEF_WEEKEND_PROTECTION;
      m_min_lot = 0.0;
      m_orig_count = 0;
      m_cancelled_session = 0;
      m_frozen_session = 0;
      m_lot_modify_session = 0;
      m_last_spread_pts = 0.0;
      m_last_atr = 0.0;
      m_broker_fail_streak = 0;
      m_panel_init = 0;
      m_panel_x = 15;
      m_panel_y = 350;
      m_panel_minimized = false;
      m_panel_dragging = false;
      m_panel_drag_ox = 0;
      m_panel_drag_oy = 0;
      m_panel_pos_ready = false;
      m_tick_idx = 0;
      m_global.Reset();
      for(int i = 0; i < GM_P11E_MAX_TRACKED; i++)
        {
         m_tracked[i].Reset();
         m_orig_comment_key[i] = "";
         m_orig_lot_by_comment_key[i] = 0.0;
        }
      for(int j = 0; j < 8; j++) m_tick_buf[j] = 0.0;
     }

                    ~CPhase11EDynamicExecutionEngine(void)
     {
      if(m_rsi_handle != INVALID_HANDLE)
        {
         IndicatorRelease(m_rsi_handle);
         m_rsi_handle = INVALID_HANDLE;
        }
     }

   void Configure(const ulong magic, const double maxLotCap, const int atrHandle,
                  const double maxIncreasePct, const double maxReducePct, const int maxFreezeMin,
                  const bool emergencyCancel, const bool newsProt, const bool brokerProt, const bool weekendProt,
                  const bool enabled, const bool dynamicLot = true)
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
      m_dynamic_lot = dynamicLot;
      m_supervisor_active = enabled;
      m_trade.SetExpertMagicNumber(m_magic);
      m_min_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
      if(m_rsi_handle == INVALID_HANDLE)
         m_rsi_handle = iRSI(_Symbol, PERIOD_H4, 14, PRICE_CLOSE);
      if(m_enabled)
         PrintFormat("TGM [P11E]: Dynamic AI Pre-Activation Engine ACTIVE | %s | continuous tick+schedule monitor", GM_P11E_VERSION);
     }

   bool IsEnabled(void) const { return m_enabled; }
   bool IsSupervisorActive(void) const { return m_supervisor_active && m_enabled; }
   SGmDynamicConfidence GlobalSnapshot(void) const { return m_global; }

   double AdjustLotForPlacement(const double engineLots, const int levelIndex, const string comment, const bool isBuy)
     {
      if(!IsSupervisorActive())
         return engineLots;

      RememberOriginalLot(comment, engineLots);
      SGmDynamicConfidence s = AnalyzeMarket(0, comment, levelIndex, isBuy);
      s.original_lot = engineLots;
      s.action = DecideAction(s.band);
      s.recommendation = GmP11EActionName(s.action);
      BuildWhy(s);
      const double target = TargetLotFromAction(engineLots, s.action);
      s.current_lot = target;
      s.target_lot = target;
      s.lot_multiplier = (engineLots > 0.0) ? (target / engineLots) : 1.0;
      m_global = s;
      m_last_ok_analysis = TimeCurrent();

      if(s.action == GM_P11E_ACT_FREEZE || s.action == GM_P11E_ACT_CANCEL)
         return engineLots; // AllowPlacement / monitor handles block/freeze

      LearnDecision("LOT_ADJUST_PLACE", s.decision_confidence, s.decision_confidence, engineLots, target, s.market_evidence, s.why);
      return target;
     }

   bool AllowPlacement(const string comment, const int levelIndex)
     {
      if(!IsSupervisorActive())
         return true;
      // Side unknown at allow gate — use overall then refine later
      SGmDynamicConfidence s = AnalyzeMarket(0, comment, levelIndex, true);
      // Also compute sell and pick worse risk for gate
      SGmDynamicConfidence sSell = AnalyzeMarket(0, comment, levelIndex, false);
      if(sSell.decision_confidence < s.decision_confidence)
         s = sSell;
      BuildWhy(s);
      m_global = s;
      m_last_ok_analysis = TimeCurrent();
      if(s.action == GM_P11E_ACT_CANCEL)
        {
         LearnDecision("BLOCK_CANCEL_BAND", s.decision_confidence, s.decision_confidence, 0, 0, s.market_evidence, s.why);
         return false;
        }
      return true;
     }

   void RegisterPlacedOrder(const ulong ticket, const string comment, const int levelIndex)
     {
      if(ticket == 0 || !IsSupervisorActive())
         return;
      if(!OrderSelect(ticket))
         return;

      const ENUM_ORDER_TYPE ot = (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
      if(ot == ORDER_TYPE_BUY || ot == ORDER_TYPE_SELL)
         return;

      const int slot = AllocTrackedSlot();
      if(slot < 0) return;

      SGmTrackedPending t;
      t.Reset();
      t.used = true;
      t.ticket = ticket;
      t.comment = comment;
      t.level_index = levelIndex;
      t.order_type = ot;
      t.is_buy_side = IsBuyOrderType(ot);
      t.frozen_price = OrderGetDouble(ORDER_PRICE_OPEN);
      t.frozen_sl = OrderGetDouble(ORDER_SL);
      t.frozen_tp = OrderGetDouble(ORDER_TP);
      t.current_lot = OrderGetDouble(ORDER_VOLUME_CURRENT);
      t.original_lot = LookupOriginalLot(comment, t.current_lot);
      t.last_target_lot = t.current_lot;
      t.state = GM_P11E_STATE_LIVE;
      t.placed_at = TimeCurrent();
      t.last_eval_at = TimeCurrent();

      SGmDynamicConfidence s = AnalyzeMarket(ticket, comment, levelIndex, t.is_buy_side);
      s.original_lot = t.original_lot;
      s.current_lot = t.current_lot;
      s.target_lot = t.current_lot;
      BuildWhy(s);
      t.last_decision_confidence = s.decision_confidence;
      t.last_overall_confidence = s.overall_ai_confidence;
      t.last_action = s.action;
      t.last_why = s.why;
      m_tracked[slot] = t;
      m_global = s;
      m_last_ok_analysis = TimeCurrent();
      LearnDecision("TRACK_PENDING", s.decision_confidence, s.decision_confidence,
                    t.original_lot, t.current_lot, s.market_evidence,
                    StringFormat("track %s price=%.5f SL=%.5f TP=%.5f", comment, t.frozen_price, t.frozen_sl, t.frozen_tp));
     }

   void OnPositionActivated(const ulong posId)
     {
      // Map activation to tracked pending by comment when possible; never manage active trades.
      string posComment = "";
      if(posId > 0 && PositionSelectByTicket(posId))
         posComment = PositionGetString(POSITION_COMMENT);

      int marked = 0;
      for(int j = 0; j < GM_P11E_MAX_TRACKED; j++)
        {
         if(!m_tracked[j].used) continue;
         if(m_tracked[j].activated_readonly) continue;
         if(m_tracked[j].state != GM_P11E_STATE_LIVE && m_tracked[j].state != GM_P11E_STATE_EXPIRED)
            continue;

         bool match = false;
         if(StringLen(posComment) > 0 &&
            (m_tracked[j].comment == posComment || StringFind(posComment, m_tracked[j].comment) == 0))
            match = true;
         else if(m_tracked[j].state == GM_P11E_STATE_LIVE &&
                 (m_tracked[j].ticket == 0 || !OrderSelect(m_tracked[j].ticket)))
            match = true; // pending ticket disappeared coincident with activation

         if(!match) continue;

         m_tracked[j].state = GM_P11E_STATE_ACTIVATED_READONLY;
         m_tracked[j].activated_readonly = true;
         m_tracked[j].last_action = GM_P11E_ACT_READONLY;
         marked++;
        }

      // Panel: only force global READ ONLY when no LIVE pendings remain under supervision
      int liveLeft = 0;
      for(int k = 0; k < GM_P11E_MAX_TRACKED; k++)
        {
         if(m_tracked[k].used && m_tracked[k].state == GM_P11E_STATE_LIVE)
            liveLeft++;
        }

      if(liveLeft == 0)
        {
         m_global.recommendation = "READ ONLY";
         m_global.action = GM_P11E_ACT_READONLY;
         m_global.pending_state = GM_P11E_STATE_ACTIVATED_READONLY;
         m_global.why = "Pending activated — AI authority ENDED for filled orders. Trading Engine 100% control.";
        }
      else
        {
         m_global.why = StringFormat("Activation mapped (%d). %d pending(s) still supervised pre-activation.", marked, liveLeft);
        }

      LearnDecision("ACTIVATED_READONLY", m_global.decision_confidence, m_global.decision_confidence,
                    m_global.current_lot, m_global.current_lot, m_global.market_evidence,
                    StringFormat("pos=%s comment=%s marked=%d liveLeft=%d",
                                 IntegerToString((long)posId), posComment, marked, liveLeft));
     }

   void OnTickMonitor(void)
     {
      if(!m_enabled) return;

      const ulong nowMs = GetTickCount();
      const bool tickDue = (nowMs - m_last_tick_ms >= GM_P11E_THROTTLE_MS);
      const bool scheduleDue = (m_last_schedule == 0 || (TimeCurrent() - m_last_schedule) >= GM_P11E_SCHEDULE_SEC);
      if(!tickDue && !scheduleDue) return;
      if(tickDue) m_last_tick_ms = nowMs;
      if(scheduleDue) m_last_schedule = TimeCurrent();

      if(m_supervisor_active && m_last_ok_analysis > 0 &&
         (TimeCurrent() - m_last_ok_analysis) > GM_P11E_FAILSAFE_TIMEOUT_SEC)
        {
         DisableSupervisor("analysis timeout");
         return;
        }
      if(!IsSupervisorActive()) return;

      // Discover untracked Engine pendings (e.g. placed when AI was briefly off)
      for(int i = OrdersTotal() - 1; i >= 0; i--)
        {
         const ulong ticket = OrderGetTicket(i);
         if(ticket == 0 || !OrderSelect(ticket)) continue;
         if(OrderGetString(ORDER_SYMBOL) != _Symbol) continue;
         if((long)OrderGetInteger(ORDER_MAGIC) != (long)m_magic) continue;
         const ENUM_ORDER_TYPE ot = (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
         if(ot == ORDER_TYPE_BUY || ot == ORDER_TYPE_SELL) continue;
         if(FindTrackedByTicket(ticket) >= 0) continue;
         const string comment = OrderGetString(ORDER_COMMENT);
         if(FindTrackedByCommentLive(comment) >= 0) continue;
         RegisterPlacedOrder(ticket, comment, 0);
        }

      for(int t = 0; t < GM_P11E_MAX_TRACKED; t++)
         EvaluateTracked(t, scheduleDue);

      // Keep global confidence fresh even with no pendings
      if(OrdersTotal() == 0)
        {
         SGmDynamicConfidence s = AnalyzeMarket(0, "", 0, true);
         BuildWhy(s);
         m_global = s;
         m_last_ok_analysis = TimeCurrent();
        }
     }

   void InitPanel(const int x, const int y)
     {
      m_panel_x = x;
      m_panel_y = y;
      m_panel_pos_ready = true;
      m_panel_minimized = false;
      m_panel_init = TimeCurrent();

      const color gold = C'198,168,86';
      const color lbl = C'160,150,120';
      const color val = clrWhite;
      const long chart = ChartID();

      EnsurePanelObject("BG", OBJ_RECTANGLE_LABEL, x, y, "", C'12,10,8', 8);
      ObjectSetInteger(chart, GM_P11E_UI_PREFIX + "BG", OBJPROP_XSIZE, GM_P11E_PANEL_W);
      ObjectSetInteger(chart, GM_P11E_UI_PREFIX + "BG", OBJPROP_YSIZE, GM_P11E_PANEL_H);
      ObjectSetInteger(chart, GM_P11E_UI_PREFIX + "BG", OBJPROP_BGCOLOR, C'12,10,8');
      ObjectSetInteger(chart, GM_P11E_UI_PREFIX + "BG", OBJPROP_BORDER_COLOR, gold);
      ObjectSetInteger(chart, GM_P11E_UI_PREFIX + "BG", OBJPROP_BACK, false);
      ObjectSetInteger(chart, GM_P11E_UI_PREFIX + "BG", OBJPROP_ZORDER, 20);

      EnsurePanelObject("Header", OBJ_RECTANGLE_LABEL, x, y, "", C'38,32,18', 8);
      ObjectSetInteger(chart, GM_P11E_UI_PREFIX + "Header", OBJPROP_XSIZE, GM_P11E_PANEL_W);
      ObjectSetInteger(chart, GM_P11E_UI_PREFIX + "Header", OBJPROP_YSIZE, GM_P11E_PANEL_HEADER_H);
      ObjectSetInteger(chart, GM_P11E_UI_PREFIX + "Header", OBJPROP_BGCOLOR, C'38,32,18');
      ObjectSetInteger(chart, GM_P11E_UI_PREFIX + "Header", OBJPROP_BORDER_COLOR, C'38,32,18');
      ObjectSetInteger(chart, GM_P11E_UI_PREFIX + "Header", OBJPROP_BACK, false);
      ObjectSetInteger(chart, GM_P11E_UI_PREFIX + "Header", OBJPROP_ZORDER, 21);

      EnsurePanelObject("Title", OBJ_LABEL, x + 8, y + 6, "AI DYNAMIC EXEC ENGINE 11E", gold, 9);
      ObjectSetInteger(chart, GM_P11E_UI_PREFIX + "Title", OBJPROP_ZORDER, 22);

      // Minimize / maximize button (clickable)
      const string btn = GM_P11E_UI_PREFIX + "BtnMin";
      if(ObjectFind(chart, btn) < 0)
        {
         ObjectCreate(chart, btn, OBJ_BUTTON, 0, 0, 0);
         ObjectSetInteger(chart, btn, OBJPROP_CORNER, CORNER_LEFT_UPPER);
         ObjectSetInteger(chart, btn, OBJPROP_SELECTABLE, true);
         ObjectSetInteger(chart, btn, OBJPROP_HIDDEN, true);
        }
      ObjectSetInteger(chart, btn, OBJPROP_XDISTANCE, x + GM_P11E_PANEL_W - 30);
      ObjectSetInteger(chart, btn, OBJPROP_YDISTANCE, y + 6);
      ObjectSetInteger(chart, btn, OBJPROP_XSIZE, GM_P11E_PANEL_BTN_W);
      ObjectSetInteger(chart, btn, OBJPROP_YSIZE, GM_P11E_PANEL_BTN_H);
      ObjectSetString(chart, btn, OBJPROP_TEXT, "[-]");
      ObjectSetInteger(chart, btn, OBJPROP_COLOR, clrSilver);
      ObjectSetInteger(chart, btn, OBJPROP_BGCOLOR, C'28,24,16');
      ObjectSetInteger(chart, btn, OBJPROP_BORDER_COLOR, gold);
      ObjectSetInteger(chart, btn, OBJPROP_FONTSIZE, 9);
      ObjectSetInteger(chart, btn, OBJPROP_ZORDER, 23);

      EnsurePanelObject("L01", OBJ_LABEL, x + 8, y + 36, "Overall Confidence:", lbl, 8);
      EnsurePanelObject("V01", OBJ_LABEL, x + 150, y + 36, "---", val, 8);
      EnsurePanelObject("L02", OBJ_LABEL, x + 8, y + 52, "BUY / SELL Conf:", lbl, 8);
      EnsurePanelObject("V02", OBJ_LABEL, x + 150, y + 52, "---", val, 8);
      EnsurePanelObject("L03", OBJ_LABEL, x + 8, y + 68, "Decision Conf:", lbl, 8);
      EnsurePanelObject("V03", OBJ_LABEL, x + 150, y + 68, "---", val, 8);
      EnsurePanelObject("L04", OBJ_LABEL, x + 8, y + 84, "Trend / Momentum:", lbl, 8);
      EnsurePanelObject("V04", OBJ_LABEL, x + 150, y + 84, "---", val, 8);
      EnsurePanelObject("L05", OBJ_LABEL, x + 8, y + 100, "Liquidity / Spread:", lbl, 8);
      EnsurePanelObject("V05", OBJ_LABEL, x + 150, y + 100, "---", val, 8);
      EnsurePanelObject("L06", OBJ_LABEL, x + 8, y + 116, "Volatility / News:", lbl, 8);
      EnsurePanelObject("V06", OBJ_LABEL, x + 150, y + 116, "---", val, 8);
      EnsurePanelObject("L07", OBJ_LABEL, x + 8, y + 132, "Recommendation:", lbl, 8);
      EnsurePanelObject("V07", OBJ_LABEL, x + 150, y + 132, "---", gold, 8);
      EnsurePanelObject("L08", OBJ_LABEL, x + 8, y + 148, "Original Lot:", lbl, 8);
      EnsurePanelObject("V08", OBJ_LABEL, x + 150, y + 148, "---", val, 8);
      EnsurePanelObject("L09", OBJ_LABEL, x + 8, y + 164, "Current / Target Lot:", lbl, 8);
      EnsurePanelObject("V09", OBJ_LABEL, x + 150, y + 164, "---", val, 8);
      EnsurePanelObject("L10", OBJ_LABEL, x + 8, y + 180, "Frozen / Cancel / Mods:", lbl, 8);
      EnsurePanelObject("V10", OBJ_LABEL, x + 150, y + 180, "---", val, 8);
      EnsurePanelObject("L11", OBJ_LABEL, x + 8, y + 196, "AI Health / State:", lbl, 8);
      EnsurePanelObject("V11", OBJ_LABEL, x + 150, y + 196, "---", val, 8);
      EnsurePanelObject("L12", OBJ_LABEL, x + 8, y + 212, "Market Condition:", lbl, 8);
      EnsurePanelObject("V12", OBJ_LABEL, x + 150, y + 212, "---", val, 8);
      EnsurePanelObject("Why", OBJ_LABEL, x + 8, y + 232, "WHY: —", C'140,200,160', 7);
      EnsurePanelObject("Ev", OBJ_LABEL, x + 8, y + 260, "EVIDENCE: —", C'120,160,200', 7);

      RenderPanelLayout();
     }

   void UpdatePanel(const int x, const int y)
     {
      // Independent position: seed once under main dashboard, then keep own X/Y (movable).
      if(!m_panel_pos_ready || m_panel_init == 0)
         InitPanel(x, y + 310);
      else
         RenderPanelLayout();

      RefreshPanelValues();
     }

   // Returns true when event was consumed (EA should skip main-panel handling).
   bool OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
     {
      if(!m_enabled || m_panel_init == 0)
         return false;

      const long chart = ChartID();
      const string btnMinName = GM_P11E_UI_PREFIX + "BtnMin";

      if(id == CHARTEVENT_OBJECT_CLICK)
        {
         if(sparam == btnMinName)
           {
            ObjectSetInteger(chart, btnMinName, OBJPROP_STATE, false);
            m_panel_minimized = !m_panel_minimized;
            RenderPanelLayout();
            RefreshPanelValues();
            ChartRedraw(chart);
            return true;
           }
         return false;
        }

      if(id == CHARTEVENT_MOUSE_MOVE)
        {
         const int mouseX = (int)lparam;
         const int mouseY = (int)dparam;
         const int mouseState = (sparam == "" ? 0 : (int)StringToInteger(sparam));
         const bool leftButtonDown = ((mouseState & 1) == 1);

         if(leftButtonDown)
           {
            if(!m_panel_dragging)
              {
               if(IsPointInsideAiHeader(mouseX, mouseY) && !IsPointInsideAiMinButton(mouseX, mouseY))
                 {
                  m_panel_dragging = true;
                  m_panel_drag_ox = mouseX - m_panel_x;
                  m_panel_drag_oy = mouseY - m_panel_y;
                  ChartSetInteger(chart, CHART_MOUSE_SCROLL, false);
                  return true;
                 }
               return false;
              }

            m_panel_x = mouseX - m_panel_drag_ox;
            m_panel_y = mouseY - m_panel_drag_oy;
            if(m_panel_x < 0) m_panel_x = 0;
            if(m_panel_y < 0) m_panel_y = 0;
            RenderPanelLayout();
            return true;
           }

         if(m_panel_dragging)
           {
            m_panel_dragging = false;
            ChartSetInteger(chart, CHART_MOUSE_SCROLL, true);
            ChartRedraw(chart);
            return true;
           }
        }

      return false;
     }

   void DestroyPanel(void)
     {
      const long chart = ChartID();
      for(int i = ObjectsTotal(chart, 0, -1) - 1; i >= 0; i--)
        {
         const string name = ObjectName(chart, i, 0, -1);
         if(StringFind(name, GM_P11E_UI_PREFIX) == 0)
            ObjectDelete(chart, name);
        }
      m_panel_init = 0;
      m_panel_pos_ready = false;
      m_panel_dragging = false;
      if(m_rsi_handle != INVALID_HANDLE)
        {
         IndicatorRelease(m_rsi_handle);
         m_rsi_handle = INVALID_HANDLE;
        }
     }
  };

#endif // GM_CPHASE11E_DYNAMIC_EXECUTION_ENGINE_MQH
//+------------------------------------------------------------------+
