//+------------------------------------------------------------------+
//|                                          CTradeOwnership.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CTRADE_OWNERSHIP_MQH
#define GM_CTRADE_OWNERSHIP_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "../Core/TradingRules.mqh"
#include "../Logging/CLogger.mqh"

/// @file CTradeOwnership.mqh
/// @brief Magic Number ownership gate — enforces Rules #1–#4.
/// @details ALL trade management engines MUST call this gate before any
///          modify / close / trail / hedge / SL / TP action.
///          Sprint 1: ownership API only — no management actions.

//+------------------------------------------------------------------+
//| CGmTradeOwnership                                                |
//+------------------------------------------------------------------+
class CGmTradeOwnership
  {
private:
   CGmLogger *m_logger;
   long       m_magic;
   string     m_symbol;
   bool       m_initialized;
   ulong      m_rejected_count;

public:
                     CGmTradeOwnership(void)
                       : m_logger(NULL),
                         m_magic(0),
                         m_symbol(""),
                         m_initialized(false),
                         m_rejected_count(0)
     {
     }

                    ~CGmTradeOwnership(void) { m_logger = NULL; }

   /// @brief Binds the sole Magic Number this EA instance may manage.
   bool Init(CGmLogger *logger, const long magic_number, const string symbol)
     {
      m_logger = logger;
      m_magic = magic_number;
      m_symbol = symbol;
      m_rejected_count = 0;
      m_initialized = (m_magic != GM_MAGIC_MANUAL_TRADE);

      if(!m_initialized)
        {
         if(m_logger != NULL)
            m_logger.Error("Magic Number cannot be 0 (reserved for manual trades)", "Ownership");
         return false;
        }

      if(m_logger != NULL)
        {
         m_logger.Success(StringFormat("Ownership gate armed | Magic=%I64d | Symbol=%s",
                                       m_magic, m_symbol),
                          "Ownership");
         m_logger.Info("Rule#1 Own-trades-only | Rule#2 Ignore-manual | Rule#3 Ignore-foreign-EA | Rule#4 Magic-gate",
                       "Ownership");
        }
      return true;
     }

   bool IsInitialized(void) const { return m_initialized; }
   long MagicNumber(void) const { return m_magic; }
   string Symbol(void) const { return m_symbol; }
   ulong RejectedCount(void) const { return m_rejected_count; }

   /// @brief True when magic equals this EA's configured Magic Number.
   bool IsOwnMagic(const long magic) const
     {
      if(!m_initialized)
         return false;
      return (magic == m_magic);
     }

   /// @brief True when magic is treated as a manual trade (never manage).
   bool IsManualMagic(const long magic) const
     {
      return (magic == GM_MAGIC_MANUAL_TRADE);
     }

   /// @brief True when magic belongs to another EA (never manage).
   bool IsForeignMagic(const long magic) const
     {
      if(IsManualMagic(magic))
         return false;
      return !IsOwnMagic(magic);
     }

   /// @brief Hard gate: may this EA manage a ticket with the given magic?
   /// @return true only for own Magic Number.
   bool CanManageMagic(const long magic)
     {
      if(IsOwnMagic(magic))
         return true;

      m_rejected_count++;
      return false;
     }

   /// @brief Ownership check for an open position ticket (selects position).
   /// @return true only if position exists, matches symbol (optional), and own magic.
   bool CanManagePosition(const ulong ticket, const bool require_symbol_match = true)
     {
      if(!m_initialized)
         return false;
      if(!PositionSelectByTicket(ticket))
        {
         m_rejected_count++;
         return false;
        }

      const long magic = PositionGetInteger(POSITION_MAGIC);
      if(!IsOwnMagic(magic))
        {
         m_rejected_count++;
         return false;
        }

      if(require_symbol_match)
        {
         const string pos_symbol = PositionGetString(POSITION_SYMBOL);
         if(pos_symbol != m_symbol)
           {
            m_rejected_count++;
            return false;
           }
        }
      return true;
     }

   /// @brief Ownership check for a pending order ticket (selects order).
   bool CanManageOrder(const ulong ticket, const bool require_symbol_match = true)
     {
      if(!m_initialized)
         return false;
      if(!OrderSelect(ticket))
        {
         m_rejected_count++;
         return false;
        }

      const long magic = OrderGetInteger(ORDER_MAGIC);
      if(!IsOwnMagic(magic))
        {
         m_rejected_count++;
         return false;
        }

      if(require_symbol_match)
        {
         const string ord_symbol = OrderGetString(ORDER_SYMBOL);
         if(ord_symbol != m_symbol)
           {
            m_rejected_count++;
            return false;
           }
        }
      return true;
     }

   /// @brief Counts currently open positions owned by this EA (symbol-scoped).
   int CountOwnPositions(void) const
     {
      if(!m_initialized)
         return 0;

      int count = 0;
      const int total = PositionsTotal();
      for(int i = 0; i < total; i++)
        {
         const ulong ticket = PositionGetTicket(i);
         if(ticket == 0)
            continue;
         if(!PositionSelectByTicket(ticket))
            continue;
         if(PositionGetString(POSITION_SYMBOL) != m_symbol)
            continue;
         if((long)PositionGetInteger(POSITION_MAGIC) != m_magic)
            continue;
         count++;
        }
      return count;
     }

   /// @brief Counts currently pending orders owned by this EA (symbol-scoped).
   int CountOwnPendingOrders(void) const
     {
      if(!m_initialized)
         return 0;

      int count = 0;
      const int total = OrdersTotal();
      for(int i = 0; i < total; i++)
        {
         const ulong ticket = OrderGetTicket(i);
         if(ticket == 0)
            continue;
         if(!OrderSelect(ticket))
            continue;
         if(OrderGetString(ORDER_SYMBOL) != m_symbol)
            continue;
         if((long)OrderGetInteger(ORDER_MAGIC) != m_magic)
            continue;
         count++;
        }
      return count;
     }
  };

#endif // GM_CTRADE_OWNERSHIP_MQH
//+------------------------------------------------------------------+
