//+------------------------------------------------------------------+
//|                                       CAIAlertCenter.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Dashboard alerts only — never mutates trades                |
//+------------------------------------------------------------------+
#ifndef GM_CAI_ALERT_CENTER_MQH
#define GM_CAI_ALERT_CENTER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmExecutionSupervisorResult.mqh"
#include "../Assistant/SGmAssistantResult.mqh"
#include "../OrderFlow/SGmOrderFlowResult.mqh"

class CGmAIAlertCenter
  {
private:
   ENUM_GM_ES_STAGE m_prev_stage;
   int              m_prev_pending;
   int              m_prev_active;
   double           m_prev_spread;
   ENUM_GM_OF_SESSION m_prev_session;
   bool             m_prev_recovery;
   bool             m_have_prev;

   void Push(SGmExecutionSupervisorResult &r, const string msg)
     {
      if(r.alert_count >= GM_ES_ALERT_MAX)
         return;
      r.alerts[r.alert_count++] = msg;
      r.latest_alert = msg;
     }

public:
                     CGmAIAlertCenter(void)
                       : m_prev_stage(GM_ES_STAGE_IDLE), m_prev_pending(0), m_prev_active(0),
                         m_prev_spread(0.0), m_prev_session(GM_OF_SESSION_UNKNOWN),
                         m_prev_recovery(false), m_have_prev(false) {}

   void Analyze(const SGmAssistantResult &sup,
                const SGmOrderFlowResult &of,
                SGmExecutionSupervisorResult &r)
     {
      r.alert_count = 0;
      for(int i = 0; i < GM_ES_ALERT_MAX; i++)
         r.alerts[i] = "";
      r.latest_alert = "";

      if(!m_have_prev)
        {
         if(r.active_trades > 0)
            Push(r, "Trade Entered");
         else if(r.pending_orders > 0)
            Push(r, "Pending Order Created");
         else
            Push(r, "Supervisor Monitoring Active");
        }
      else
        {
         if(r.active_trades > m_prev_active)
            Push(r, "Trade Entered");
         if(r.pending_orders > m_prev_pending && r.active_trades == m_prev_active)
            Push(r, "Pending Order Created");
         if(r.lifecycle_stage != m_prev_stage)
           {
            if(r.lifecycle_stage == GM_ES_STAGE_BREAK_EVEN)
               Push(r, "Break Even Activated");
            else if(r.lifecycle_stage == GM_ES_STAGE_PARTIAL)
               Push(r, "Partial Close Completed");
            else if(r.lifecycle_stage == GM_ES_STAGE_TRAILING)
               Push(r, "Trailing Stop Updated");
            else if(r.lifecycle_stage == GM_ES_STAGE_RECOVERY)
               Push(r, "Recovery Activated");
            else if(r.lifecycle_stage == GM_ES_STAGE_CLOSED)
               Push(r, "Trade Closed");
            else if(r.lifecycle_stage == GM_ES_STAGE_ACTIVATED)
               Push(r, "Pending Order Activated");
            else
               Push(r, "Market Structure Changed");
           }
         if(sup.valid && sup.recovery_active && !m_prev_recovery)
            Push(r, "Recovery Activated");
         if(sup.valid && !sup.recovery_active && m_prev_recovery)
            Push(r, "Recovery Completed");
         if(r.spread_points > m_prev_spread + 8.0)
            Push(r, "Spread Increased");
         if(of.valid && of.energy_score >= 80.0 && of.expansion_energy >= 70.0)
            Push(r, "High Volatility");
         if(of.valid && of.active_session != m_prev_session &&
            m_prev_session != GM_OF_SESSION_UNKNOWN)
            Push(r, "Session Changed");
        }

      if(r.alert_count == 0)
         Push(r, "No New Lifecycle Events");

      r.alert_center = "";
      for(int j = 0; j < r.alert_count; j++)
        {
         if(j > 0) r.alert_center += " | ";
         r.alert_center += r.alerts[j];
        }

      m_prev_stage = r.lifecycle_stage;
      m_prev_pending = r.pending_orders;
      m_prev_active = r.active_trades;
      m_prev_spread = r.spread_points;
      if(of.valid) m_prev_session = of.active_session;
      m_prev_recovery = (sup.valid && sup.recovery_active);
      m_have_prev = true;
     }
  };

#endif // GM_CAI_ALERT_CENTER_MQH
//+------------------------------------------------------------------+
