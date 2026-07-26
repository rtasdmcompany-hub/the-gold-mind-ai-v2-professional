//+------------------------------------------------------------------+
//|                                               CRiskEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CRISK_ENGINE_MQH
#define GM_CRISK_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "CRiskBase.mqh"
#include "CAtrEngine.mqh"
#include "CLotSizeEngine.mqh"
#include "CStopLossEngine.mqh"
#include "CTakeProfitEngine.mqh"
#include "CBrokerValidator.mqh"
#include "RiskConstants.mqh"
#include "../Calculation/EnumsLevels.mqh"

/// @file CRiskEngine.mqh
/// @brief Sprint 3 Risk Engine — lot / 30-pip SL / ATR TP / broker gates.

struct SGmRiskPlan
  {
   double lots;
   double sl;
   double tp;
   double sl_distance;
   double atr;
   bool   valid;
  };

class CGmRiskEngine : public CGmRiskBase
  {
private:
   CGmAtrEngine        m_atr;
   CGmLotSizeEngine    m_lots;
   CGmStopLossEngine   m_sl;
   CGmTakeProfitEngine m_tp;
   CGmBrokerValidator  m_broker;
   string              m_symbol;

public:
                     CGmRiskEngine(void)
                       : m_symbol("")
     {
      m_module_name = "RiskEngine";
     }

   virtual          ~CGmRiskEngine(void) {}

   virtual bool Init(CGmLogger *logger)
     {
      CGmRiskBase::Init(logger);
      return true;
     }

   bool InitFull(CGmLogger *logger, const string symbol,
                 const int max_spread_points = GM_MAX_SPREAD_POINTS_DEFAULT)
     {
      m_logger = logger;
      m_symbol = symbol;
      m_module_name = "RiskEngine";

      if(!m_atr.Init(logger, symbol, GM_ATR_PERIOD))
         return false;
      if(!m_lots.Init(logger, symbol, GM_RISK_EQUITY_FRACTION))
         return false;
      if(!m_sl.Init(logger, symbol, GM_FIXED_SL_PIPS))
         return false;
      if(!m_tp.Init(logger, GetPointer(m_atr), symbol))
         return false;
      if(!m_broker.Init(logger, symbol, max_spread_points))
         return false;

      m_status = GM_MODULE_READY;
      if(m_logger != NULL)
         m_logger.Success("Risk Engine online | 3% equity | 30-pip SL | ATR(14) TP", m_module_name);
      return true;
     }

   void SetMaxSpreadPoints(const int max_spread_points)
     {
      m_broker.SetMaxSpreadPoints(max_spread_points);
     }

   virtual void Shutdown(void)
     {
      m_atr.Shutdown();
      m_status = GM_MODULE_DISABLED;
     }

   CGmBrokerValidator *Broker(void) { return GetPointer(m_broker); }
   CGmAtrEngine       *Atr(void) { return GetPointer(m_atr); }
   double              StopDistance(void) const { return m_sl.StopDistancePrice(); }

   /// @brief Build full risk plan for an entry (lot + SL + TP).
   bool BuildPlan(const double entry, const ENUM_GM_LEVEL_SIDE side, SGmRiskPlan &plan)
     {
      plan.lots = 0.0;
      plan.sl = 0.0;
      plan.tp = 0.0;
      plan.sl_distance = 0.0;
      plan.atr = 0.0;
      plan.valid = false;

      const ulong t0 = GetMicrosecondCount();

      plan.sl_distance = m_sl.StopDistancePrice();
      if(!m_sl.CalculateStopLoss(entry, side, plan.sl))
         return false;
      if(!m_tp.CalculateTakeProfit(entry, side, plan.tp))
         return false;
      if(!m_atr.GetAtr(plan.atr))
         return false;
      if(!m_lots.CalculateLots(plan.sl_distance, plan.lots))
         return false;

      plan.valid = true;
      if(m_logger != NULL)
         m_logger.Success(StringFormat("Risk plan | lots=%.2f SL=%.5f TP=%.5f ATR=%.5f | %I64u us",
                                       plan.lots, plan.sl, plan.tp, plan.atr,
                                       GetMicrosecondCount() - t0),
                          m_module_name);
      return true;
     }

   bool ValidatePending(const ENUM_ORDER_TYPE type,
                        const SGmRiskPlan &plan,
                        const double price)
     {
      if(!plan.valid)
         return false;
      return m_broker.ValidatePending(type, plan.lots, price, plan.sl, plan.tp);
     }

   virtual bool ValidateTrade(void)
     {
      return m_broker.ValidateTradingAllowed();
     }
  };

#endif // GM_CRISK_ENGINE_MQH
//+------------------------------------------------------------------+
