//+------------------------------------------------------------------+
//|                                           CReportGenerator.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CREPORT_GENERATOR_MQH
#define GM_CREPORT_GENERATOR_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "../Journal/JournalConstants.mqh"
#include "../Journal/CJournalEngine.mqh"
#include "../Analytics/SGmAnalyticsSnapshot.mqh"
#include "../Logging/CLogger.mqh"
#include "../Core/Version.mqh"

/// @file CReportGenerator.mqh
/// @brief Builds in-memory enterprise reports (READ-ONLY).

class CGmReportGenerator
  {
private:
   CGmLogger *m_logger;
   string     m_cache[GM_REPORT_CACHE_MAX];
   int        m_cache_type[GM_REPORT_CACHE_MAX];
   int        m_cache_n;

   string TypeName(const ENUM_GM_REPORT_TYPE t) const
     {
      switch(t)
        {
         case GM_RPT_WEEKLY:      return "WEEKLY";
         case GM_RPT_MONTHLY:     return "MONTHLY";
         case GM_RPT_SESSION:     return "SESSION";
         case GM_RPT_TRADE:       return "TRADE";
         case GM_RPT_PERFORMANCE: return "PERFORMANCE";
         case GM_RPT_RISK:        return "RISK";
         case GM_RPT_RECOVERY:    return "RECOVERY";
         default:                 return "DAILY";
        }
     }

   void CachePut(const ENUM_GM_REPORT_TYPE t, const string body)
     {
      if(m_cache_n < GM_REPORT_CACHE_MAX)
        {
         m_cache_type[m_cache_n] = (int)t;
         m_cache[m_cache_n] = body;
         m_cache_n++;
         return;
        }
      for(int i = 1; i < GM_REPORT_CACHE_MAX; i++)
        {
         m_cache[i - 1] = m_cache[i];
         m_cache_type[i - 1] = m_cache_type[i];
        }
      m_cache_type[GM_REPORT_CACHE_MAX - 1] = (int)t;
      m_cache[GM_REPORT_CACHE_MAX - 1] = body;
     }

public:
                     CGmReportGenerator(void) : m_logger(NULL), m_cache_n(0)
     {
      for(int i = 0; i < GM_REPORT_CACHE_MAX; i++)
        {
         m_cache[i] = "";
         m_cache_type[i] = -1;
        }
     }

   void Init(CGmLogger *logger)
     {
      m_logger = logger;
      m_cache_n = 0;
     }

   string Generate(const ENUM_GM_REPORT_TYPE type,
                   CGmJournalEngine *journal,
                   const SGmAnalyticsSnapshot &an)
     {
      string body = StringFormat(
                       "# THE GOLD MIND AI — %s REPORT\r\n"
                       "Build %d | %s\r\n"
                       "Generated: %s\r\n"
                       "Symbol: %s | Magic: %I64d\r\n"
                       "----------------------------------------\r\n",
                       TypeName(type),
                       GM_VERSION_BUILD,
                       GM_SPRINT_LABEL,
                       TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS),
                       an.symbol,
                       an.magic);

      if(journal != NULL)
        {
         const SGmJournalReportStats st = journal.Stats();
         body += StringFormat("Today Summary: %s\r\n", st.today_summary);
         body += StringFormat("Last Win: %s | Last Loss: %s\r\n",
                              st.last_winning_trade, st.last_losing_trade);
         body += StringFormat("Largest Win/Loss: %s / %s\r\n",
                              st.largest_win, st.largest_loss);
         body += StringFormat("Streaks W/L: %s / %s\r\n",
                              st.longest_win_streak, st.longest_loss_streak);
         body += StringFormat("Session: %s\r\n", st.current_session_result);
         body += StringFormat("Avg Trade Time: %s\r\n", st.average_trade_time);
         body += StringFormat("Journal Counts | trades=%d levels=%d sessions=%d alerts=%d\r\n",
                              st.trade_count, st.level_count, st.session_count, st.alert_count);
        }

      body += "----------------------------------------\r\n";
      body += StringFormat("Analytics Net=%.2f WR=%.1f%% PF=%.2f RF=%.2f DD=%.2f%%\r\n",
                           an.total_net_profit, an.overall_win_rate,
                           an.profit_factor, an.recovery_factor, an.current_dd_pct);
      body += StringFormat("Today %+0.2f / Week %+0.2f / Month %+0.2f\r\n",
                           an.today_profit - an.today_loss,
                           an.week_profit - an.week_loss,
                           an.month_profit - an.month_loss);
      body += StringFormat("Risk curr=%.2f%% max=%.2f%% | Recovery trades=%d\r\n",
                           an.current_risk_pct, an.maximum_risk_pct, an.recovery_trades);
      body += "READ-ONLY — no trade interference\r\n";

      CachePut(type, body);
      if(m_logger != NULL)
         m_logger.Info(StringFormat("Report Generated | type=%s | bytes=%d",
                                    TypeName(type), StringLen(body)),
                       "ReportGenerator");
      return body;
     }

   bool GetCached(const ENUM_GM_REPORT_TYPE type, string &out) const
     {
      for(int i = m_cache_n - 1; i >= 0; i--)
        {
         if(m_cache_type[i] == (int)type)
           {
            out = m_cache[i];
            return (StringLen(out) > 0);
           }
        }
      return false;
     }
  };

#endif // GM_CREPORT_GENERATOR_MQH
//+------------------------------------------------------------------+
