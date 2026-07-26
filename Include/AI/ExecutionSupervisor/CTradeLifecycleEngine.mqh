//+------------------------------------------------------------------+
//|                                 CTradeLifecycleEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CTRADE_LIFECYCLE_ENGINE_MQH
#define GM_CTRADE_LIFECYCLE_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmExecutionSupervisorResult.mqh"
#include "../Assistant/SGmAssistantResult.mqh"
#include "../../Analytics/SGmAnalyticsSnapshot.mqh"

class CGmTradeLifecycleEngine
  {
private:
   ENUM_GM_ES_STAGE InferStage(const SGmAssistantResult &sup,
                               const SGmExecutionSupervisorResult &r) const
     {
      if(sup.valid && sup.recovery_active)
         return GM_ES_STAGE_RECOVERY;
      if(r.active_trades > 0)
        {
         // Heuristic Gold Mind stage inference from floating P/L & exposure
         if(r.floating_profit > 0.0 && r.active_trades == 1 &&
            r.floating_profit > MathMax(5.0, r.atr14 * 0.15))
            return GM_ES_STAGE_TRAILING; // likely post-partial trail remnant
         if(r.floating_profit > 0.0 && r.active_trades >= 1 &&
            r.floating_loss < r.floating_profit * 0.25)
            return GM_ES_STAGE_IN_PROFIT;
         if(r.floating_profit >= 0.0 && r.floating_loss <= MathMax(1.0, r.atr14 * 0.05))
            return GM_ES_STAGE_BREAK_EVEN;
         if(r.active_trades >= 2)
            return GM_ES_STAGE_PARTIAL; // multi-lot / staggered levels still open
         return GM_ES_STAGE_ACTIVATED;
        }
      if(r.pending_orders > 0)
         return GM_ES_STAGE_PENDING;
      if(r.total_trades > 0 && r.active_trades == 0 && r.pending_orders == 0)
         return GM_ES_STAGE_CLOSED;
      return GM_ES_STAGE_IDLE;
     }

public:
   void Analyze(const SGmAssistantResult &sup,
                const SGmAnalyticsSnapshot &a,
                SGmExecutionSupervisorResult &r)
     {
      r.lifecycle_stage = InferStage(sup, r);
      r.lifecycle_status = GmEsStageName(r.lifecycle_stage);

      r.execution_timeline = StringFormat(
         "H4→Signal→Pending(%d)→Active(%d)→BE→Partial80→Trail20→Close | Now=%s",
         r.pending_orders, r.active_trades, r.lifecycle_status);

      string rec = "Idle";
      if(sup.valid && sup.recovery_active)
         rec = "Recovery ACTIVE | " + sup.recovery_status;
      else if(a.recovery_trades > 0)
         rec = StringFormat("Recovery history=%d | Second-attempt WR=%.0f%%",
                            a.recovery_trades, a.second_attempt_win_rate);
      else
         rec = StringFormat("No active recovery | FirstWR=%.0f%% SecondWR=%.0f%%",
                            a.first_attempt_win_rate, a.second_attempt_win_rate);
      r.recovery_timeline = rec;

      r.lifecycle_events = 0;
      if(r.pending_orders > 0) r.lifecycle_events++;
      if(r.active_trades > 0) r.lifecycle_events++;
      if(r.lifecycle_stage == GM_ES_STAGE_BREAK_EVEN ||
         r.lifecycle_stage == GM_ES_STAGE_PARTIAL ||
         r.lifecycle_stage == GM_ES_STAGE_TRAILING)
         r.lifecycle_events++;
      if(r.lifecycle_stage == GM_ES_STAGE_RECOVERY) r.lifecycle_events++;
      if(r.lifecycle_stage == GM_ES_STAGE_CLOSED) r.lifecycle_events++;

      r.lifecycle_report = StringFormat(
         "Stage=%s | Events=%d | DurationAvg=%.0fs | BuyOpen=%d SellOpen=%d | %s",
         r.lifecycle_status, r.lifecycle_events, r.trade_duration_sec,
         r.buy_open, r.sell_open, GM_ES_CONTEXT);
     }
  };

#endif // GM_CTRADE_LIFECYCLE_ENGINE_MQH
//+------------------------------------------------------------------+
