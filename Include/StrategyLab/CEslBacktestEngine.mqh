//+------------------------------------------------------------------+
//|                                        CEslBacktestEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     RESEARCH ONLY — synthetic H4 simulation, no live orders     |
//+------------------------------------------------------------------+
#ifndef GM_CESL_BACKTEST_ENGINE_MQH
#define GM_CESL_BACKTEST_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmStrategyLabResult.mqh"
#include "../Calculation/LevelConstants.mqh"
#include "../Logging/CLogger.mqh"

class CGmEslBacktestEngine
  {
private:
   CGmLogger      *m_logger;
   string          m_symbol;
   SGmEslSimTrade  m_trades[GM_ESL_BARS_MAX];
   int             m_n;
   int             m_bars;
   double          m_health;
   string          m_summary;
   ENUM_GM_ESL_SCENARIO m_scenario;

   double m_atr[];
   bool   m_atr_ok;

   double PointSize(void) const
     {
      const double p = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
      return (p > 0.0) ? p : 0.01;
     }

   double PipSize(void) const
     {
      return PointSize() * 10.0;
     }

   double AtrAt(const int shift) const
     {
      if(m_atr_ok && shift >= 0 && shift < ArraySize(m_atr))
         return MathMax(m_atr[shift], PipSize());
      return PipSize() * 50.0;
     }

   void SimBar(const MqlRates &bar, const MqlRates &prev,
               const ENUM_GM_ESL_SCENARIO sc, const double atr_scale,
               const int atr_shift)
     {
      if(m_n >= GM_ESL_BARS_MAX)
         return;

      const double diff = MathAbs(prev.high - prev.low);
      if(diff <= 0.0)
         return;

      const double atr = AtrAt(atr_shift) * atr_scale;
      const double pip = PipSize();
      const double sl_dist = GM_ESL_REF_SL_PIPS * pip;
      const double tp_dist = atr; // ATR-14 TP reference

      // Simulate BL1 buy level touch
      const double bl1 = prev.low - diff * GM_LEVEL_FRAC_1;
      const double sl1 = prev.high + diff * GM_LEVEL_FRAC_1;

      // Bar simulation: if low pierces buy level → long; if high pierces sell → short
      bool buy_hit = (bar.low <= bl1);
      bool sell_hit = (bar.high >= sl1);

      // Scenario filters
      if(sc == GM_ESL_SC_NEWS && (bar.time % 86400) > 3600 * 16)
        { buy_hit = false; sell_hit = false; } // skip late NY for news filter stub
      if(sc == GM_ESL_SC_SESSION)
        {
         MqlDateTime dt;
         TimeToStruct(bar.time, dt);
         if(dt.hour < 8 || dt.hour >= 21)
           { buy_hit = false; sell_hit = false; }
        }

      if(buy_hit && m_n < GM_ESL_BARS_MAX)
        {
         SGmEslSimTrade t;
         t.open_time = bar.time;
         t.side = 1;
         t.level = 1;
         t.entry = bl1;
         t.sl = bl1 - sl_dist;
         t.tp = bl1 + tp_dist;
         t.atr = atr;
         t.recovery = (sc == GM_ESL_SC_RECOVERY);
         t.scenario = GmEslScenarioName(sc);
         // Outcome: TP before SL approximation via close vs mid
         const bool hit_tp = (bar.high >= t.tp);
         const bool hit_sl = (bar.low <= t.sl);
         if(hit_tp && !hit_sl) { t.win = true; t.pnl_r = 1.0; }
         else if(hit_sl && !hit_tp) { t.win = false; t.pnl_r = -1.0; }
         else if(hit_tp && hit_sl) { t.win = (bar.close > t.entry); t.pnl_r = t.win ? 0.5 : -0.5; }
         else
           {
            t.pnl_r = (bar.close - t.entry) / sl_dist;
            t.win = (t.pnl_r >= 0.0);
           }
         // Partial / BE / trail knowledge applied as expectancy boost when win
         if(t.win)
            t.pnl_r *= (0.8 + 0.2 * 0.5); // 80% partial + 20% trail stub
         m_trades[m_n++] = t;
        }

      if(sell_hit && m_n < GM_ESL_BARS_MAX)
        {
         SGmEslSimTrade t;
         t.open_time = bar.time;
         t.side = -1;
         t.level = 1;
         t.entry = sl1;
         t.sl = sl1 + sl_dist;
         t.tp = sl1 - tp_dist;
         t.atr = atr;
         t.recovery = (sc == GM_ESL_SC_HEDGE || sc == GM_ESL_SC_RECOVERY);
         t.scenario = GmEslScenarioName(sc);
         const bool hit_tp = (bar.low <= t.tp);
         const bool hit_sl = (bar.high >= t.sl);
         if(hit_tp && !hit_sl) { t.win = true; t.pnl_r = 1.0; }
         else if(hit_sl && !hit_tp) { t.win = false; t.pnl_r = -1.0; }
         else if(hit_tp && hit_sl) { t.win = (bar.close < t.entry); t.pnl_r = t.win ? 0.5 : -0.5; }
         else
           {
            t.pnl_r = (t.entry - bar.close) / sl_dist;
            t.win = (t.pnl_r >= 0.0);
           }
         if(t.win)
            t.pnl_r *= (0.8 + 0.2 * 0.5);
         m_trades[m_n++] = t;
        }
     }

public:
                     CGmEslBacktestEngine(void)
                       : m_logger(NULL), m_symbol(""), m_n(0), m_bars(0),
                         m_health(0.0), m_summary(""), m_scenario(GM_ESL_SC_HISTORICAL),
                         m_atr_ok(false) {}

   void Init(CGmLogger *logger, const string symbol)
     {
      m_logger = logger;
      m_symbol = symbol;
      m_n = 0;
      m_bars = 0;
      m_health = 0.0;
      m_summary = "Idle";
      m_atr_ok = false;
     }

   int TradeCount(void) const { return m_n; }
   int BarsCovered(void) const { return m_bars; }
   double Health(void) const { return m_health; }
   string Summary(void) const { return m_summary; }

   bool GetTrade(const int i, SGmEslSimTrade &out) const
     {
      if(i < 0 || i >= m_n) return false;
      out = m_trades[i];
      return true;
     }

   void Run(const ENUM_GM_ESL_SCENARIO sc = GM_ESL_SC_HISTORICAL)
     {
      m_scenario = sc;
      m_n = 0;
      m_bars = 0;

      MqlRates rates[];
      ArraySetAsSeries(rates, true);
      const int copied = CopyRates(m_symbol, PERIOD_H4, 1, GM_ESL_BARS_MAX, rates);
      if(copied < 3)
        {
         m_health = 20.0;
         m_summary = "Backtest Failed | insufficient H4 history";
         if(m_logger != NULL)
            m_logger.Warning(m_summary, "ESL");
         return;
        }

      if(m_logger != NULL)
         m_logger.Info("Backtest Started | " + GmEslScenarioName(sc) +
                       " | bars=" + IntegerToString(copied), "ESL");

      double atr_scale = 1.0;
      if(sc == GM_ESL_SC_HIGH_VOL) atr_scale = 1.6;
      if(sc == GM_ESL_SC_LOW_VOL)  atr_scale = 0.6;

      m_atr_ok = false;
      ArrayResize(m_atr, 0);
      const int h_atr = iATR(m_symbol, PERIOD_H4, GM_ESL_REF_ATR_PERIOD);
      if(h_atr != INVALID_HANDLE)
        {
         ArraySetAsSeries(m_atr, true);
         if(CopyBuffer(h_atr, 0, 1, copied, m_atr) == copied)
            m_atr_ok = true;
         IndicatorRelease(h_atr);
        }

      m_bars = copied;
      for(int i = copied - 2; i >= 0; i--)
         SimBar(rates[i], rates[i + 1], sc, atr_scale, i);

      int wins = 0;
      double sum_r = 0.0;
      for(int t = 0; t < m_n; t++)
        {
         if(m_trades[t].win) wins++;
         sum_r += m_trades[t].pnl_r;
        }
      const double wr = (m_n > 0) ? (100.0 * (double)wins / (double)m_n) : 0.0;
      m_health = MathMin(100.0, 40.0 + wr * 0.4 + MathMin(20.0, (double)m_n * 0.05));
      if(sum_r > 0.0) m_health = MathMin(100.0, m_health + 5.0);

      m_summary = StringFormat(
         "Backtest OK | %s | Bars=%d Trades=%d WR=%.1f%% Health=%.0f | H4+ATR14+SL30+BE/Partial/Trail knowledge",
         GmEslScenarioName(sc), m_bars, m_n, wr, m_health);

      if(m_logger != NULL)
         m_logger.Success("Backtest Completed | " + m_summary, "ESL");
     }
  };

#endif // GM_CESL_BACKTEST_ENGINE_MQH
//+------------------------------------------------------------------+
