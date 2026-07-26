//+------------------------------------------------------------------+
//|                                             CAnalyticsBase.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CANALYTICS_BASE_MQH
#define GM_CANALYTICS_BASE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "../Core/EnumsCore.mqh"
#include "../Logging/CLogger.mqh"

/// @file CAnalyticsBase.mqh
/// @brief Analytics Engine base — isolated observation / reporting layer.
/// @warning Must never send, modify, or close trades. Read-only by contract.

//+------------------------------------------------------------------+
//| CGmAnalyticsBase                                                 |
//+------------------------------------------------------------------+
class CGmAnalyticsBase
  {
protected:
   CGmLogger            *m_logger;
   ENUM_GM_MODULE_STATUS m_status;
   string                m_module_name;

public:
                     CGmAnalyticsBase(void)
                       : m_logger(NULL),
                         m_status(GM_MODULE_DISABLED),
                         m_module_name("AnalyticsEngine")
     {
     }

   virtual          ~CGmAnalyticsBase(void) { m_logger = NULL; }

   virtual bool Init(CGmLogger *logger)
     {
      m_logger = logger;
      m_status = GM_MODULE_IDLE;
      if(m_logger != NULL)
         m_logger.Info("Analytics Engine base ready (read-only; no trade interference)", m_module_name);
      return true;
     }

   virtual void Shutdown(void) { m_status = GM_MODULE_DISABLED; }

   ENUM_GM_MODULE_STATUS Status(void) const { return m_status; }
   string ModuleName(void) const { return m_module_name; }

   /// @brief Future: collect performance / cycle analytics snapshots.
   virtual bool Collect(void) { return false; }
  };

#endif // GM_CANALYTICS_BASE_MQH
//+------------------------------------------------------------------+
