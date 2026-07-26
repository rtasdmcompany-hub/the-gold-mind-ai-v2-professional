//+------------------------------------------------------------------+
//|                                      CLearningEventEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CLEARNING_EVENT_ENGINE_MQH
#define GM_CLEARNING_EVENT_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmLearningAnalysisResult.mqh"
#include "../../Logging/CLogger.mqh"

class CGmLearningEventEngine
  {
private:
   CGmLogger *m_logger;
   string     m_events[GM_LEARN_EVT_MAX];
   int        m_n;
   bool       m_ready;

   void Push(const string label, const string detail)
     {
      const string line = StringFormat("%s | %s | %s",
                                       TimeToString(TimeCurrent(), TIME_SECONDS),
                                       label, detail);
      if(m_n < GM_LEARN_EVT_MAX)
         m_events[m_n++] = line;
      else
        {
         for(int i = 1; i < GM_LEARN_EVT_MAX; i++)
            m_events[i - 1] = m_events[i];
         m_events[GM_LEARN_EVT_MAX - 1] = line;
        }
      if(m_logger != NULL)
         m_logger.Info(label + " | " + detail, "LearnEvent");
     }

public:
                     CGmLearningEventEngine(void)
                       : m_logger(NULL), m_n(0), m_ready(false) {}

   void Init(CGmLogger *logger)
     {
      m_logger = logger;
      m_n = 0;
      m_ready = true;
      Push("Learning Engine Started", GM_LEARN_AI_VERSION + " | " + GM_LEARN_ADVISOR_ONLY);
     }

   void OnStarted(void) { Push("Learning Started", "cycle"); }
   void OnPattern(const string name) { Push("Pattern Detected", name); }
   void OnKnowledge(void) { Push("Knowledge Updated", GM_LEARN_KB_VERSION); }
   void OnAccuracy(const SGmLearningAnalysisResult &r)
     {
      Push("Accuracy Updated",
           StringFormat("pred=%.0f conf=%.0f pat=%.0f reco=%.0f",
                        r.prediction_accuracy, r.confidence_accuracy,
                        r.pattern_accuracy, r.recommendation_accuracy));
     }
   void OnCompleted(const SGmLearningAnalysisResult &r)
     {
      Push("Learning Completed", StringFormat("progress=%.0f xp=%s",
                                              r.learning_progress,
                                              GmLearnXpName(r.experience)));
      Push("Learning Cycle Finished", TimeToString(r.last_cycle_at, TIME_DATE | TIME_SECONDS));
     }
  };

#endif // GM_CLEARNING_EVENT_ENGINE_MQH
//+------------------------------------------------------------------+
