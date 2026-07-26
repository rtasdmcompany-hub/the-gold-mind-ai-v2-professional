//+------------------------------------------------------------------+
//|                                       CEtjJournalDatabase.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CETJ_JOURNAL_DATABASE_MQH
#define GM_CETJ_JOURNAL_DATABASE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "TradeJournalConstants.mqh"
#include "SGmTradeJournalPlatformResult.mqh"
#include "CEtjJournalEngine.mqh"
#include "../Core/CFileManager.mqh"
#include "../Logging/CLogger.mqh"

class CGmEtjJournalDatabase
  {
private:
   CGmLogger      *m_logger;
   CGmFileManager *m_files;
   string          m_pfx;
   bool            m_ready;

   void WriteTable(const string table, const string body)
     {
      if(m_files == NULL) return;
      m_files.WriteText(m_pfx + table + ".txt", body);
     }

public:
                     CGmEtjJournalDatabase(void)
                       : m_logger(NULL), m_files(NULL), m_pfx(""), m_ready(false) {}

   bool Init(CGmLogger *logger, CGmFileManager *files,
             const long magic, const string symbol)
     {
      m_logger = logger;
      m_files = files;
      string sym = symbol;
      StringReplace(sym, ".", "_");
      m_pfx = StringFormat("%s%I64d_%s_", GM_ETJ_DB_PREFIX, magic, sym);
      m_ready = true;
      if(m_logger != NULL)
         m_logger.Info("Database Updated | Trade Journal DB Ready | " + m_pfx, "ETJ");
      return true;
     }

   string Prefix(void) const { return m_pfx; }

   void Shutdown(void) { m_ready = false; }

   void Persist(CGmEtjJournalEngine *journal,
                const SGmTradeJournalPlatformResult &r,
                const string timeline_body)
     {
      if(!m_ready || m_files == NULL || !r.valid)
         return;

      const string ts = TimeToString(r.stamped_at, TIME_DATE | TIME_SECONDS);
      const string head = StringFormat("Timestamp=%s\r\n", ts);

      string hist = "=== trade_history ===\r\n" + head;
      SGmEtjTradeRecord t;
      if(journal != NULL)
        {
         for(int i = 0; i < journal.Count(); i++)
           {
            if(!journal.GetAt(i, t))
               continue;
            hist += StringFormat("TID=%I64u %s %s Entry=%.5f Exit=%.5f PnL=%.2f Session=%s\r\n",
                                 t.trade_id, GmEtjSideName(t.side), GmEtjStatusName(t.status),
                                 t.entry_price, t.exit_price, t.profit_loss, t.market_session);
           }
        }
      WriteTable("trade_history", hist);

      WriteTable("timeline",
                 "=== timeline ===\r\n" + head + timeline_body + "\r\n");

      WriteTable("replay_data",
                 "=== replay_data ===\r\n" + head + r.replay_summary + "\r\n");

      WriteTable("performance_reports",
                 "=== performance_reports ===\r\n" + head + r.analytics_summary + "\r\n" +
                 StringFormat("WR=%.1f PF=%.2f Exp=%.2f\r\n",
                              r.win_rate, r.profit_factor, r.expectancy));

      WriteTable("execution_reports",
                 "=== execution_reports ===\r\n" + head +
                 StringFormat("Execution=%.1f Discipline=%.1f Compliance=%.1f\r\n",
                              r.execution_score, r.discipline_score, r.compliance_score));

      WriteTable("ai_reports",
                 "=== ai_reports ===\r\n" + head +
                 "AI Confidence recorded per trade when available\r\n" +
                 "Screenshot capture = " + GM_ETJ_SCREENSHOT_ARCH + "\r\n");

      WriteTable("statistics",
                 "=== statistics ===\r\n" + head +
                 StringFormat("Total=%d Open=%d Today=%d Events=%d\r\n"
                              "TodayPnL=%.2f Week=%.2f Month=%.2f\r\n"
                              "Best=%s Worst=%s ConsecW=%d ConsecL=%d\r\n",
                              r.trades_total, r.trades_open, r.trades_today, r.timeline_events,
                              r.today_pnl, r.weekly_pnl, r.monthly_pnl,
                              r.best_session, r.worst_session,
                              r.max_consec_wins, r.max_consec_losses));

      if(m_logger != NULL)
         m_logger.Debug("Database Updated | ETJ tables persisted", "ETJ");
     }
  };

#endif // GM_CETJ_JOURNAL_DATABASE_MQH
//+------------------------------------------------------------------+
