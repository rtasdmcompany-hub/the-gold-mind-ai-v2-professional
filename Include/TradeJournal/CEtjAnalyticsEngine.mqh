//+------------------------------------------------------------------+
//|                                       CEtjAnalyticsEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CETJ_ANALYTICS_ENGINE_MQH
#define GM_CETJ_ANALYTICS_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "CEtjJournalEngine.mqh"
#include "SGmTradeJournalPlatformResult.mqh"
#include "../Logging/CLogger.mqh"

class CGmEtjAnalyticsEngine
  {
private:
   CGmLogger *m_logger;

   double Clamp(const double v, const double lo, const double hi) const
     {
      if(v < lo) return lo;
      if(v > hi) return hi;
      return v;
     }

public:
                     CGmEtjAnalyticsEngine(void) : m_logger(NULL) {}

   void Init(CGmLogger *logger) { m_logger = logger; }

   void Calculate(CGmEtjJournalEngine *journal, SGmTradeJournalPlatformResult &out)
     {
      out.win_rate = out.loss_rate = 0.0;
      out.avg_win = out.avg_loss = out.expectancy = 0.0;
      out.profit_factor = out.recovery_rate = 0.0;
      out.avg_holding_sec = out.avg_atr = 0.0;
      out.max_consec_wins = out.max_consec_losses = 0;
      out.best_session = out.worst_session = "—";
      out.weekly_pnl = out.monthly_pnl = out.today_pnl = 0.0;
      out.analytics_summary = "No closed trades";

      if(journal == NULL)
         return;

      int wins = 0, losses = 0, closed = 0, recovery_n = 0, recovery_ok = 0;
      double sum_win = 0.0, sum_loss = 0.0, sum_hold = 0.0, sum_atr = 0.0;
      double gross_profit = 0.0, gross_loss = 0.0;
      int cur_w = 0, cur_l = 0, max_w = 0, max_l = 0;

      // Session aggregates
      double sess_pnl[4];
      int sess_n[4];
      string sess_name[4];
      sess_name[0] = "Asia"; sess_name[1] = "London";
      sess_name[2] = "NewYork"; sess_name[3] = "Overlap";
      for(int s = 0; s < 4; s++) { sess_pnl[s] = 0.0; sess_n[s] = 0; }

      MqlDateTime now;
      TimeToStruct(TimeCurrent(), now);
      const datetime week_ago = TimeCurrent() - 7 * 86400;
      const datetime month_ago = TimeCurrent() - 30 * 86400;

      SGmEtjTradeRecord r;
      for(int i = 0; i < journal.Count(); i++)
        {
         if(!journal.GetAt(i, r))
            continue;

         // Period PnL includes open floating
         MqlDateTime ot;
         TimeToStruct(r.open_time, ot);
         if(ot.year == now.year && ot.mon == now.mon && ot.day == now.day)
            out.today_pnl += r.profit_loss;
         if(r.open_time >= week_ago)
            out.weekly_pnl += r.profit_loss;
         if(r.open_time >= month_ago)
            out.monthly_pnl += r.profit_loss;

         if(r.status != GM_ETJ_ST_CLOSED)
            continue;

         closed++;
         sum_hold += (double)r.duration_sec;
         sum_atr += r.atr_value;

         int si = 3;
         if(r.market_session == "Asia") si = 0;
         else if(r.market_session == "London") si = 1;
         else if(r.market_session == "NewYork") si = 2;
         sess_pnl[si] += r.profit_loss;
         sess_n[si]++;

         if(StringFind(r.recovery_status, "None") < 0 && StringLen(r.recovery_status) > 0)
           {
            recovery_n++;
            if(r.profit_loss >= 0.0)
               recovery_ok++;
           }

         if(r.profit_loss >= 0.0)
           {
            wins++;
            sum_win += r.profit_loss;
            gross_profit += r.profit_loss;
            cur_w++; cur_l = 0;
            if(cur_w > max_w) max_w = cur_w;
           }
         else
           {
            losses++;
            sum_loss += r.profit_loss;
            gross_loss += MathAbs(r.profit_loss);
            cur_l++; cur_w = 0;
            if(cur_l > max_l) max_l = cur_l;
           }
        }

      if(closed > 0)
        {
         out.win_rate = 100.0 * (double)wins / (double)closed;
         out.loss_rate = 100.0 * (double)losses / (double)closed;
         out.avg_win = (wins > 0) ? (sum_win / (double)wins) : 0.0;
         out.avg_loss = (losses > 0) ? (sum_loss / (double)losses) : 0.0;
         const double pw = (double)wins / (double)closed;
         const double pl = (double)losses / (double)closed;
         out.expectancy = pw * out.avg_win + pl * out.avg_loss;
         out.profit_factor = (gross_loss > 0.0) ? (gross_profit / gross_loss)
                            : ((gross_profit > 0.0) ? 99.0 : 0.0);
         out.avg_holding_sec = sum_hold / (double)closed;
         out.avg_atr = sum_atr / (double)closed;
         out.max_consec_wins = max_w;
         out.max_consec_losses = max_l;
         out.recovery_rate = (recovery_n > 0)
            ? (100.0 * (double)recovery_ok / (double)recovery_n) : 0.0;

         int best = -1, worst = -1;
         for(int k = 0; k < 4; k++)
           {
            if(sess_n[k] == 0) continue;
            if(best < 0 || sess_pnl[k] > sess_pnl[best]) best = k;
            if(worst < 0 || sess_pnl[k] < sess_pnl[worst]) worst = k;
           }
         if(best >= 0) out.best_session = sess_name[best];
         if(worst >= 0) out.worst_session = sess_name[worst];

         out.analytics_summary = StringFormat(
            "Closed=%d WR=%.1f%% PF=%.2f Exp=%.2f Hold=%.0fs",
            closed, out.win_rate, out.profit_factor, out.expectancy, out.avg_holding_sec);
        }

      if(m_logger != NULL)
         m_logger.Info("Analytics Updated | " + out.analytics_summary, "ETJ");
     }
  };

#endif // GM_CETJ_ANALYTICS_ENGINE_MQH
//+------------------------------------------------------------------+
