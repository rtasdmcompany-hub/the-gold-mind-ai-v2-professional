//+------------------------------------------------------------------+
//|                                               CSyncEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CSYNC_ENGINE_MQH
#define GM_CSYNC_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "MultiInstanceConstants.mqh"
#include "SGmGlobalMonitorSnapshot.mqh"
#include "../Logging/CLogger.mqh"

/// @file CSyncEngine.mqh
/// @brief Synchronizes MONITORING information only — never trading actions.

class CGmSyncEngine
  {
private:
   CGmLogger *m_logger;
   datetime   m_last_sync;
   ulong      m_last_us;
   int        m_sync_count;
   bool       m_ready;

public:
                     CGmSyncEngine(void)
                       : m_logger(NULL), m_last_sync(0), m_last_us(0),
                         m_sync_count(0), m_ready(false)
     {
     }

   void Init(CGmLogger *logger)
     {
      m_logger = logger;
      m_last_sync = 0;
      m_last_us = 0;
      m_sync_count = 0;
      m_ready = true;
      if(m_logger != NULL)
         m_logger.Info("Synchronization Engine ready | monitoring-only", "SyncEngine");
     }

   bool IsReady(void) const { return m_ready; }
   datetime LastSync(void) const { return m_last_sync; }
   ulong LastUs(void) const { return m_last_us; }
   int SyncCount(void) const { return m_sync_count; }

   bool ShouldSync(void) const
     {
      if(!m_ready)
         return false;
      if(m_last_sync <= 0)
         return true;
      return ((TimeCurrent() - m_last_sync) >= GM_INSTANCE_SYNC_SEC);
     }

   void MarkSynced(const ulong us, const SGmGlobalMonitorSnapshot &snap)
     {
      m_last_sync = TimeCurrent();
      m_last_us = us;
      m_sync_count++;
      if(m_logger != NULL)
         m_logger.Debug(StringFormat("Synchronization Events | #%d | instances=%d | %I64u us",
                                     m_sync_count, snap.total_instances, us),
                        "SyncEngine");
     }

   /// @brief Explicitly documents blocked trading sync.
   bool SyncTradingActions(void) const
     {
      if(m_logger != NULL)
         m_logger.Warning("Trading sync blocked by design — monitoring only", "SyncEngine");
      return false;
     }
  };

#endif // GM_CSYNC_ENGINE_MQH
//+------------------------------------------------------------------+
