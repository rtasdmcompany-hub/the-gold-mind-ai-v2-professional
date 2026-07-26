//+------------------------------------------------------------------+
//|                                    CEtjPsychologyAnalyzer.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CETJ_PSYCHOLOGY_ANALYZER_MQH
#define GM_CETJ_PSYCHOLOGY_ANALYZER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "CEtjJournalEngine.mqh"
#include "SGmTradeJournalPlatformResult.mqh"
#include "../Logging/CLogger.mqh"

class CGmEtjPsychologyAnalyzer
  {
private:
   CGmLogger *m_logger;

   double Clamp100(const double v) const
     {
      if(v < 0.0) return 0.0;
      if(v > 100.0) return 100.0;
      return v;
     }

public:
                     CGmEtjPsychologyAnalyzer(void) : m_logger(NULL) {}

   void Init(CGmLogger *logger) { m_logger = logger; }

   void Analyze(CGmEtjJournalEngine *journal, SGmTradeJournalPlatformResult &out)
     {
      out.execution_score = 70.0;
      out.discipline_score = 70.0;
      out.compliance_score = 70.0;

      if(journal == NULL || journal.Count() == 0)
        {
         out.execution_score = 50.0;
         out.discipline_score = 50.0;
         out.compliance_score = 50.0;
         return;
        }

      int n = 0, with_sl = 0, with_tp = 0, be_n = 0, partial_n = 0;
      int closed = 0, timed_ok = 0;
      double lot_sum = 0.0, lot_sq = 0.0;

      SGmEtjTradeRecord r;
      for(int i = 0; i < journal.Count(); i++)
        {
         if(!journal.GetAt(i, r))
            continue;
         n++;
         lot_sum += r.lot_size;
         lot_sq += r.lot_size * r.lot_size;
         if(r.stop_loss > 0.0) with_sl++;
         if(r.take_profit > 0.0) with_tp++;
         if(r.break_even) be_n++;
         if(r.partial_close) partial_n++;
         if(r.status == GM_ETJ_ST_CLOSED)
           {
            closed++;
            // H4-aligned open (within first 30 min of H4 candle) scores timing
            const int offset = (int)(r.open_time % (4 * PeriodSeconds(PERIOD_H1)));
            if(offset <= 1800)
               timed_ok++;
           }
        }

      const double sl_rate = (n > 0) ? (100.0 * (double)with_sl / (double)n) : 0.0;
      const double tp_rate = (n > 0) ? (100.0 * (double)with_tp / (double)n) : 0.0;
      const double mean_lot = (n > 0) ? (lot_sum / (double)n) : 0.0;
      const double var_lot = (n > 1)
         ? ((lot_sq - (lot_sum * lot_sum / (double)n)) / (double)(n - 1)) : 0.0;
      const double cv = (mean_lot > 0.0) ? (MathSqrt(MathMax(0.0, var_lot)) / mean_lot) : 0.0;

      // Execution consistency — SL/TP presence + timing
      const double timing = (closed > 0) ? (100.0 * (double)timed_ok / (double)closed) : 70.0;
      out.execution_score = Clamp100(0.4 * sl_rate + 0.3 * tp_rate + 0.3 * timing);

      // Risk consistency — lower lot CV = higher discipline
      const double risk_consistency = Clamp100(100.0 - cv * 100.0);
      const double be_rate = (n > 0) ? (100.0 * (double)be_n / (double)n) : 0.0;
      out.discipline_score = Clamp100(0.55 * risk_consistency + 0.25 * be_rate + 0.20 * sl_rate);

      // Strategy compliance — SL+TP+lifecycle management presence
      const double mgmt = (n > 0)
         ? (100.0 * (double)(be_n + partial_n) / (double)(n * 2)) : 0.0;
      out.compliance_score = Clamp100(0.45 * sl_rate + 0.35 * tp_rate + 0.20 * mgmt);

      if(m_logger != NULL)
         m_logger.Info(StringFormat("Performance Calculated | Exec=%.0f Disc=%.0f Comp=%.0f",
                                    out.execution_score, out.discipline_score,
                                    out.compliance_score), "ETJ");
     }
  };

#endif // GM_CETJ_PSYCHOLOGY_ANALYZER_MQH
//+------------------------------------------------------------------+
