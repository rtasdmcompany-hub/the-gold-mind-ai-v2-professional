//+------------------------------------------------------------------+
//|                                                  CRiskBase.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|                        Copyright 2026, RTAS Softwear            |
//+------------------------------------------------------------------+
#ifndef GM_CRISK_BASE_MQH
#define GM_CRISK_BASE_MQH
#property copyright "Copyright 2026, RTAS Softwear"
#property link      "https://rtas.softwear"

#include "../Core/EnumsCore.mqh"
#include "../Logging/CLogger.mqh"

/// @file CRiskBase.mqh
/// @brief Abstract base for future risk / money-management modules.
/// @warning Sprint 1: skeleton only — no lot sizing, SL/TP, or exposure logic.

//+------------------------------------------------------------------+
//| CGmRiskBase                                                      |
//+------------------------------------------------------------------+
class CGmRiskBase
  {
protected:
   CGmLogger            *m_logger;
   ENUM_GM_MODULE_STATUS m_status;
   string                m_module_name;

public:
                     CGmRiskBase(void)
                       : m_logger(NULL),
                         m_status(GM_MODULE_DISABLED),
                         m_module_name("RiskBase")
     {
     }

   virtual          ~CGmRiskBase(void) { m_logger = NULL; }

   virtual bool Init(CGmLogger *logger)
     {
      m_logger = logger;
      m_status = GM_MODULE_IDLE;
      return true;
     }

   virtual void Shutdown(void)
     {
      m_status = GM_MODULE_DISABLED;
     }

   ENUM_GM_MODULE_STATUS Status(void) const { return m_status; }
   string ModuleName(void) const { return m_module_name; }

   /// @brief Future: validate whether a proposed trade passes risk gates.
   virtual bool ValidateTrade(void)
     {
      return false;
     }
  };

#endif // GM_CRISK_BASE_MQH
//+------------------------------------------------------------------+
