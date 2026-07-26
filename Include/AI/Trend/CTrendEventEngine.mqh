//+------------------------------------------------------------------+
//|                                       CTrendEventEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CTREND_EVENT_ENGINE_MQH
#define GM_CTREND_EVENT_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmTrendAnalysisResult.mqh"
#include "../../Logging/CLogger.mqh"

class CGmTrendEventEngine
  {
private:
   CGmLogger *m_logger;
   string     m_events[GM_TREND_EVENT_MAX];
   int        m_n;
   double     m_prev_strength;
   bool       m_ready;

   void Push(const ENUM_GM_TREND_EVENT type, const string detail)
     {
      const string line = StringFormat("%s | %s | %s",
                                       TimeToString(TimeCurrent(), TIME_SECONDS),
                                       GmTrendEventName(type), detail);
      if(m_n < GM_TREND_EVENT_MAX)
         m_events[m_n++] = line;
      else
        {
         for(int i = 1; i < GM_TREND_EVENT_MAX; i++)
            m_events[i - 1] = m_events[i];
         m_events[GM_TREND_EVENT_MAX - 1] = line;
        }
      if(m_logger != NULL)
         m_logger.Info(GmTrendEventName(type) + " | " + detail, "TrendEvent");
     }

public:
                     CGmTrendEventEngine(void)
                       : m_logger(NULL), m_n(0), m_prev_strength(-1.0), m_ready(false) {}

   void Init(CGmLogger *logger)
     {
      m_logger = logger;
      m_n = 0;
      m_prev_strength = -1.0;
      m_ready = true;
     }

   int Count(void) const { return m_n; }
   string At(const int i) const
     {
      return (i >= 0 && i < m_n) ? m_events[i] : "";
     }

   void Evaluate(const SGmTrendAnalysisResult &cur, const SGmTrendAnalysisResult &prev)
     {
      if(!m_ready || !cur.valid)
         return;

      if(!prev.valid)
        {
         Push(GM_TREND_EVT_STARTED, GmTrendDirName(cur.primary));
         m_prev_strength = cur.strength_score;
         return;
        }

      if(prev.primary != cur.primary &&
         cur.primary != GM_TREND_DIR_UNKNOWN &&
         prev.primary != GM_TREND_DIR_UNKNOWN)
         Push(GM_TREND_EVT_REVERSAL,
              StringFormat("%s -> %s", GmTrendDirName(prev.primary), GmTrendDirName(cur.primary)));

      if(m_prev_strength >= 0.0)
        {
         if(cur.strength_score >= m_prev_strength + 8.0)
            Push(GM_TREND_EVT_STRENGTH_UP, StringFormat("%.0f -> %.0f", m_prev_strength, cur.strength_score));
         else if(cur.strength_score <= m_prev_strength - 8.0)
            Push(GM_TREND_EVT_STRENGTH_DOWN, StringFormat("%.0f -> %.0f", m_prev_strength, cur.strength_score));
        }
      m_prev_strength = cur.strength_score;

      if(prev.structure != cur.structure && cur.structure != GM_TREND_STRUCT_NONE)
         Push(GM_TREND_EVT_STRUCTURE, GmTrendStructName(cur.structure));

      if(cur.bos_up || cur.bos_down)
         Push(GM_TREND_EVT_BOS, cur.bos_up ? "BOS Up" : "BOS Down");
      if(cur.choch_up || cur.choch_down)
         Push(GM_TREND_EVT_CHOCH, cur.choch_up ? "CHOCH Up" : "CHOCH Down");
      if(cur.liq_sweep_high || cur.liq_sweep_low)
         Push(GM_TREND_EVT_LIQUIDITY, cur.liq_sweep_high ? "Sweep High" : "Sweep Low");
     }

   string ExportBody(void) const
     {
      string body = "";
      for(int i = 0; i < m_n; i++)
         body += m_events[i] + "\r\n";
      return body;
     }
  };

#endif // GM_CTREND_EVENT_ENGINE_MQH
//+------------------------------------------------------------------+
