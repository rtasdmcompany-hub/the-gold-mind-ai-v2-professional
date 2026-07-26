//+------------------------------------------------------------------+
//|                                        SGmJournalReportStats.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_SGM_JOURNAL_REPORT_STATS_MQH
#define GM_SGM_JOURNAL_REPORT_STATS_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

/// @file SGmJournalReportStats.mqh
/// @brief Dashboard report-panel metrics derived from journals (READ-ONLY).

struct SGmJournalReportStats
  {
   string today_summary;
   string last_winning_trade;
   string last_losing_trade;
   string largest_win;
   string largest_loss;
   string longest_win_streak;
   string longest_loss_streak;
   string current_session_result;
   string average_trade_time;
   int    alert_count;
   string last_alert;
   int    trade_count;
   int    level_count;
   int    session_count;
   bool   valid;

   void Reset(void)
     {
      today_summary = "—";
      last_winning_trade = "—";
      last_losing_trade = "—";
      largest_win = "—";
      largest_loss = "—";
      longest_win_streak = "0";
      longest_loss_streak = "0";
      current_session_result = "—";
      average_trade_time = "—";
      alert_count = 0;
      last_alert = "—";
      trade_count = 0;
      level_count = 0;
      session_count = 0;
      valid = false;
     }
  };

#endif // GM_SGM_JOURNAL_REPORT_STATS_MQH
//+------------------------------------------------------------------+
