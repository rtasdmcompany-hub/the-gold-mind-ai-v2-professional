//+------------------------------------------------------------------+
//|                                    CAdcDecisionDatabase.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CADC_DECISION_DATABASE_MQH
#define GM_CADC_DECISION_DATABASE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmAIDecisionCenterResult.mqh"
#include "../Core/CFileManager.mqh"
#include "../Logging/CLogger.mqh"

class CGmAdcDecisionDatabase
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
                     CGmAdcDecisionDatabase(void)
                       : m_logger(NULL), m_files(NULL), m_pfx(""), m_ready(false) {}

   bool Init(CGmLogger *logger, CGmFileManager *files,
             const long magic, const string symbol)
     {
      m_logger = logger;
      m_files = files;
      string sym = symbol;
      StringReplace(sym, ".", "_");
      m_pfx = StringFormat("%s%I64d_%s_", GM_ADC_DB_PREFIX, magic, sym);
      m_ready = true;
      if(m_logger != NULL)
         m_logger.Info("Database Updated | AI Decision Center DB Ready | " + m_pfx, "ADC");
      return true;
     }

   string Prefix(void) const { return m_pfx; }
   void Shutdown(void) { m_ready = false; }

   void Persist(const SGmAIDecisionCenterResult &r)
     {
      if(!m_ready || m_files == NULL || !r.valid) return;
      const string ts = TimeToString(r.stamped_at, TIME_DATE | TIME_SECONDS);
      const string head = StringFormat("Timestamp=%s\r\n", ts);

      WriteTable("decision_history", head + r.decision_history + "\r\n" + r.decision_timeline);
      WriteTable("trade_quality_reports", head + r.quality_report);
      WriteTable("execution_reports", head + r.execution_report);
      WriteTable("broker_statistics", head + StringFormat("Broker=%.0f Exec=%.0f\r\n",
                                                           r.broker_quality, r.execution_health));
      WriteTable("market_classification", head + r.market_report);
      WriteTable("ai_reports", head + r.daily_ai_report + "\r\n" + r.weekly_ai_report +
                 "\r\n" + r.monthly_ai_report + "\r\n" + r.institutional_summary);
      WriteTable("historical_scores", head + StringFormat(
         "Conf=%.0f Qual=%.0f TradeQ=%.0f Exec=%.0f Broker=%.0f Adapt=%.0f\r\n",
         r.decision_confidence, r.decision_quality, r.trade_quality_score,
         r.execution_health, r.broker_quality, r.market_adaptability));

      if(m_logger != NULL)
         m_logger.Debug("Database Updated | ADC tables persisted", "ADC");
     }
  };

#endif // GM_CADC_DECISION_DATABASE_MQH
//+------------------------------------------------------------------+
