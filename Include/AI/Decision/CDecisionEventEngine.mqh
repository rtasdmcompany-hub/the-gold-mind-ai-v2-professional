//+------------------------------------------------------------------+
//|                                       CDecisionEventEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CDECISION_EVENT_ENGINE_MQH
#define GM_CDECISION_EVENT_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmDecisionSupportResult.mqh"
#include "../../Logging/CLogger.mqh"

class CGmDecisionEventEngine
  {
private:
   CGmLogger *m_logger;
   string     m_events[GM_DEC_EVT_MAX];
   int        m_n;

   void Push(const string label, const string detail)
     {
      const string line = StringFormat("%s | %s | %s",
                                       TimeToString(TimeCurrent(), TIME_SECONDS),
                                       label, detail);
      if(m_n < GM_DEC_EVT_MAX)
         m_events[m_n++] = line;
      else
        {
         for(int i = 1; i < GM_DEC_EVT_MAX; i++)
            m_events[i - 1] = m_events[i];
         m_events[GM_DEC_EVT_MAX - 1] = line;
        }
      if(m_logger != NULL)
         m_logger.Info(label + " | " + detail, "DecEvent");
     }

public:
                     CGmDecisionEventEngine(void) : m_logger(NULL), m_n(0) {}

   void Init(CGmLogger *logger)
     {
      m_logger = logger;
      m_n = 0;
      Push("Decision Support Started", GM_DEC_AI_VERSION + " | " + GM_DEC_ADVISORY_ONLY);
     }

   void OnDecision(const SGmDecisionSupportResult &r)
     {
      Push("Decision Generated", GmDecRecoName(r.recommendation) +
           StringFormat(" | conf=%.0f", r.overall_confidence));
     }

   void OnExplanation(void) { Push("Explanation Generated", "XAI"); }
   void OnSimilarity(const double pct)
     { Push("Similarity Search Completed", StringFormat("%.0f%%", pct)); }
   void OnValidation(const ENUM_GM_DEC_STRATEGY_MATCH m)
     { Push("Strategy Validation Completed", GmDecMatchName(m)); }
  };

#endif // GM_CDECISION_EVENT_ENGINE_MQH
//+------------------------------------------------------------------+
