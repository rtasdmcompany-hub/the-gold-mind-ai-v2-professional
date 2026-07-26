//+------------------------------------------------------------------+
//|                                                 CTradeBase.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|                        Copyright 2026, RTAS Softwear            |
//+------------------------------------------------------------------+
#ifndef GM_CTRADE_BASE_MQH
#define GM_CTRADE_BASE_MQH
#property copyright "Copyright 2026, RTAS Softwear"
#property link      "https://rtas.softwear"

#include "../Core/EnumsCore.mqh"
#include "../Logging/CLogger.mqh"

/// @file CTradeBase.mqh
/// @brief Abstract base for future trade orchestration modules.
/// @warning Sprint 1: skeleton only — no buy/sell, no order send.

//+------------------------------------------------------------------+
//| CGmTradeBase                                                     |
//+------------------------------------------------------------------+
class CGmTradeBase
  {
protected:
   CGmLogger            *m_logger;
   ENUM_GM_MODULE_STATUS m_status;
   string                m_module_name;

public:
                     CGmTradeBase(void)
                       : m_logger(NULL),
                         m_status(GM_MODULE_DISABLED),
                         m_module_name("TradeBase")
     {
     }

   virtual          ~CGmTradeBase(void) { m_logger = NULL; }

   virtual bool Init(CGmLogger *logger)
     {
      m_logger = logger;
      m_status = GM_MODULE_IDLE;
      if(m_logger != NULL)
         m_logger.Info("Trade base registered (disabled until Trading sprint)", m_module_name);
      return true;
     }

   virtual void Shutdown(void)
     {
      m_status = GM_MODULE_DISABLED;
     }

   ENUM_GM_MODULE_STATUS Status(void) const { return m_status; }
   string ModuleName(void) const { return m_module_name; }

   /// @brief Future: process strategy signals into trade actions.
   virtual bool Process(void)
     {
      return false;
     }
  };

#endif // GM_CTRADE_BASE_MQH
//+------------------------------------------------------------------+
