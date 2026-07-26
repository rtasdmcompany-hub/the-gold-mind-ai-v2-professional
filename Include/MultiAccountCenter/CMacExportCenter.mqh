//+------------------------------------------------------------------+
//|                                        CMacExportCenter.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CMAC_EXPORT_CENTER_MQH
#define GM_CMAC_EXPORT_CENTER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmMultiAccountCenterResult.mqh"
#include "../Core/CFileManager.mqh"
#include "../Logging/CLogger.mqh"

class CGmMacExportCenter
  {
private:
   CGmLogger      *m_logger;
   CGmFileManager *m_files;
   string          m_pfx;
   string          m_status;

public:
                     CGmMacExportCenter(void)
                       : m_logger(NULL), m_files(NULL), m_pfx(""), m_status("Idle") {}

   void Init(CGmLogger *logger, CGmFileManager *files, const string prefix)
     {
      m_logger = logger;
      m_files = files;
      m_pfx = prefix;
      m_status = "Architecture Ready | CSV/TXT stubs";
     }

   string Status(void) const { return m_status; }

   void Export(const SGmMultiAccountCenterResult &r)
     {
      if(m_files == NULL || !r.valid) return;

      m_files.WriteText(m_pfx + "account_list.txt", r.account_list);
      m_files.WriteText(m_pfx + "cluster_overview.txt", r.cluster_overview);
      m_files.WriteText(m_pfx + "capital_allocation.txt", r.capital_report);
      m_files.WriteText(m_pfx + "performance_comparison.txt", r.comparison_report);
      m_files.WriteText(m_pfx + "rankings.txt", r.ranking_report);
      m_files.WriteText(m_pfx + "enterprise_monitoring.txt", r.monitoring_summary);
      m_files.WriteText(m_pfx + "institutional_summary.txt", r.institutional_summary);

      m_files.WriteText(m_pfx + "mac_export.csv",
                        "Metric,Value\r\n" +
                        StringFormat("AccountHealth,%.1f\r\nCapitalAlloc,%.1f\r\n"
                                     "PortfolioBalance,%.1f\r\nEnterpriseHealth,%.1f\r\n"
                                     "Licensed,%d\r\nExcluded,%d\r\n",
                                     r.account_health, r.capital_allocation_score,
                                     r.portfolio_balance_score, r.enterprise_health,
                                     r.accounts_licensed, r.accounts_excluded_unlicensed));

      m_status = "CSV/TXT Exported";
      if(m_logger != NULL)
         m_logger.Info("Database Updated | MAC export " + m_status, "MAC");
     }
  };

#endif // GM_CMAC_EXPORT_CENTER_MQH
//+------------------------------------------------------------------+
