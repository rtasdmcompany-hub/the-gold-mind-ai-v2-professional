//+------------------------------------------------------------------+
//|                          SGmTradeJournalPlatformResult.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_SGM_TRADE_JOURNAL_PLATFORM_RESULT_MQH
#define GM_SGM_TRADE_JOURNAL_PLATFORM_RESULT_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "TradeJournalConstants.mqh"

struct SGmTradeJournalPlatformResult
  {
   datetime            stamped_at;
   ENUM_GM_ETJ_REPLAY  replay_status;

   int                 trades_total;
   int                 trades_open;
   int                 trades_today;
   int                 timeline_events;

   double              win_rate;
   double              loss_rate;
   double              avg_win;
   double              avg_loss;
   double              expectancy;
   double              profit_factor;
   double              recovery_rate;
   double              avg_holding_sec;
   double              avg_atr;
   int                 max_consec_wins;
   int                 max_consec_losses;
   string              best_session;
   string              worst_session;

   double              weekly_pnl;
   double              monthly_pnl;
   double              today_pnl;

   double              execution_score;
   double              discipline_score;
   double              compliance_score;

   string              timeline_summary;
   string              replay_summary;
   string              analytics_summary;
   string              export_status;
   string              center_status;
   string              insight;

   bool                may_execute;
   bool                may_modify_risk;
   bool                may_interrupt_trading;
   bool                valid;

   void Reset(void)
     {
      stamped_at = 0;
      replay_status = GM_ETJ_RP_IDLE;
      trades_total = trades_open = trades_today = timeline_events = 0;
      win_rate = loss_rate = avg_win = avg_loss = 0.0;
      expectancy = profit_factor = recovery_rate = 0.0;
      avg_holding_sec = avg_atr = 0.0;
      max_consec_wins = max_consec_losses = 0;
      best_session = worst_session = "—";
      weekly_pnl = monthly_pnl = today_pnl = 0.0;
      execution_score = discipline_score = compliance_score = 0.0;
      timeline_summary = replay_summary = analytics_summary = "";
      export_status = "Architecture Ready";
      center_status = insight = "";
      may_execute = false;
      may_modify_risk = false;
      may_interrupt_trading = false;
      valid = false;
     }
  };

#endif // GM_SGM_TRADE_JOURNAL_PLATFORM_RESULT_MQH
//+------------------------------------------------------------------+
