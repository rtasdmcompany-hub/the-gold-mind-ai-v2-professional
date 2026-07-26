//+------------------------------------------------------------------+
//|                                    CMacAccountClusterManager.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CMAC_ACCOUNT_CLUSTER_MANAGER_MQH
#define GM_CMAC_ACCOUNT_CLUSTER_MANAGER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmMultiAccountCenterResult.mqh"
#include "../Logging/CLogger.mqh"

class CGmMacAccountClusterManager
  {
private:
   CGmLogger          *m_logger;
   ENUM_GM_MAC_CLUSTER m_primary;
   string              m_filter;
   string              m_sort;

public:
                     CGmMacAccountClusterManager(void)
                       : m_logger(NULL),
                         m_primary(GM_MAC_CL_PRODUCTION),
                         m_filter("All"),
                         m_sort("HealthDesc") {}

   void Init(CGmLogger *logger)
     {
      m_logger = logger;
      m_primary = GM_MAC_CL_PRODUCTION;
      m_filter = "All";
      m_sort = "HealthDesc";
     }

   ENUM_GM_MAC_CLUSTER Primary(void) const { return m_primary; }

   void SetPrimary(const ENUM_GM_MAC_CLUSTER c)
     {
      m_primary = c;
      if(m_logger != NULL)
         m_logger.Info("Cluster Updated | Primary=" + GmMacClusterName(c), "MAC");
     }

   void ApplyToResult(SGmMultiAccountCenterResult &out) const
     {
      out.primary_cluster = m_primary;
      out.cluster_overview = StringFormat(
         "=== ACCOUNT CLUSTERS ===\r\n"
         "Primary=%s | Filter=%s | Sort=%s\r\n"
         "Groups: Personal/Funded/Investor/Client/Testing/Production/Custom\r\n"
         "Search/Filter/Sort = Catalog Ready | Licensed accounts only\r\n",
         GmMacClusterName(m_primary), m_filter, m_sort);
     }
  };

#endif // GM_CMAC_ACCOUNT_CLUSTER_MANAGER_MQH
//+------------------------------------------------------------------+
