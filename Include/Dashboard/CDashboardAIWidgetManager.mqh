//+------------------------------------------------------------------+
//|                              CDashboardAIWidgetManager.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CDASHBOARD_AI_WIDGET_MANAGER_MQH
#define GM_CDASHBOARD_AI_WIDGET_MANAGER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "../AI/SGmAISnapshot.mqh"
#include "../AI/AIConstants.mqh"

/// @file CDashboardAIWidgetManager.mqh
/// @brief Phase 7 certification widgets — Sprint 10 Closure.

class CGmDashboardAIWidgetManager
  {
private:
   SGmAISnapshot m_ai;
   bool          m_have;

public:
                     CGmDashboardAIWidgetManager(void) : m_have(false)
     {
      m_ai.Reset();
     }

   void Apply(const SGmAISnapshot &s)
     {
      m_ai = s;
      m_have = s.valid;
     }

   int PlaceholderCount(void) const { return 14; }

   string LabelAt(const int i) const
     {
      switch(i)
        {
         case 0:  return "Performance Score";
         case 1:  return "Security Score";
         case 2:  return "Reliability Grade";
         case 3:  return "Functional Score";
         case 4:  return "Phase Completion";
         case 5:  return "Modules Pass/Fail";
         case 6:  return "Architecture Freeze";
         case 7:  return "Production Ready";
         case 8:  return "Decision";
         case 9:  return "Recommendation";
         case 10: return "Phase 7 Certification";
         case 11: return "Mode";
         case 12: return "Overall Score";
         case 13: return "Control Gate";
         default: return "AI";
        }
     }

   string ValueAt(const int i) const
     {
      if(!m_have)
        {
         if(i >= 9)
            return GM_AI_COMING_SOON;
         return GM_AI_NOT_INITIALIZED;
        }
      switch(i)
        {
         case 0:  return m_ai.w_trend_detector;
         case 1:  return m_ai.future_ai_score;
         case 2:  return m_ai.w_recovery_ai;
         case 3:  return m_ai.prediction_status;
         case 4:  return m_ai.learning_status;
         case 5:  return m_ai.w_volatility_scanner;
         case 6:  return m_ai.w_market_analyzer;
         case 7:  return m_ai.w_news_analyzer;
         case 8:  return m_ai.w_trade_confidence;
         case 9:  return m_ai.ai_version;
         case 10: return m_ai.ai_status;
         case 11: return m_ai.current_mode;
         case 12: return m_ai.confidence_status;
         case 13: return "ECOSYSTEM ONLY";
         default: return "—";
        }
     }
  };

#endif // GM_CDASHBOARD_AI_WIDGET_MANAGER_MQH
//+------------------------------------------------------------------+
