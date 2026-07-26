//+------------------------------------------------------------------+
//|                                      CStrategyEngineBase.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CSTRATEGY_ENGINE_BASE_MQH
#define GM_CSTRATEGY_ENGINE_BASE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "../Core/EnumsCore.mqh"
#include "../Core/TradingRules.mqh"
#include "../Logging/CLogger.mqh"

/// @file CStrategyEngineBase.mqh
/// @brief Core Strategy Engine base — isolated from Trade/Risk/Recovery/AI.
/// @details Future concrete strategy implements official Gold Mind H4 level
///          calculation and pending-order intent. No direct order send here;
///          intents are handed to the Trade Management Engine.

//+------------------------------------------------------------------+
//| CGmStrategyEngineBase                                            |
//+------------------------------------------------------------------+
class CGmStrategyEngineBase
  {
protected:
   CGmLogger            *m_logger;
   ENUM_GM_MODULE_STATUS m_status;
   string                m_module_name;
   ENUM_TIMEFRAMES       m_strategy_tf;

public:
                     CGmStrategyEngineBase(void)
                       : m_logger(NULL),
                         m_status(GM_MODULE_DISABLED),
                         m_module_name("StrategyEngine"),
                         m_strategy_tf(GM_POLICY_STRATEGY_TIMEFRAME)
     {
     }

   virtual          ~CGmStrategyEngineBase(void) { m_logger = NULL; }

   virtual bool Init(CGmLogger *logger)
     {
      m_logger = logger;
      m_status = GM_MODULE_IDLE;
      m_strategy_tf = GM_POLICY_STRATEGY_TIMEFRAME;
      if(m_logger != NULL)
         m_logger.Info(StringFormat("Strategy Engine base ready | TF=%s | activate_immediately=%d | use_last_closed_H4=%d",
                                    EnumToString(m_strategy_tf),
                                    GM_POLICY_ACTIVATE_IMMEDIATELY,
                                    GM_POLICY_USE_LAST_CLOSED_H4),
                       m_module_name);
      return true;
     }

   virtual void Shutdown(void) { m_status = GM_MODULE_DISABLED; }

   ENUM_GM_MODULE_STATUS Status(void) const { return m_status; }
   ENUM_TIMEFRAMES StrategyTimeframe(void) const { return m_strategy_tf; }
   string ModuleName(void) const { return m_module_name; }

   /// @brief Future: evaluate last closed H4 and produce level/order intents.
   /// @note Must NOT wait for the next H4 open — uses last CLOSED H4.
   virtual bool EvaluateCycle(void) { return false; }

   /// @brief Future: handle a newly closed H4 candle.
   virtual bool OnH4Closed(void) { return false; }
  };

#endif // GM_CSTRATEGY_ENGINE_BASE_MQH
//+------------------------------------------------------------------+
