//+------------------------------------------------------------------+
//|                                          CEpaExportCenter.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CEPA_EXPORT_CENTER_MQH
#define GM_CEPA_EXPORT_CENTER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmPortfolioAnalyticsResult.mqh"
#include "../Core/CFileManager.mqh"
#include "../Logging/CLogger.mqh"

class CGmEpaExportCenter
  {
private:
   CGmLogger      *m_logger;
   CGmFileManager *m_files;
   string          m_pfx;
   string          m_status;

public:
                     CGmEpaExportCenter(void)
                       : m_logger(NULL), m_files(NULL), m_pfx(""), m_status("Idle") {}

   void Init(CGmLogger *logger, CGmFileManager *files, const string prefix)
     {
      m_logger = logger;
      m_files = files;
      m_pfx = prefix;
      m_status = "Architecture Ready | CSV live | PDF/Excel/Investor = ARCH";
     }

   string Status(void) const { return m_status; }

   void Export(const SGmPortfolioAnalyticsResult &r)
     {
      if(m_files == NULL || !r.valid) return;

      m_files.WriteText(m_pfx + "portfolio_report.csv",
                        "Metric,Value\r\n" +
                        StringFormat("Health,%.1f\r\nCapitalGrowth,%.2f\r\nRiskStab,%.1f\r\n"
                                     "MaxDD,%.2f\r\nPF,%.2f\r\nSharpe,%.2f\r\nGrade,%s\r\n",
                                     r.portfolio_health, r.capital_growth_pct, r.risk_stability,
                                     r.max_drawdown_pct, r.profit_factor, r.sharpe_ratio,
                                     GmEpaGradeName(r.performance_grade)));

      m_files.WriteText(m_pfx + "capital_report.txt", r.capital_report + "\r\n");
      m_files.WriteText(m_pfx + "risk_report.txt", r.risk_report + "\r\n");
      m_files.WriteText(m_pfx + "performance_report.txt", r.performance_report + "\r\n");
      m_files.WriteText(m_pfx + "equity_curves.txt",
                        r.equity_curve_summary + "\r\n" + r.drawdown_curve_summary + "\r\n" +
                        r.monthly_heatmap + "\r\n");

      m_files.WriteText(m_pfx + "export_investor.arch.txt", "Investor Portfolio Report — architecture reserved\r\n");
      m_files.WriteText(m_pfx + "export_pdf.arch.txt", "PDF — architecture reserved\r\n");
      m_files.WriteText(m_pfx + "export_excel.arch.txt", "Excel — architecture reserved\r\n");

      m_status = "CSV Exported | PDF/Excel/Investor ARCH";
      if(m_logger != NULL)
         m_logger.Info("Report Generated | " + m_status, "EPA");
     }
  };

#endif // GM_CEPA_EXPORT_CENTER_MQH
//+------------------------------------------------------------------+
