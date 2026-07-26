//+------------------------------------------------------------------+
//|                                          CEslExportCenter.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Export architecture — CSV live · PDF/Excel ARCH             |
//+------------------------------------------------------------------+
#ifndef GM_CESL_EXPORT_CENTER_MQH
#define GM_CESL_EXPORT_CENTER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmStrategyLabResult.mqh"
#include "../Core/CFileManager.mqh"
#include "../Logging/CLogger.mqh"

class CGmEslExportCenter
  {
private:
   CGmLogger      *m_logger;
   CGmFileManager *m_files;
   string          m_pfx;
   string          m_status;

public:
                     CGmEslExportCenter(void)
                       : m_logger(NULL), m_files(NULL), m_pfx(""), m_status("Idle") {}

   void Init(CGmLogger *logger, CGmFileManager *files, const string prefix)
     {
      m_logger = logger;
      m_files = files;
      m_pfx = prefix;
      m_status = "Architecture Ready | CSV live | PDF/Excel/Institutional = ARCH";
     }

   string Status(void) const { return m_status; }

   void Export(const SGmStrategyLabResult &r)
     {
      if(m_files == NULL || !r.valid)
         return;

      m_files.WriteText(m_pfx + "backtest_report.csv",
                        "Metric,Value\r\n" +
                        StringFormat("Health,%.1f\r\nTrades,%d\r\nBars,%d\r\nWR,%.1f\r\nPF,%.2f\r\n",
                                     r.backtest_health, r.simulated_trades, r.bars_covered,
                                     r.win_rate, r.profit_factor));

      m_files.WriteText(m_pfx + "monte_carlo_report.txt",
                        "=== MONTE CARLO ===\r\n" + r.monte_carlo_summary + "\r\n" +
                        r.probability_report + "\r\n");

      m_files.WriteText(m_pfx + "walk_forward_report.txt",
                        "=== WALK-FORWARD ===\r\n" + r.walk_forward_summary + "\r\n");

      m_files.WriteText(m_pfx + "validation_report.txt",
                        "=== INSTITUTIONAL VALIDATION ===\r\n" +
                        r.validation_status + "\r\n" +
                        StringFormat("Institutional=%.1f Robust=%.1f\r\n",
                                     r.institutional_score, r.robustness_score));

      m_files.WriteText(m_pfx + "export_pdf.arch.txt", "PDF Validation Reports — architecture reserved\r\n");
      m_files.WriteText(m_pfx + "export_excel.arch.txt", "Excel Reports — architecture reserved\r\n");
      m_files.WriteText(m_pfx + "export_institutional.arch.txt", "Institutional Reports — architecture reserved\r\n");

      m_status = "CSV Exported | PDF/Excel/Institutional ARCH";
      if(m_logger != NULL)
         m_logger.Info("Report Generated | " + m_status, "ESL");
     }
  };

#endif // GM_CESL_EXPORT_CENTER_MQH
//+------------------------------------------------------------------+
