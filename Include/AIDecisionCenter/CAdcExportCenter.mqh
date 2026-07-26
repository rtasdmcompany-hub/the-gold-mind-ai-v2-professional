//+------------------------------------------------------------------+
//|                                        CAdcExportCenter.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CADC_EXPORT_CENTER_MQH
#define GM_CADC_EXPORT_CENTER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmAIDecisionCenterResult.mqh"
#include "../Core/CFileManager.mqh"
#include "../Logging/CLogger.mqh"

class CGmAdcExportCenter
  {
private:
   CGmLogger      *m_logger;
   CGmFileManager *m_files;
   string          m_pfx;
   string          m_status;

public:
                     CGmAdcExportCenter(void)
                       : m_logger(NULL), m_files(NULL), m_pfx(""), m_status("Idle") {}

   void Init(CGmLogger *logger, CGmFileManager *files, const string prefix)
     {
      m_logger = logger;
      m_files = files;
      m_pfx = prefix;
      m_status = "Architecture Ready | CSV stubs | PDF/Excel ARCH";
     }

   string Status(void) const { return m_status; }

   void Export(const SGmAIDecisionCenterResult &r)
     {
      if(m_files == NULL || !r.valid) return;

      m_files.WriteText(m_pfx + "ai_decision_report.txt", r.decision_report);
      m_files.WriteText(m_pfx + "trade_quality_report.txt", r.quality_report);
      m_files.WriteText(m_pfx + "execution_report.txt", r.execution_report);
      m_files.WriteText(m_pfx + "broker_report.txt",
                        StringFormat("BrokerQuality=%.0f\r\nExecHealth=%.0f\r\n",
                                     r.broker_quality, r.execution_health));
      m_files.WriteText(m_pfx + "institutional_ai_report.txt", r.institutional_summary);

      m_files.WriteText(m_pfx + "adc_export.csv",
                        "Metric,Value\r\n" +
                        StringFormat("DecisionConfidence,%.1f\r\nDecisionQuality,%.1f\r\n"
                                     "TradeQuality,%.1f\r\nExecHealth,%.1f\r\nBrokerQuality,%.1f\r\n"
                                     "MarketAdaptability,%.1f\r\n",
                                     r.decision_confidence, r.decision_quality,
                                     r.trade_quality_score, r.execution_health,
                                     r.broker_quality, r.market_adaptability));

      m_files.WriteText(m_pfx + "export_pdf.arch.txt", "PDF — architecture reserved\r\n");
      m_files.WriteText(m_pfx + "export_excel.arch.txt", "Excel — architecture reserved\r\n");

      m_status = "CSV/TXT Exported | PDF/Excel ARCH";
      if(m_logger != NULL)
         m_logger.Info("AI Report Generated | Export " + m_status, "ADC");
     }
  };

#endif // GM_CADC_EXPORT_CENTER_MQH
//+------------------------------------------------------------------+
