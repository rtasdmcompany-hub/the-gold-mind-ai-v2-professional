//+------------------------------------------------------------------+
//|                                             CAIEventEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CAI_EVENT_ENGINE_MQH
#define GM_CAI_EVENT_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmAIEventRecord.mqh"
#include "../Logging/CLogger.mqh"

/// @file CAIEventEngine.mqh
/// @brief AI event infrastructure only — no AI inference logic.

class CGmAIEventEngine
  {
private:
   CGmLogger        *m_logger;
   SGmAIEventRecord  m_items[GM_AI_EVENT_MAX];
   int               m_count;
   int               m_head;
   ulong             m_next_id;

public:
                     CGmAIEventEngine(void)
                       : m_logger(NULL), m_count(0), m_head(0), m_next_id(1)
     {
     }

   void Init(CGmLogger *logger)
     {
      m_logger = logger;
      m_count = 0;
      m_head = 0;
      m_next_id = 1;
     }

   int Count(void) const { return m_count; }

   string TypeName(const ENUM_GM_AI_EVENT_TYPE t) const
     {
      switch(t)
        {
         case GM_AI_EVT_STARTED:             return "AI Started";
         case GM_AI_EVT_STOPPED:             return "AI Stopped";
         case GM_AI_EVT_LEARNING:            return "AI Learning";
         case GM_AI_EVT_PREDICTION:          return "AI Prediction";
         case GM_AI_EVT_RECOMMENDATION:      return "AI Recommendation";
         case GM_AI_EVT_WARNING:             return "AI Warning";
         case GM_AI_EVT_ERROR:               return "AI Error";
         case GM_AI_EVT_CONFIDENCE_UPDATED:  return "AI Confidence Updated";
         case GM_AI_EVT_DATA_UPDATED:        return "AI Data Updated";
         default:                            return "AI Info";
        }
     }

   void Raise(const ENUM_GM_AI_EVENT_TYPE type,
              const string module_name,
              const string description,
              const double confidence,
              const ulong session_id)
     {
      SGmAIEventRecord e;
      e.Reset();
      e.event_id = m_next_id++;
      e.stamped_at = TimeCurrent();
      e.type = type;
      e.module_name = module_name;
      e.description = description;
      e.confidence = confidence;
      e.session_id = session_id;
      e.used = true;

      m_items[m_head] = e;
      m_head = (m_head + 1) % GM_AI_EVENT_MAX;
      if(m_count < GM_AI_EVENT_MAX)
         m_count++;

      if(m_logger != NULL)
        {
         const string msg = StringFormat("%s | %s | %s",
                                         TypeName(type), module_name, description);
         if(type == GM_AI_EVT_ERROR)
            m_logger.Warning(msg, "AIEvents");
         else if(type == GM_AI_EVT_WARNING)
            m_logger.Warning(msg, "AIEvents");
         else
            m_logger.Info(msg, "AIEvents");
        }
     }

   bool GetRecent(const int newest_index, SGmAIEventRecord &out) const
     {
      if(newest_index < 0 || newest_index >= m_count)
         return false;
      int idx = m_head - 1 - newest_index;
      while(idx < 0)
         idx += GM_AI_EVENT_MAX;
      out = m_items[idx];
      return true;
     }
  };

#endif // GM_CAI_EVENT_ENGINE_MQH
//+------------------------------------------------------------------+
