//+------------------------------------------------------------------+
//|                                           CLevelManagerImpl.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CLEVEL_MANAGER_IMPL_MQH
#define GM_CLEVEL_MANAGER_IMPL_MQH

#include "CLevelManager.mqh"
#include "../Trading/CPendingOrderEngine.mqh"

/// @file CLevelManagerImpl.mqh
/// @brief Out-of-line LevelManager methods needing PendingOrderEngine.

void CGmLevelManager::NotifyClosed(const string level_tag,
                                   const ulong trade_id,
                                   const bool is_tp,
                                   const bool is_sl,
                                   const double pnl)
  {
   if(!m_initialized)
      return;

   const ENUM_GM_LEVEL_TAG tag = TagFromString(level_tag);
   const int need_reactivate = m_lifecycle.OnTradeClosed(tag, trade_id, is_tp, is_sl, pnl);
   if(need_reactivate != 1)
      return;

   SGmLevelRecord rec;
   if(!m_lifecycle.GetRecord(tag, rec))
      return;
   if(!m_lifecycle.PrepareReactivation(rec))
     {
      if(m_logger != NULL)
         m_logger.Warning(StringFormat("Reactivation validation failed | %s", level_tag),
                          "LevelManager");
      return;
     }

   if(m_pendings == NULL)
     {
      if(m_logger != NULL)
         m_logger.Error("Cannot reactivate — pending engine not bound", "LevelManager");
      return;
     }

   // Same original calculated level price — never invent a new level.
   if(!m_pendings.PlaceExact(tag, rec.entry_price, 2))
     {
      if(m_logger != NULL)
         m_logger.Error(StringFormat("Reactivation order failed | %s @ %.5f",
                                     level_tag, rec.entry_price),
                        "LevelManager");
     }
  }

#endif // GM_CLEVEL_MANAGER_IMPL_MQH
//+------------------------------------------------------------------+
