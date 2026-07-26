//+------------------------------------------------------------------+
//|                                         CProfitMonitor.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CPROFIT_MONITOR_MQH
#define GM_CPROFIT_MONITOR_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "CPipTools.mqh"
#include "TradeMgmtConstants.mqh"
#include "../Logging/CLogger.mqh"
#include "../Trading/CTradeOwnership.mqh"

/// @file CProfitMonitor.mqh
/// @brief Monitors only Gold Mind Magic Number positions for pip profit.

class CGmProfitMonitor
  {
private:
   CGmLogger         *m_logger;
   CGmTradeOwnership *m_ownership;
   string             m_symbol;
   long               m_magic;

public:
                     CGmProfitMonitor(void)
                       : m_logger(NULL), m_ownership(NULL), m_symbol(""), m_magic(0) {}
                    ~CGmProfitMonitor(void)
     {
      m_logger = NULL;
      m_ownership = NULL;
     }

   void Init(CGmLogger *logger, CGmTradeOwnership *ownership,
             const string symbol, const long magic)
     {
      m_logger = logger;
      m_ownership = ownership;
      m_symbol = symbol;
      m_magic = magic;
      if(m_logger != NULL)
         m_logger.Info("Profit Monitor ready | Magic-only", "ProfitMonitor");
     }

   bool IsOwnPosition(const ulong ticket) const
     {
      if(ticket == 0 || !PositionSelectByTicket(ticket))
         return false;
      if((long)PositionGetInteger(POSITION_MAGIC) != m_magic)
         return false;
      if(PositionGetString(POSITION_SYMBOL) != m_symbol)
         return false;
      if(m_ownership != NULL && !m_ownership.CanManagePosition(ticket, true))
         return false;
      return true;
     }

   double CurrentProfitPips(const ulong ticket) const
     {
      if(!PositionSelectByTicket(ticket))
         return 0.0;
      return CGmPipTools::ProfitPips(m_symbol,
                                     PositionGetInteger(POSITION_TYPE),
                                     PositionGetDouble(POSITION_PRICE_OPEN));
     }

   double CurrentProfitMoney(const ulong ticket) const
     {
      if(!PositionSelectByTicket(ticket))
         return 0.0;
      return PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
     }

   bool ReachedBreakEvenTrigger(const ulong ticket) const
     {
      return (CurrentProfitPips(ticket) >= GM_BE_TRIGGER_PIPS);
     }
  };

#endif // GM_CPROFIT_MONITOR_MQH
//+------------------------------------------------------------------+
