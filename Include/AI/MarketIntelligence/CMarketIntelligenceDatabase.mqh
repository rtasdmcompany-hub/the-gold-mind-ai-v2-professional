//+------------------------------------------------------------------+
//|                               CMarketIntelligenceDatabase.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CMARKET_INTELLIGENCE_DATABASE_MQH
#define GM_CMARKET_INTELLIGENCE_DATABASE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmMarketIntelligenceResult.mqh"
#include "../../Core/CFileManager.mqh"
#include "../../Logging/CLogger.mqh"

class CGmMarketIntelligenceDatabase
  {
private:
   CGmLogger      *m_logger;
   CGmFileManager *m_files;
   string          m_pfx;
   string          m_rows[GM_MI_HIST_MAX];
   int             m_n;
   ulong           m_last_persist_ms;
   bool            m_ready;

   void WriteTable(const string table, const string body)
     {
      if(m_files == NULL) return;
      m_files.WriteText(m_pfx + table + ".txt", body);
     }

public:
                     CGmMarketIntelligenceDatabase(void)
                       : m_logger(NULL), m_files(NULL), m_pfx(""), m_n(0),
                         m_last_persist_ms(0), m_ready(false) {}

   bool Init(CGmLogger *logger, CGmFileManager *files,
             const long magic, const string symbol)
     {
      m_logger = logger;
      m_files = files;
      string sym = symbol;
      StringReplace(sym, ".", "_");
      m_pfx = StringFormat("%s%I64d_%s_", GM_MI_DB_PREFIX, magic, sym);
      m_n = 0;
      m_ready = true;
      if(m_logger != NULL)
         m_logger.Info("Market Intelligence Database Ready | " + m_pfx, "AIMI");
      return true;
     }

   void Shutdown(void)
     {
      Persist();
      m_ready = false;
     }

   void Persist(void)
     {
      if(!m_ready || m_files == NULL) return;
      string body = "=== market_intelligence_index ===\r\n";
      for(int i = 0; i < m_n; i++)
         body += m_rows[i] + "\r\n";
      m_files.WriteText(m_pfx + "market_intelligence_index.txt", body);
     }

   void Record(const SGmMarketIntelligenceResult &r)
     {
      if(!m_ready || !r.valid) return;

      const string ts = TimeToString(r.stamped_at, TIME_DATE | TIME_SECONDS);
      const string head = StringFormat("Timestamp=%s | SessionID=%I64u | Symbol=%s\r\n",
                                       ts, r.session_id, r.symbol);

      WriteTable("market_intelligence", "=== market_intelligence ===\r\n" + head + r.market_intelligence_report);
      WriteTable("momentum", "=== momentum ===\r\n" + head + r.momentum_report);
      WriteTable("liquidity", "=== liquidity ===\r\n" + head + r.liquidity_report);
      WriteTable("institutional_analysis", "=== institutional_analysis ===\r\n" + head + r.institutional_report);
      WriteTable("market_structure", "=== market_structure ===\r\n" + head + r.structure_report);
      WriteTable("breakout_analysis",
                 "=== breakout_analysis ===\r\n" + head +
                 StringFormat("BreakoutProb=%.0f%% FalseBO=%.0f%% ATRExp=%.0f\r\n",
                              r.breakout_probability, r.false_breakout_probability, r.atr_expansion_score));
      WriteTable("reversal_analysis",
                 "=== reversal_analysis ===\r\n" + head +
                 StringFormat("ReversalProb=%.0f%% Exhaust=%.0f CHoCH=%s\r\n",
                              r.reversal_probability, r.momentum_exhaustion,
                              (r.change_of_character ? "Y" : "N")));

      const string line = StringFormat("%s | mom=%.0f liq=%.0f struct=%.0f bo=%.0f rev=%.0f phase=%s",
                                       ts, r.momentum_index, r.liquidity_score,
                                       r.structure_quality, r.breakout_probability,
                                       r.reversal_probability, GmMiInstPhaseName(r.institutional_phase));
      if(m_n < GM_MI_HIST_MAX)
         m_rows[m_n++] = line;
      else
        {
         for(int i = 1; i < GM_MI_HIST_MAX; i++)
            m_rows[i - 1] = m_rows[i];
         m_rows[GM_MI_HIST_MAX - 1] = line;
        }

      const ulong now = GetTickCount();
      if(m_last_persist_ms == 0 || (now - m_last_persist_ms) > 9000)
        {
         Persist();
         m_last_persist_ms = now;
         if(m_logger != NULL)
            m_logger.Info("Database Synchronization Completed | Market Intelligence tables", "AIMI");
        }
     }
  };

#endif // GM_CMARKET_INTELLIGENCE_DATABASE_MQH
//+------------------------------------------------------------------+
