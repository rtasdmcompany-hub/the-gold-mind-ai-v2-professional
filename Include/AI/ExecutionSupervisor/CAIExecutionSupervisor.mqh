//+------------------------------------------------------------------+
//|                              CAIExecutionSupervisor.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Real-time execution health observation — never executes     |
//+------------------------------------------------------------------+
#ifndef GM_CAI_EXECUTION_SUPERVISOR_MQH
#define GM_CAI_EXECUTION_SUPERVISOR_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmExecutionSupervisorResult.mqh"
#include "../Assistant/SGmAssistantResult.mqh"
#include "../../Analytics/SGmAnalyticsSnapshot.mqh"

class CGmAIExecutionSupervisor
  {
public:
   void Analyze(const SGmAssistantResult &sup,
                const SGmAnalyticsSnapshot &a,
                const int own_positions,
                const int own_pendings,
                SGmExecutionSupervisorResult &r)
     {
      r.pending_orders = (own_pendings > 0) ? own_pendings : a.pending_orders;
      r.active_trades = (own_positions > 0) ? own_positions : a.running_trades;
      r.buy_open = a.buy_open;
      r.sell_open = a.sell_open;
      r.total_trades = a.total_trades;
      r.recovery_trades = a.recovery_trades;
      r.floating_profit = a.floating_profit;
      r.floating_loss = a.floating_loss;
      r.spread_points = (sup.valid && sup.spread_points > 0.0) ? sup.spread_points : a.spread_points;
      r.atr14 = a.atr14;
      r.trade_duration_sec = a.avg_trade_duration_sec;

      double health = 72.0;
      if(sup.valid)
         health = 0.45 * sup.overall_health_score + 0.25 * sup.system_health_score +
                  0.20 * sup.capital_protection_score + 0.10 * (100.0 - MathMin(100.0, sup.current_dd_pct * 4.0));

      if(r.active_trades > 0)
         health += (r.floating_profit > r.floating_loss) ? 4.0 : -6.0;
      if(r.spread_points > 40.0)
         health -= 8.0;
      else if(r.spread_points > 25.0)
         health -= 3.0;
      if(sup.valid && sup.recovery_active)
         health -= 5.0;

      r.execution_health_score = GmEsClamp(health);

      r.supervisor_report = StringFormat(
         "Pending=%d Active=%d Buy=%d Sell=%d FloatP=%.2f FloatL=%.2f Spread=%.1f ATR=%.2f | Health=%.0f",
         r.pending_orders, r.active_trades, r.buy_open, r.sell_open,
         r.floating_profit, r.floating_loss, r.spread_points, r.atr14,
         r.execution_health_score);
     }
  };

#endif // GM_CAI_EXECUTION_SUPERVISOR_MQH
//+------------------------------------------------------------------+
