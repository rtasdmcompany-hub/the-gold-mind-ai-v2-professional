//+------------------------------------------------------------------+
//|                                          CEolExportCenter.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CEOL_EXPORT_CENTER_MQH
#define GM_CEOL_EXPORT_CENTER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmOptimizationLabResult.mqh"
#include "../Core/CFileManager.mqh"
#include "../Logging/CLogger.mqh"

class CGmEolExportCenter
  {
private:
   CGmLogger      *m_logger;
   CGmFileManager *m_files;
   string          m_pfx;
   string          m_status;

public:
                     CGmEolExportCenter(void)
                       : m_logger(NULL), m_files(NULL), m_pfx(""), m_status("Idle") {}

   void Init(CGmLogger *logger, CGmFileManager *files, const string prefix)
     {
      m_logger = logger;
      m_files = files;
      m_pfx = prefix;
      m_status = "Architecture Ready | CSV live | PDF/Excel = ARCH";
     }

   string Status(void) const { return m_status; }

   void Export(const SGmOptimizationLabResult &r)
     {
      if(m_files == NULL || !r.valid)
         return;

      m_files.WriteText(m_pfx + "optimization_report.csv",
                        "Metric,Value\r\n" +
                        StringFormat("OptimizationScore,%.1f\r\nComparisonScore,%.1f\r\n"
                                     "ParamStability,%.1f\r\nParamConfidence,%.1f\r\n"
                                     "Adaptability,%.1f\r\nInstitutional,%.1f\r\n",
                                     r.optimization_score, r.comparison_score,
                                     r.parameter_stability, r.parameter_confidence,
                                     r.market_adaptability, r.institutional_score));

      m_files.WriteText(m_pfx + "strategy_comparison_report.txt",
                        "=== STRATEGY COMPARISON ===\r\n" + r.comparison_summary + "\r\n" +
                        r.ranking_summary + "\r\n");

      m_files.WriteText(m_pfx + "ai_recommendation_report.txt",
                        r.recommendation_report + "\r\n");

      m_files.WriteText(m_pfx + "institutional_validation_report.txt",
                        "=== INSTITUTIONAL VALIDATION ===\r\n" +
                        r.validation_status + "\r\n" + r.adaptability_report + "\r\n");

      m_files.WriteText(m_pfx + "export_pdf.arch.txt", "PDF — architecture reserved\r\n");
      m_files.WriteText(m_pfx + "export_excel.arch.txt", "Excel — architecture reserved\r\n");

      m_status = "CSV Exported | PDF/Excel ARCH";
      if(m_logger != NULL)
         m_logger.Info("Report Generated | " + m_status, "EOL");
     }
  };

#endif // GM_CEOL_EXPORT_CENTER_MQH
//+------------------------------------------------------------------+
