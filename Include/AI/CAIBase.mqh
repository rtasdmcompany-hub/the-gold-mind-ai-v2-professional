//+------------------------------------------------------------------+
//|                                                    CAIBase.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|                        Copyright 2026, RTAS Softwear            |
//+------------------------------------------------------------------+
#ifndef GM_CAI_BASE_MQH
#define GM_CAI_BASE_MQH
#property copyright "Copyright 2026, RTAS Softwear"
#property link      "https://rtas.softwear"

#include "../Core/EnumsCore.mqh"
#include "../Logging/CLogger.mqh"

/// @file CAIBase.mqh
/// @brief Abstract base for future AI / ML decision modules.
/// @warning Sprint 1: skeleton only — no inference, no signals, no models.

//+------------------------------------------------------------------+
//| CGmAIBase                                                        |
//+------------------------------------------------------------------+
class CGmAIBase
  {
protected:
   CGmLogger            *m_logger;
   ENUM_GM_MODULE_STATUS m_status;
   string                m_module_name;

public:
                     CGmAIBase(void)
                       : m_logger(NULL),
                         m_status(GM_MODULE_DISABLED),
                         m_module_name("AIBase")
     {
     }

   virtual          ~CGmAIBase(void) { m_logger = NULL; }

   /// @brief Framework init — subclasses override for model bootstrap.
   virtual bool Init(CGmLogger *logger)
     {
      m_logger = logger;
      m_status = GM_MODULE_IDLE;
      if(m_logger != NULL)
         m_logger.Info("AI base registered (disabled until AI sprint)", m_module_name);
      return true;
     }

   virtual void Shutdown(void)
     {
      m_status = GM_MODULE_DISABLED;
     }

   ENUM_GM_MODULE_STATUS Status(void) const { return m_status; }
   string ModuleName(void) const { return m_module_name; }

   /// @brief Future: evaluate market context and emit AI advisory.
   /// @return false in Sprint 1 (not implemented).
   virtual bool Evaluate(void)
     {
      return false;
     }
  };

#endif // GM_CAI_BASE_MQH
//+------------------------------------------------------------------+
