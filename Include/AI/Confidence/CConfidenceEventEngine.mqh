//+------------------------------------------------------------------+
//|                                    CConfidenceEventEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CCONFIDENCE_EVENT_ENGINE_MQH
#define GM_CCONFIDENCE_EVENT_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmConfidenceAnalysisResult.mqh"
#include "../../Logging/CLogger.mqh"

class CGmConfidenceEventEngine
  {
private:
   CGmLogger *m_logger;
   string     m_events[GM_CONF_EVT_MAX];
   int        m_n;
   bool       m_ready;

   void Push(const string label, const string detail)
     {
      const string line = StringFormat("%s | %s | %s",
                                       TimeToString(TimeCurrent(), TIME_SECONDS),
                                       label, detail);
      if(m_n < GM_CONF_EVT_MAX)
         m_events[m_n++] = line;
      else
        {
         for(int i = 1; i < GM_CONF_EVT_MAX; i++)
            m_events[i - 1] = m_events[i];
         m_events[GM_CONF_EVT_MAX - 1] = line;
        }
      if(m_logger != NULL)
         m_logger.Info(label + " | " + detail, "ConfEvent");
     }

public:
                     CGmConfidenceEventEngine(void)
                       : m_logger(NULL), m_n(0), m_ready(false) {}

   void Init(CGmLogger *logger)
     {
      m_logger = logger;
      m_n = 0;
      m_ready = true;
      Push("Confidence Engine Started", GM_CONF_AI_VERSION + " | " + GM_CONF_ADVISOR_ONLY);
     }

   int Count(void) const { return m_n; }
   string At(const int i) const
     { return (i >= 0 && i < m_n) ? m_events[i] : ""; }

   void Evaluate(const SGmConfidenceAnalysisResult &cur)
     {
      if(!m_ready || !cur.valid)
         return;
      if(cur.new_h4_cycle)
         Push("H4 Cycle Evaluated", TimeToString(cur.h4_bar_time, TIME_DATE | TIME_MINUTES));
      Push("Confidence Calculated", StringFormat("%.0f", cur.overall_confidence));
      Push("Quality Score Updated", StringFormat("TQ=%.0f MQ=%.0f", cur.trade_quality, cur.market_quality));
      Push("Environment Classified", GmConfEnvName(cur.environment));
      Push("Recommendation Generated", GmConfRecoName(cur.recommendation));
     }
  };

#endif // GM_CCONFIDENCE_EVENT_ENGINE_MQH
//+------------------------------------------------------------------+
