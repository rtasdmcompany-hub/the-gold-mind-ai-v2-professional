//+------------------------------------------------------------------+
//|                                          CErcExportCenter.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CERC_EXPORT_CENTER_MQH
#define GM_CERC_EXPORT_CENTER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmReportingCenterResult.mqh"
#include "../Core/CFileManager.mqh"
#include "../Logging/CLogger.mqh"

class CGmErcExportCenter
  {
private:
   CGmLogger      *m_logger;
   CGmFileManager *m_files;
   string          m_pfx;
   string          m_status;

public:
                     CGmErcExportCenter(void)
                       : m_logger(NULL), m_files(NULL), m_pfx(""), m_status("Idle") {}

   void Init(CGmLogger *logger, CGmFileManager *files, const string prefix)
     {
      m_logger = logger;
      m_files = files;
      m_pfx = prefix;
      m_status = "Architecture Ready | CSV/JSON/HTML stubs | PDF/Excel packages = ARCH";
     }

   string Status(void) const { return m_status; }

   void Export(const SGmReportingCenterResult &r)
     {
      if(m_files == NULL || !r.valid) return;

      m_files.WriteText(m_pfx + "daily_report.txt", r.daily_report);
      m_files.WriteText(m_pfx + "monthly_report.txt", r.monthly_report);
      m_files.WriteText(m_pfx + "executive_summary.txt", r.executive_summary);
      m_files.WriteText(m_pfx + "investor_dashboard.txt", r.investor_summary);
      m_files.WriteText(m_pfx + "business_intelligence.txt", r.bi_report);
      m_files.WriteText(m_pfx + "visualization_catalog.txt", r.visualization_catalog);

      m_files.WriteText(m_pfx + "reports_export.csv",
                        "Metric,Value\r\n" +
                        StringFormat("ReportQuality,%.1f\r\nBIScore,%.1f\r\nForecast,%.1f\r\n"
                                     "InvestorRating,%.1f\r\nNetProfit,%.2f\r\nPF,%.2f\r\nMaxDD,%.2f\r\n",
                                     r.report_quality, r.bi_score, r.performance_forecast,
                                     r.investor_rating, r.net_profit, r.profit_factor,
                                     r.max_drawdown_pct));

      m_files.WriteText(m_pfx + "reports_export.json",
                        StringFormat("{\"quality\":%.1f,\"bi\":%.1f,\"forecast\":%.1f,\"rating\":%.1f,\"net\":%.2f}\r\n",
                                     r.report_quality, r.bi_score, r.performance_forecast,
                                     r.investor_rating, r.net_profit));

      m_files.WriteText(m_pfx + "reports_export.html",
                        "<html><body><h1>Gold Mind Reporting Center</h1><pre>" +
                        r.executive_summary + "</pre></body></html>\r\n");

      m_files.WriteText(m_pfx + "export_pdf.arch.txt", "PDF — architecture reserved\r\n");
      m_files.WriteText(m_pfx + "export_excel.arch.txt", "Excel — architecture reserved\r\n");
      m_files.WriteText(m_pfx + "package_executive.arch.txt", "Executive Report Package — architecture reserved\r\n");
      m_files.WriteText(m_pfx + "package_investor.arch.txt", "Investor Package — architecture reserved\r\n");
      m_files.WriteText(m_pfx + "package_institutional.arch.txt", "Institutional Package — architecture reserved\r\n");

      m_status = "CSV/JSON/HTML Exported | PDF/Excel/Packages ARCH";
      if(m_logger != NULL)
         m_logger.Info("Report Exported | " + m_status, "ERC");
     }
  };

#endif // GM_CERC_EXPORT_CENTER_MQH
//+------------------------------------------------------------------+
