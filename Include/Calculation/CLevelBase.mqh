//+------------------------------------------------------------------+
//|                                                 CLevelBase.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CLEVEL_BASE_MQH
#define GM_CLEVEL_BASE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "../Core/EnumsCore.mqh"
#include "../Logging/CLogger.mqh"

/// @file CLevelBase.mqh
/// @brief Abstract base for price-level calculation modules.

class CGmLevelBase
  {
protected:
   CGmLogger            *m_logger;
   ENUM_GM_MODULE_STATUS m_status;
   string                m_module_name;

public:
                     CGmLevelBase(void)
                       : m_logger(NULL),
                         m_status(GM_MODULE_DISABLED),
                         m_module_name("LevelBase")
     {
     }

   virtual          ~CGmLevelBase(void) { m_logger = NULL; }

   virtual bool Init(CGmLogger *logger)
     {
      m_logger = logger;
      m_status = GM_MODULE_IDLE;
      return true;
     }

   virtual void Shutdown(void) { m_status = GM_MODULE_DISABLED; }

   ENUM_GM_MODULE_STATUS Status(void) const { return m_status; }
   string ModuleName(void) const { return m_module_name; }

   virtual bool Recalculate(void) { return false; }
  };

#endif // GM_CLEVEL_BASE_MQH
//+------------------------------------------------------------------+
