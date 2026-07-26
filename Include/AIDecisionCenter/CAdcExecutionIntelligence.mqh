//+------------------------------------------------------------------+
//|                               CAdcExecutionIntelligence.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CADC_EXECUTION_INTELLIGENCE_MQH
#define GM_CADC_EXECUTION_INTELLIGENCE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmAIDecisionCenterResult.mqh"
#include "../TradeJournal/SGmTradeJournalPlatformResult.mqh"
#include "../PortfolioAnalytics/SGmPortfolioAnalyticsResult.mqh"
#include "../Logging/CLogger.mqh"

class CGmAdcExecutionIntelligence
  {
private:
   CGmLogger *m_logger;
   double     m_exec_health;
   double     m_broker_quality;

   double Clamp100(const double v) const
     {
      if(v < 0.0) return 0.0;
      if(v > 100.0) return 100.0;
      return v;
     }

public:
                     CGmAdcExecutionIntelligence(void)
                       : m_logger(NULL), m_exec_health(0.0), m_broker_quality(0.0) {}

   void Init(CGmLogger *logger)
     {
      m_logger = logger;
      m_exec_health = m_broker_quality = 0.0;
     }

   double ExecHealth(void) const { return m_exec_health; }
   double BrokerQuality(void) const { return m_broker_quality; }

   void Analyze(const SGmTradeJournalPlatformResult &etj,
                const SGmPortfolioAnalyticsResult &epa,
                SGmAIDecisionCenterResult &out)
     {
      double eh = 60.0;
      eh += MathMin(20.0, etj.execution_score * 0.2);
      eh += MathMin(10.0, etj.discipline_score * 0.1);
      eh += (etj.trades_total > 0 ? 5.0 : 0.0);
      eh -= MathMin(10.0, (double)epa.max_consec_losses);

      double bq = 58.0;
      bq += MathMin(15.0, etj.execution_score * 0.15);
      bq += MathMin(12.0, etj.compliance_score * 0.12);
      bq += MathMin(10.0, epa.portfolio_health * 0.08);
      bq += 5.0; // architecture assumes retry catalog available

      m_exec_health = Clamp100(eh);
      m_broker_quality = Clamp100(bq);

      out.execution_health = m_exec_health;
      out.broker_quality = m_broker_quality;

      out.execution_report = StringFormat(
         "=== EXECUTION INTELLIGENCE ===\r\n"
         "Latency/PendingLatency/BrokerResponse=Observe Catalog\r\n"
         "FillQuality | RejectionRate | RetryEvents | Stability\r\n"
         "ExecutionHealth=%.0f | BrokerQuality=%.0f | ETJ Exec=%.0f\r\n",
         m_exec_health, m_broker_quality, etj.execution_score);

      if(m_logger != NULL)
         m_logger.Info(StringFormat("Execution Analysis Completed | Health=%.0f Broker=%.0f",
                                    m_exec_health, m_broker_quality), "ADC");
     }
  };

#endif // GM_CADC_EXECUTION_INTELLIGENCE_MQH
//+------------------------------------------------------------------+
