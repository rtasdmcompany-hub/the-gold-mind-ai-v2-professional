//+------------------------------------------------------------------+
//|                                          CAISecurityGuard.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CAI_SECURITY_GUARD_MQH
#define GM_CAI_SECURITY_GUARD_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "../../Logging/CLogger.mqh"

/// @file CAISecurityGuard.mqh
/// @brief Hard gate — AI may NEVER execute or mutate trades (Phase 3).

class CGmAISecurityGuard
  {
private:
   CGmLogger *m_logger;
   ulong      m_blocked;
   bool       m_ready;

   void Block(const string action)
     {
      m_blocked++;
      if(m_logger != NULL)
         m_logger.Warning(StringFormat("AI SECURITY BLOCK | %s | ANALYSIS ONLY", action),
                          "AISecurity");
     }

public:
                     CGmAISecurityGuard(void)
                       : m_logger(NULL), m_blocked(0), m_ready(false) {}

   void Init(CGmLogger *logger)
     {
      m_logger = logger;
      m_blocked = 0;
      m_ready = true;
      if(m_logger != NULL)
         m_logger.Success("AI Security Guard armed | ANALYSIS ONLY | no trade APIs",
                          "AISecurity");
     }

   bool IsReady(void) const { return m_ready; }
   ulong BlockedCount(void) const { return m_blocked; }
   bool AllowsExecution(void) const { return false; }
   bool IsAnalysisOnly(void) const { return true; }

   bool RequestOpenTrade(void)      { Block("OpenTrade"); return false; }
   bool RequestCloseTrade(void)     { Block("CloseTrade"); return false; }
   bool RequestModifyOrder(void)    { Block("ModifyOrder"); return false; }
   bool RequestModifySL(void)       { Block("ModifySL"); return false; }
   bool RequestModifyTP(void)       { Block("ModifyTP"); return false; }
   bool RequestModifyRisk(void)     { Block("ModifyRisk"); return false; }
   bool RequestDeletePending(void)  { Block("DeletePending"); return false; }
   bool RequestOverrideEngine(void) { Block("OverrideTradingEngine"); return false; }
  };

#endif // GM_CAI_SECURITY_GUARD_MQH
//+------------------------------------------------------------------+
