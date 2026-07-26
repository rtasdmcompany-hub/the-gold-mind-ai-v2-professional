//+------------------------------------------------------------------+
//|                                     CEifDeviceGroupManager.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CEIF_DEVICE_GROUP_MANAGER_MQH
#define GM_CEIF_DEVICE_GROUP_MANAGER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "InfrastructureConstants.mqh"
#include "SGmInfrastructureResult.mqh"

class CGmEifDeviceGroupManager
  {
private:
   ENUM_GM_EIF_DEVICE_GROUP m_filter;
   string                   m_search;
   bool                     m_ready;

public:
                     CGmEifDeviceGroupManager(void)
                       : m_filter(GM_EIF_GROUP_CUSTOM), m_search(""), m_ready(false) {}

   bool Init(void)
     {
      m_filter = GM_EIF_GROUP_CUSTOM; // CUSTOM = show all groups in Sprint 4
      m_search = "";
      m_ready = true;
      return true;
     }

   void SetFilter(const ENUM_GM_EIF_DEVICE_GROUP g) { m_filter = g; }
   void SetSearch(const string q) { m_search = q; }

   ENUM_GM_EIF_DEVICE_GROUP Filter(void) const { return m_filter; }
   string Search(void) const { return m_search; }

   bool Passes(const SGmEifTerminalRecord &rec) const
     {
      if(!m_ready) return false;
      // CUSTOM filter = all groups
      if(m_filter != GM_EIF_GROUP_CUSTOM && rec.group != m_filter)
         return false;
      if(StringLen(m_search) == 0)
         return true;
      const string hay = rec.terminal_name + "|" + rec.device_name + "|" +
                         rec.broker + "|" + rec.server;
      return (StringFind(hay, m_search) >= 0);
     }

   string Summary(void) const
     {
      return "Filter=" + GmEifGroupName(m_filter) +
             (StringLen(m_search) > 0 ? (" | Search=" + m_search) : " | Search=*");
     }
  };

#endif // GM_CEIF_DEVICE_GROUP_MANAGER_MQH
//+------------------------------------------------------------------+
