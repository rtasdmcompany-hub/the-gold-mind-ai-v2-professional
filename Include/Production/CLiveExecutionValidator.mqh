//+------------------------------------------------------------------+
//|                                   CLiveExecutionValidator.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CLIVE_EXECUTION_VALIDATOR_MQH
#define GM_CLIVE_EXECUTION_VALIDATOR_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "CEnterpriseLogContext.mqh"
#include "../Risk/RiskConstants.mqh"
#include "../TradeManagement/TradeMgmtConstants.mqh"
#include "../TradeManagement/CPipTools.mqh"
#include "../Trading/CTradeOwnership.mqh"
#include "../Trading/CTradeRegistry.mqh"
#include "../Trading/CTradeIdManager.mqh"
#include "../Session/CH4SessionEngine.mqh"

/// @file CLiveExecutionValidator.mqh
/// @brief Live execution sanity checks (read-only warnings; no strategy change).

class CGmLiveExecutionValidator
  {
private:
   CGmLogger               *m_logger;
   CGmEnterpriseLogContext *m_elog;
   CGmTradeOwnership       *m_ownership;
   CGmTradeRegistry        *m_registry;
   CGmH4SessionEngine      *m_session;
   string                   m_symbol;
   long                     m_magic;
   bool                     m_enabled;
   int                      m_warns;

public:
                     CGmLiveExecutionValidator(void)
                       : m_logger(NULL), m_elog(NULL), m_ownership(NULL),
                         m_registry(NULL), m_session(NULL),
                         m_symbol(""), m_magic(0), m_enabled(true), m_warns(0)
     {
     }

                    ~CGmLiveExecutionValidator(void)
     {
      m_logger = NULL;
      m_elog = NULL;
      m_ownership = NULL;
      m_registry = NULL;
      m_session = NULL;
     }

   void Init(CGmLogger *logger,
             CGmEnterpriseLogContext *elog,
             CGmTradeOwnership *ownership,
             CGmTradeRegistry *registry,
             CGmH4SessionEngine *session,
             const string symbol,
             const long magic,
             const bool enabled)
     {
      m_logger = logger;
      m_elog = elog;
      m_ownership = ownership;
      m_registry = registry;
      m_session = session;
      m_symbol = symbol;
      m_magic = magic;
      m_enabled = enabled;
     }

   int WarningCount(void) const { return m_warns; }

   void Warn(const string msg)
     {
      m_warns++;
      if(m_elog != NULL)
         m_elog.Emit(GM_LOG_WARNING, "LiveExec", msg, 0, 0, 0, 0, "Review live execution");
      else if(m_logger != NULL)
         m_logger.Warning(msg, "LiveExec");
     }

   int Run(void)
     {
      m_warns = 0;
      if(!m_enabled)
         return 0;

      // Duplicate pending tags
      string seen_tags = "|";
      const int ot = OrdersTotal();
      for(int i = 0; i < ot; i++)
        {
         const ulong ticket = OrderGetTicket(i);
         if(ticket == 0 || !OrderSelect(ticket))
            continue;
         if((long)OrderGetInteger(ORDER_MAGIC) != m_magic)
            continue;
         if(OrderGetString(ORDER_SYMBOL) != m_symbol)
            continue;
         const string tag = CGmTradeIdManager::ExtractLevelTag(OrderGetString(ORDER_COMMENT));
         if(StringLen(tag) == 0)
            continue;
         if(StringFind(seen_tags, "|" + tag + "|") >= 0)
            Warn(StringFormat("Duplicate Pending Order | tag=%s", tag));
         else
            seen_tags += tag + "|";
        }

      // Open positions SL/TP
      const int pt = PositionsTotal();
      for(int p = 0; p < pt; p++)
        {
         const ulong ticket = PositionGetTicket(p);
         if(ticket == 0 || !PositionSelectByTicket(ticket))
            continue;
         if((long)PositionGetInteger(POSITION_MAGIC) != m_magic)
            continue;
         if(PositionGetString(POSITION_SYMBOL) != m_symbol)
            continue;
         if(PositionGetDouble(POSITION_SL) <= 0.0)
            Warn(StringFormat("Missing SL | ticket=%I64u", ticket));
         if(PositionGetDouble(POSITION_TP) <= 0.0)
            Warn(StringFormat("Missing TP | ticket=%I64u", ticket));

         if(m_registry != NULL)
           {
            SGmTradeRecord rec;
            if(m_registry.GetByTicket(ticket, rec))
              {
               if(rec.be_done && !rec.trailing_active)
                 {
                  const double open = PositionGetDouble(POSITION_PRICE_OPEN);
                  const double sl = PositionGetDouble(POSITION_SL);
                  const double pip = CGmPipTools::PipSize(m_symbol);
                  if(pip > 0.0 && MathAbs(sl - open) > pip * 3.0)
                     Warn(StringFormat("BE inconsistency | ticket=%I64u", ticket));
                 }
               if(rec.partial_done && rec.original_volume > 0.0)
                 {
                  const double vol = PositionGetDouble(POSITION_VOLUME);
                  const double runner = rec.original_volume * (GM_RUNNER_PERCENT / 100.0);
                  if(vol > runner * 1.6 + 1e-8)
                     Warn(StringFormat("Partial/runner volume check | ticket=%I64u", ticket));
                 }
              }
           }
        }

      if(m_session != NULL && m_session.CurrentSessionId() == 0 &&
         m_ownership != NULL && m_ownership.CountOwnPendingOrders() > 0)
         Warn("Session Reset check | pendings exist without active session id");

      if(m_logger != NULL)
         m_logger.Info(StringFormat("Live execution validation | warnings=%d", m_warns),
                       "LiveExec");
      return m_warns;
     }
  };

#endif // GM_CLIVE_EXECUTION_VALIDATOR_MQH
//+------------------------------------------------------------------+
