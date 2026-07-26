//+------------------------------------------------------------------+
//|                                            CTradeIdManager.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CTRADE_ID_MANAGER_MQH
#define GM_CTRADE_ID_MANAGER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "../Calculation/LevelConstants.mqh"
#include "../Logging/CLogger.mqh"
#include "../Trading/CTradeOwnership.mqh"

/// @file CTradeIdManager.mqh
/// @brief Internal unique Trade ID allocator for analytics / recovery / tracking.
/// @details IDs persist across restarts via GlobalVariable + live order scan.
///          Comment format: "{LEVEL_TAG}#T{id}" e.g. GM_BL1#T10042

//+------------------------------------------------------------------+
//| CGmTradeIdManager                                                |
//+------------------------------------------------------------------+
class CGmTradeIdManager
  {
private:
   CGmLogger         *m_logger;
   CGmTradeOwnership *m_ownership;
   long               m_magic;
   string             m_symbol;
   ulong              m_next_id;
   string             m_gv_name;
   bool               m_initialized;

   string BuildGvName(void) const
     {
      return StringFormat("GM_TID_%I64d", m_magic);
     }

   ulong ParseTradeIdFromComment(const string comment) const
     {
      const int pos = StringFind(comment, GM_TRADE_ID_MARKER);
      if(pos < 0)
         return 0;
      const string id_str = StringSubstr(comment, pos + StringLen(GM_TRADE_ID_MARKER));
      return (ulong)StringToInteger(id_str);
     }

   /// @brief Scans own pendings + positions for max embedded Trade ID.
   ulong ScanMaxExistingId(void) const
     {
      ulong max_id = 0;

      const int orders = OrdersTotal();
      for(int i = 0; i < orders; i++)
        {
         const ulong ticket = OrderGetTicket(i);
         if(ticket == 0 || !OrderSelect(ticket))
            continue;
         if((long)OrderGetInteger(ORDER_MAGIC) != m_magic)
            continue;
         if(OrderGetString(ORDER_SYMBOL) != m_symbol)
            continue;
         const ulong tid = ParseTradeIdFromComment(OrderGetString(ORDER_COMMENT));
         if(tid > max_id)
            max_id = tid;
        }

      const int positions = PositionsTotal();
      for(int p = 0; p < positions; p++)
        {
         const ulong ticket = PositionGetTicket(p);
         if(ticket == 0 || !PositionSelectByTicket(ticket))
            continue;
         if((long)PositionGetInteger(POSITION_MAGIC) != m_magic)
            continue;
         if(PositionGetString(POSITION_SYMBOL) != m_symbol)
            continue;
         const ulong tid = ParseTradeIdFromComment(PositionGetString(POSITION_COMMENT));
         if(tid > max_id)
            max_id = tid;
        }

      return max_id;
     }

public:
                     CGmTradeIdManager(void)
                       : m_logger(NULL),
                         m_ownership(NULL),
                         m_magic(0),
                         m_symbol(""),
                         m_next_id(1),
                         m_gv_name(""),
                         m_initialized(false)
     {
     }

                    ~CGmTradeIdManager(void)
     {
      m_logger = NULL;
      m_ownership = NULL;
     }

   bool Init(CGmLogger *logger, CGmTradeOwnership *ownership, const long magic, const string symbol)
     {
      m_logger = logger;
      m_ownership = ownership;
      m_magic = magic;
      m_symbol = symbol;
      m_gv_name = BuildGvName();

      ulong from_gv = 0;
      if(GlobalVariableCheck(m_gv_name))
         from_gv = (ulong)GlobalVariableGet(m_gv_name);

      const ulong from_scan = ScanMaxExistingId();
      const ulong seed = (from_gv > from_scan) ? from_gv : from_scan;
      m_next_id = (seed > 0) ? (seed + 1) : 1;
      Persist();

      m_initialized = true;
      if(m_logger != NULL)
         m_logger.Info(StringFormat("Trade ID manager ready | next_id=%I64u | gv=%s | recovered_max=%I64u",
                                    m_next_id, m_gv_name, seed),
                       "TradeID");
      return true;
     }

   void Shutdown(void)
     {
      if(m_initialized)
         Persist();
      m_initialized = false;
     }

   bool IsInitialized(void) const { return m_initialized; }
   ulong PeekNext(void) const { return m_next_id; }

   void Persist(void)
     {
      if(StringLen(m_gv_name) == 0)
         return;
      // Store last issued id (next-1), or 0 if none issued yet.
      const double store = (m_next_id > 1) ? (double)(m_next_id - 1) : 0.0;
      GlobalVariableSet(m_gv_name, store);
     }

   /// @brief Allocates a new unique Trade ID (never reused).
   ulong Allocate(void)
     {
      if(!m_initialized)
         return 0;
      const ulong id = m_next_id;
      m_next_id++;
      Persist();
      if(m_logger != NULL)
         m_logger.Info(StringFormat("Trade ID allocated | id=%I64u", id), "TradeID");
      return id;
     }

   /// @brief Builds order comment: LEVEL_TAG + #T + id
   string BuildComment(const string level_tag, const ulong trade_id) const
     {
      return StringFormat("%s%s%I64u", level_tag, GM_TRADE_ID_MARKER, trade_id);
     }

   /// @brief Extracts level tag prefix (GM_BLx / GM_SLx) from a comment.
   static string ExtractLevelTag(const string comment)
     {
      const int pos = StringFind(comment, GM_TRADE_ID_MARKER);
      if(pos > 0)
         return StringSubstr(comment, 0, pos);
      // Legacy / plain tag
      if(StringFind(comment, "GM_BL") == 0 || StringFind(comment, "GM_SL") == 0)
        {
         if(StringLen(comment) >= 6)
            return StringSubstr(comment, 0, 6);
        }
      return comment;
     }

   static ulong ExtractTradeId(const string comment)
     {
      const int pos = StringFind(comment, GM_TRADE_ID_MARKER);
      if(pos < 0)
         return 0;
      return (ulong)StringToInteger(StringSubstr(comment, pos + StringLen(GM_TRADE_ID_MARKER)));
     }
  };

#endif // GM_CTRADE_ID_MANAGER_MQH
//+------------------------------------------------------------------+
