//+------------------------------------------------------------------+
//|                                          CAIDecisionQueue.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CAI_DECISION_QUEUE_MQH
#define GM_CAI_DECISION_QUEUE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "Phase3AIConstants.mqh"

/// @brief Advisory decision record — NEVER executed by Core.
struct SGmAIDecisionItem
  {
   datetime stamped_at;
   string   kind;
   string   reason;
   double   confidence;
   bool     advisory_only;

   void Reset(void)
     {
      stamped_at = 0;
      kind = "";
      reason = "";
      confidence = 0.0;
      advisory_only = true;
     }
  };

class CGmAIDecisionQueue
  {
private:
   SGmAIDecisionItem m_q[GM_AI_CORE_QUEUE_MAX];
   int               m_n;
   int               m_head;
   bool              m_ready;

public:
                     CGmAIDecisionQueue(void) : m_n(0), m_head(0), m_ready(false) {}

   void Init(void)
     {
      m_n = 0;
      m_head = 0;
      for(int i = 0; i < GM_AI_CORE_QUEUE_MAX; i++)
         m_q[i].Reset();
      m_ready = true;
     }

   bool IsReady(void) const { return m_ready; }
   int Count(void) const { return m_n; }

   void Enqueue(const string kind, const string reason, const double confidence)
     {
      if(!m_ready)
         return;
      SGmAIDecisionItem item;
      item.Reset();
      item.stamped_at = TimeCurrent();
      item.kind = kind;
      item.reason = reason;
      item.confidence = confidence;
      item.advisory_only = true; // immutable Phase 3 rule
      m_q[m_head] = item;
      m_head = (m_head + 1) % GM_AI_CORE_QUEUE_MAX;
      if(m_n < GM_AI_CORE_QUEUE_MAX)
         m_n++;
     }

   bool PeekLatest(SGmAIDecisionItem &out) const
     {
      out.Reset();
      if(!m_ready || m_n <= 0)
         return false;
      int idx = m_head - 1;
      if(idx < 0)
         idx += GM_AI_CORE_QUEUE_MAX;
      out = m_q[idx];
      return true;
     }
  };

#endif // GM_CAI_DECISION_QUEUE_MQH
//+------------------------------------------------------------------+
