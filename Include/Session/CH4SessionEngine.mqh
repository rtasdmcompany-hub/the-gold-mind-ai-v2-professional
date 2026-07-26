//+------------------------------------------------------------------+
//|                                          CH4SessionEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CH4_SESSION_ENGINE_MQH
#define GM_CH4_SESSION_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SessionConstants.mqh"
#include "SGmSessionLogSettings.mqh"
#include "SGmSessionRecord.mqh"
#include "CSessionAudit.mqh"
#include "CSessionPerformance.mqh"
#include "CExecutionControl.mqh"
#include "COrderSyncEngine.mqh"
#include "CSessionSyncEngine.mqh"
#include "../Core/CFileManager.mqh"
#include "../Logging/CLogger.mqh"
#include "../Lifecycle/CLevelManager.mqh"
#include "../Trading/CTradeOwnership.mqh"
#include "../Trading/CTradeRegistry.mqh"
#include "../Calculation/SGmLevels.mqh"

/// @file CH4SessionEngine.mqh
/// @brief H4 Session Manager — one closed H4 candle = one trading session.

class CGmH4SessionEngine
  {
private:
   CGmLogger               *m_logger;
   CGmFileManager          *m_files;
   CGmLevelManager         *m_level_mgr;
   CGmTradeOwnership       *m_ownership;
   CGmTradeRegistry        *m_registry;
   CGmSessionAudit          m_audit;
   CGmSessionPerformance    m_perf;
   CGmExecutionControl      m_exec;
   CGmOrderSyncEngine       m_order_sync;
   CGmSessionSyncEngine     m_session_sync;
   SGmSessionLogSettings    m_settings;
   SGmSessionRecord         m_current;
   SGmSessionRecord         m_archive[GM_SESSION_ARCHIVE_MAX];
   int                      m_archive_count;
   string                   m_symbol;
   long                     m_magic;
   string                   m_file_name;
   bool                     m_ready;
   datetime                 m_last_sync;

   void PersistCurrent(void)
     {
      if(m_files == NULL || !m_current.used)
         return;
      const string payload = StringFormat(
         "#GM_H4_SESSION\r\n"
         "session_id=%I64u\r\n"
         "h4_bar=%I64d\r\n"
         "state=%d\r\n"
         "generated=%d\r\n"
         "active_levels=%d\r\n"
         "completed=%d\r\n"
         "failed=%d\r\n"
         "pendings=%d\r\n"
         "trades=%d\r\n",
         m_current.session_id,
         (long)m_current.h4_bar_time,
         (int)m_current.state,
         m_current.generated_levels,
         m_current.active_levels,
         m_current.completed_levels,
         m_current.failed_levels,
         m_current.pending_orders,
         m_current.active_trades);
      m_files.WriteText(m_file_name, payload);
     }

   void ArchiveCurrent(void)
     {
      if(!m_current.used)
         return;
      m_current.state = GM_SESSION_ARCHIVED;
      m_current.session_end = TimeCurrent();

      if(m_settings.automatic_archive)
        {
         if(m_archive_count < GM_SESSION_ARCHIVE_MAX)
           {
            m_archive[m_archive_count++] = m_current;
           }
         else
           {
            // Shift left — drop oldest
            for(int i = 1; i < GM_SESSION_ARCHIVE_MAX; i++)
               m_archive[i - 1] = m_archive[i];
            m_archive[GM_SESSION_ARCHIVE_MAX - 1] = m_current;
           }
        }

      m_audit.Record(GM_AUDIT_CLEANUP, "H4Session",
                     StringFormat("Session archived | SID=%I64u H4=%s",
                                  m_current.session_id,
                                  TimeToString(m_current.h4_bar_time, TIME_DATE | TIME_MINUTES)),
                     m_current.session_id);
      PersistCurrent();
     }

public:
                     CGmH4SessionEngine(void)
                       : m_logger(NULL), m_files(NULL), m_level_mgr(NULL),
                         m_ownership(NULL), m_registry(NULL),
                         m_archive_count(0), m_symbol(""), m_magic(0),
                         m_file_name(""), m_ready(false), m_last_sync(0)
     {
      m_settings.Defaults();
      m_current.Reset();
      for(int i = 0; i < GM_SESSION_ARCHIVE_MAX; i++)
         m_archive[i].Reset();
     }

                    ~CGmH4SessionEngine(void)
     {
      if(m_ready)
         PersistCurrent();
      m_logger = NULL;
      m_files = NULL;
      m_level_mgr = NULL;
      m_ownership = NULL;
      m_registry = NULL;
     }

   bool Init(CGmLogger *logger,
             CGmFileManager *files,
             CGmLevelManager *level_mgr,
             CGmTradeOwnership *ownership,
             CGmTradeRegistry *registry,
             const string symbol,
             const long magic,
             const SGmSessionLogSettings &settings)
     {
      m_logger = logger;
      m_files = files;
      m_level_mgr = level_mgr;
      m_ownership = ownership;
      m_registry = registry;
      m_symbol = symbol;
      m_magic = magic;
      m_settings = settings;

      string sym = symbol;
      StringReplace(sym, ".", "_");
      m_file_name = StringFormat("%s%I64d_%s.state", GM_SESSION_FILE_PREFIX, magic, sym);

      m_audit.Init(logger, files, magic, symbol, settings);
      m_perf.Init(logger, GetPointer(m_audit), settings);
      m_exec.Init(logger, GetPointer(m_audit), ownership, registry, magic, symbol);
      m_order_sync.Init(logger, GetPointer(m_audit), GetPointer(m_perf),
                        registry, ownership, magic, symbol);
      m_session_sync.Init(logger, GetPointer(m_audit), GetPointer(m_perf),
                          level_mgr, registry, GetPointer(m_order_sync));

      m_ready = true;
      if(m_logger != NULL && m_settings.enable_session_logs)
         m_logger.Success("H4 Session Engine ready | AI-ready modular", "H4Session");
      return true;
     }

   void Shutdown(void)
     {
      PersistCurrent();
      m_ready = false;
     }

   CGmExecutionControl *ExecControl(void) { return GetPointer(m_exec); }
   CGmSessionAudit *Audit(void) { return GetPointer(m_audit); }
   SGmSessionRecord Current(void) const { return m_current; }
   ulong CurrentSessionId(void) const { return m_current.session_id; }
   datetime CurrentH4(void) const { return m_current.h4_bar_time; }

   /// @brief Create / bind a new H4 trading session from levels snapshot.
   bool BeginSession(const SGmLevels &levels)
     {
      if(!m_ready || !levels.valid)
         return false;

      const ulong t0 = GetMicrosecondCount();
      const ulong new_sid = (ulong)levels.h4_bar_time;

      // Same session already active — no duplicate create
      if(m_current.used && m_current.session_id == new_sid &&
         (m_current.state == GM_SESSION_ACTIVE || m_current.state == GM_SESSION_RECOVERED))
        {
         m_current.state = GM_SESSION_ACTIVE;
         m_exec.SetActiveSessionId(m_current.session_id);
         m_session_sync.RefreshSessionStats(m_current);
         if(m_settings.enable_recovery_logs && m_logger != NULL)
            m_logger.Info("Session already active — no duplicate create", "H4Session");
         return true;
        }

      // Archive previous session on rollover
      if(m_current.used && m_current.session_id != new_sid)
        {
         ArchiveCurrent();
         m_exec.SetActiveSessionId(0);
        }

      if(!m_exec.ValidateMagic())
         return false;

      m_current.Reset();
      m_current.BindFromLevels(levels, m_magic, m_symbol);
      m_exec.SetActiveSessionId(m_current.session_id);
      m_order_sync.SetSessionH4(m_current.h4_bar_time);

      m_audit.Record(GM_AUDIT_SESSION_CREATED, "H4Session",
                     StringFormat("Session Created | start=%s candleOpen=%s candleClose=%s",
                                  TimeToString(m_current.session_start, TIME_DATE | TIME_MINUTES),
                                  TimeToString(m_current.candle_open, TIME_DATE | TIME_MINUTES),
                                  TimeToString(m_current.candle_close, TIME_DATE | TIME_MINUTES)),
                     m_current.session_id);
      m_audit.Record(GM_AUDIT_LEVELS_GENERATED, "H4Session",
                     StringFormat("Levels Generated | count=%d valid=%s",
                                  m_current.generated_levels,
                                  m_current.levels_valid ? "Y" : "N"),
                     m_current.session_id);

      m_session_sync.RefreshSessionStats(m_current);
      PersistCurrent();

      const ulong us = GetMicrosecondCount() - t0;
      m_perf.RecordSessionInit(us);

      if(m_logger != NULL && m_settings.enable_session_logs)
         m_logger.Success(StringFormat("H4 Session active | SID=%I64u H4=%s | %I64u us",
                                       m_current.session_id,
                                       TimeToString(m_current.h4_bar_time, TIME_DATE | TIME_MINUTES),
                                       us),
                          "H4Session");
      return true;
     }

   /// @brief Cleanup hook — called before new session; positions untouched.
   void OnSessionCleanup(const int deleted_pendings)
     {
      m_audit.Record(GM_AUDIT_CLEANUP, "H4Session",
                     StringFormat("Expired pendings removed=%d | positions untouched",
                                  deleted_pendings),
                     m_current.session_id);
      m_audit.Record(GM_AUDIT_ORDER_DELETED, "H4Session",
                     StringFormat("Orders Deleted | count=%d", deleted_pendings),
                     m_current.session_id);
     }

   void OnOrdersPlaced(const int placed)
     {
      m_audit.Record(GM_AUDIT_ORDER_PLACED, "H4Session",
                     StringFormat("Orders Placed | count=%d", placed),
                     m_current.session_id);
      m_session_sync.RefreshSessionStats(m_current);
      PersistCurrent();
     }

   void OnTradeOpened(const ulong trade_id, const ulong ticket)
     {
      m_audit.Record(GM_AUDIT_TRADE_OPENED, "H4Session",
                     StringFormat("Trade Opened | TID=%I64u ticket=%I64u", trade_id, ticket),
                     m_current.session_id);
      m_audit.Record(GM_AUDIT_ORDER_ACTIVATED, "H4Session",
                     StringFormat("Order Activated | ticket=%I64u", ticket),
                     m_current.session_id);
     }

   void OnTradeClosed(const ulong trade_id)
     {
      m_audit.Record(GM_AUDIT_TRADE_CLOSED, "H4Session",
                     StringFormat("Trade Closed | TID=%I64u", trade_id),
                     m_current.session_id);
     }

   /// @brief Recover current session identity after restart.
   bool Recover(const datetime h4_bar)
     {
      if(!m_ready || h4_bar <= 0)
         return false;

      if(m_current.used && m_current.session_id == (ulong)h4_bar)
        {
         m_current.state = GM_SESSION_RECOVERED;
         m_current.state = GM_SESSION_ACTIVE;
         m_exec.SetActiveSessionId(m_current.session_id);
         m_session_sync.RefreshSessionStats(m_current);
         if(m_settings.enable_recovery_logs)
            m_audit.Record(GM_AUDIT_RECOVERY, "H4Session",
                           "Current session recovered (in-memory)", m_current.session_id);
         return true;
        }

      m_current.Reset();
      m_current.session_id = (ulong)h4_bar;
      m_current.h4_bar_time = h4_bar;
      m_current.candle_open = h4_bar;
      m_current.candle_close = h4_bar + PeriodSeconds(PERIOD_H4);
      m_current.session_start = TimeCurrent();
      m_current.magic = m_magic;
      m_current.symbol = m_symbol;
      m_current.state = GM_SESSION_RECOVERED;
      m_current.used = true;
      m_current.state = GM_SESSION_ACTIVE;
      m_exec.SetActiveSessionId(m_current.session_id);
      m_order_sync.SetSessionH4(h4_bar);
      m_session_sync.RefreshSessionStats(m_current);
      PersistCurrent();

      if(m_settings.enable_recovery_logs)
         m_audit.Record(GM_AUDIT_RECOVERY, "H4Session",
                        StringFormat("Session recovered | SID=%I64u pend=%d trades=%d",
                                     m_current.session_id,
                                     m_current.pending_orders,
                                     m_current.active_trades),
                        m_current.session_id);
      return true;
     }

   void Process(void)
     {
      if(!m_ready)
         return;
      const ulong t0 = GetMicrosecondCount();
      // Sprint 9: throttle session DB sync (identical trading behavior)
      if(m_current.used && (TimeCurrent() - m_last_sync >= 5 || m_last_sync == 0))
        {
         m_session_sync.RefreshSessionStats(m_current);
         m_last_sync = TimeCurrent();
        }
      m_perf.RefreshSystem();
      m_perf.RecordExec(GetMicrosecondCount() - t0);
     }
  };

#endif // GM_CH4_SESSION_ENGINE_MQH
//+------------------------------------------------------------------+
