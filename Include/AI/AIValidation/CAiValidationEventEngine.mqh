//+------------------------------------------------------------------+
//|                                    CAiValidationEventEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CAI_VALIDATION_EVENT_ENGINE_MQH
#define GM_CAI_VALIDATION_EVENT_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmAIValidationResult.mqh"
#include "../../Logging/CLogger.mqh"

class CGmAiValidationEventEngine
  {
private:
   CGmLogger *m_logger;
   string     m_events[GM_AIVAL_EVT_MAX];
   int        m_n;

   void Push(const string label, const string detail)
     {
      const string line = StringFormat("%s | %s | %s",
                                       TimeToString(TimeCurrent(), TIME_SECONDS),
                                       label, detail);
      if(m_n < GM_AIVAL_EVT_MAX)
         m_events[m_n++] = line;
      else
        {
         for(int i = 1; i < GM_AIVAL_EVT_MAX; i++)
            m_events[i - 1] = m_events[i];
         m_events[GM_AIVAL_EVT_MAX - 1] = line;
        }
      if(m_logger != NULL)
         m_logger.Info(label + " | " + detail, "AiValEvent");
     }

public:
                     CGmAiValidationEventEngine(void) : m_logger(NULL), m_n(0) {}

   void Init(CGmLogger *logger)
     {
      m_logger = logger;
      m_n = 0;
      Push("AI Validation Engine Started", GM_AIVAL_VERSION + " | " + GM_AIVAL_ANALYSIS_ONLY);
     }

   void OnStarted(void) { Push("Validation Started", "cycle"); }
   void OnCompleted(const SGmAIValidationResult &r)
     {
      Push("Validation Completed", StringFormat("acc=%.0f cert=%.0f", r.ai_accuracy, r.certification_score));
     }
   void OnBacktest(void) { Push("Backtest Completed", "intelligence"); }
   void OnForward(void) { Push("Forward Test Updated", "live"); }
   void OnCert(const double score) { Push("Certification Updated", StringFormat("%.0f", score)); }
   void OnDrift(const string msg) { Push("Drift Detected", msg); }
  };

#endif // GM_CAI_VALIDATION_EVENT_ENGINE_MQH
//+------------------------------------------------------------------+
