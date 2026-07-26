//+------------------------------------------------------------------+
//|                               SGmAIDecisionCenterResult.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_SGM_AI_DECISION_CENTER_RESULT_MQH
#define GM_SGM_AI_DECISION_CENTER_RESULT_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "AIDecisionCenterConstants.mqh"

struct SGmAIDecisionCenterResult
  {
   datetime                  stamped_at;
   ENUM_GM_ADC_QUEUE         queue_status;
   ENUM_GM_ADC_QUALITY_GRADE trade_quality_grade;
   ENUM_GM_ADC_QUALITY_GRADE execution_grade;
   ENUM_GM_ADC_MARKET_CLASS  market_class;

   double                    decision_confidence;
   double                    decision_quality;
   double                    trade_quality_score;
   double                    execution_health;
   double                    broker_quality;
   double                    market_adaptability;

   int                       decisions_recorded;
   int                       trades_analyzed;

   string                    decision_report;
   string                    quality_report;
   string                    execution_report;
   string                    market_report;
   string                    daily_ai_report;
   string                    weekly_ai_report;
   string                    monthly_ai_report;
   string                    decision_history;
   string                    decision_timeline;
   string                    institutional_summary;
   string                    recommendations;
   string                    export_status;
   string                    center_status;
   string                    insight;

   bool                      may_execute;
   bool                      may_modify_risk;
   bool                      may_interrupt_trading;
   bool                      may_auto_change_ai;
   bool                      valid;

   void Reset(void)
     {
      stamped_at = 0;
      queue_status = GM_ADC_Q_IDLE;
      trade_quality_grade = GM_ADC_QG_C;
      execution_grade = GM_ADC_QG_C;
      market_class = GM_ADC_MKT_RANGING;
      decision_confidence = decision_quality = trade_quality_score = 0.0;
      execution_health = broker_quality = market_adaptability = 0.0;
      decisions_recorded = trades_analyzed = 0;
      decision_report = quality_report = execution_report = market_report = "";
      daily_ai_report = weekly_ai_report = monthly_ai_report = "";
      decision_history = decision_timeline = institutional_summary = "";
      recommendations = "";
      export_status = "Architecture Ready";
      center_status = insight = "";
      may_execute = false;
      may_modify_risk = false;
      may_interrupt_trading = false;
      may_auto_change_ai = false;
      valid = false;
     }
  };

#endif // GM_SGM_AI_DECISION_CENTER_RESULT_MQH
//+------------------------------------------------------------------+
