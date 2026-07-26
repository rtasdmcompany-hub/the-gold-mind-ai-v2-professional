//+------------------------------------------------------------------+
//|                                            CJournalEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//|     Phase 2 Sprint 5 — Alert Center + Journals orchestrator     |
//+------------------------------------------------------------------+
#ifndef GM_CJOURNAL_ENGINE_MQH
#define GM_CJOURNAL_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "CAlertCenter.mqh"
#include "CTradeJournal.mqh"
#include "CLevelJournal.mqh"
#include "CSessionJournal.mqh"
#include "CJournalSearch.mqh"
#include "SGmJournalReportStats.mqh"
#include "../Core/CFileManager.mqh"
#include "../Logging/CLogger.mqh"
#include "../Lifecycle/CLevelManager.mqh"
#include "../Session/CH4SessionEngine.mqh"
#include "../Analytics/CAnalyticsEngine.mqh"

/// @file CJournalEngine.mqh
/// @brief Enterprise Alert Center + Journals (READ-ONLY observation).
/// @warning Never opens/closes/modifies trades, SL/TP, or risk.

class CGmJournalEngine
  {
private:
   CGmLogger           *m_logger;
   CGmFileManager      *m_files;
   CGmLevelManager     *m_levels;
   CGmH4SessionEngine  *m_session;
   CGmAnalyticsEngine  *m_analytics;

   CGmAlertCenter       m_alerts;
   CGmTradeJournal      m_trades;
   CGmLevelJournal      m_levels_j;
   CGmSessionJournal    m_sessions;
   CGmJournalSearch     m_search;

   SGmJournalReportStats m_stats;
   datetime              m_last_sync;
   bool                  m_ready;
   long                  m_magic;
   string                m_symbol;

   void RecomputeStats(void)
     {
      m_stats.Reset();
      m_stats.alert_count = m_alerts.Count();
      m_stats.trade_count = m_trades.Count();
      m_stats.level_count = m_levels_j.Count();
      m_stats.session_count = m_sessions.Count();

      SGmAlertRecord a;
      if(m_alerts.GetRecent(0, a))
         m_stats.last_alert = m_alerts.FormatLine(a);

      datetime day0 = TimeCurrent();
      MqlDateTime dt;
      TimeToStruct(day0, dt);
      dt.hour = 0; dt.min = 0; dt.sec = 0;
      day0 = StructToTime(dt);

      double today_pnl = 0.0;
      int today_n = 0;
      int today_w = 0;
      int today_l = 0;
      double largest_win = 0.0;
      double largest_loss = 0.0;
      ulong last_win_id = 0;
      ulong last_loss_id = 0;
      double last_win_pnl = 0.0;
      double last_loss_pnl = 0.0;
      datetime last_win_t = 0;
      datetime last_loss_t = 0;
      double dur_sum = 0.0;
      int dur_n = 0;
      int cur_w = 0, cur_l = 0, max_w = 0, max_l = 0;

      for(int i = 0; i < m_trades.Count(); i++)
        {
         SGmTradeJournalRecord r;
         if(!m_trades.GetAt(i, r) || r.is_open)
            continue;

         if(r.duration_sec > 0.0)
           {
            dur_sum += r.duration_sec;
            dur_n++;
           }

         if(r.close_time >= day0 || (r.close_time == 0 && r.open_time >= day0))
           {
            today_pnl += r.profit_loss;
            today_n++;
            if(r.profit_loss >= 0.0)
               today_w++;
            else
               today_l++;
           }

         if(r.profit_loss >= 0.0)
           {
            if(r.profit_loss > largest_win)
               largest_win = r.profit_loss;
            if(r.close_time >= last_win_t)
              {
               last_win_t = r.close_time;
               last_win_id = r.trade_id;
               last_win_pnl = r.profit_loss;
              }
            cur_w++;
            if(cur_w > max_w)
               max_w = cur_w;
            cur_l = 0;
           }
         else
           {
            if(r.profit_loss < largest_loss)
               largest_loss = r.profit_loss;
            if(r.close_time >= last_loss_t)
              {
               last_loss_t = r.close_time;
               last_loss_id = r.trade_id;
               last_loss_pnl = r.profit_loss;
              }
            cur_l++;
            if(cur_l > max_l)
               max_l = cur_l;
            cur_w = 0;
           }
        }

      m_stats.today_summary = StringFormat("N=%d W=%d L=%d Net=%+.2f",
                                           today_n, today_w, today_l, today_pnl);
      if(last_win_id > 0)
         m_stats.last_winning_trade = StringFormat("TID=%I64u %+0.2f", last_win_id, last_win_pnl);
      if(last_loss_id > 0)
         m_stats.last_losing_trade = StringFormat("TID=%I64u %+0.2f", last_loss_id, last_loss_pnl);
      if(largest_win > 0.0)
         m_stats.largest_win = StringFormat("%+.2f", largest_win);
      if(largest_loss < 0.0)
         m_stats.largest_loss = StringFormat("%+.2f", largest_loss);
      m_stats.longest_win_streak = IntegerToString(max_w);
      m_stats.longest_loss_streak = IntegerToString(max_l);
      if(dur_n > 0)
         m_stats.average_trade_time = StringFormat("%.0fs", dur_sum / (double)dur_n);

      SGmSessionJournalRecord sess;
      if(m_sessions.GetCurrent(sess))
         m_stats.current_session_result = StringFormat("#%I64u Net=%+.2f WR=%.1f%% DD=%.2f%%",
                                                       sess.session_number, sess.net_profit,
                                                       sess.win_rate, sess.drawdown);

      m_stats.valid = true;
     }

public:
                     CGmJournalEngine(void)
                       : m_logger(NULL), m_files(NULL), m_levels(NULL),
                         m_session(NULL), m_analytics(NULL),
                         m_last_sync(0), m_ready(false), m_magic(0), m_symbol("")
     {
      m_stats.Reset();
     }

                    ~CGmJournalEngine(void) { Shutdown(); }

   bool Init(CGmLogger *logger,
             CGmFileManager *files,
             CGmLevelManager *levels,
             CGmH4SessionEngine *session,
             CGmAnalyticsEngine *analytics,
             const long magic,
             const string symbol)
     {
      m_logger = logger;
      m_files = files;
      m_levels = levels;
      m_session = session;
      m_analytics = analytics;
      m_magic = magic;
      m_symbol = symbol;

      m_alerts.Init(logger, files, magic, symbol);
      m_trades.Init(logger, magic, symbol);
      m_levels_j.Init(logger);
      m_sessions.Init(logger);
      m_search.Init(logger);
      m_stats.Reset();
      m_last_sync = 0;
      m_ready = true;

      m_alerts.Raise(GM_ALERT_INFO, "JournalEngine",
                     "Enterprise Alert Center + Journals online", 2);

      if(m_logger != NULL)
         m_logger.Success("Journal Engine ready | Alert Center + Trade/Level/Session Journals",
                          "JournalEngine");
      Sync(true);
      return true;
     }

   void Shutdown(void)
     {
      if(!m_ready)
         return;
      m_alerts.PersistSnapshot();
      m_ready = false;
     }

   bool IsReady(void) const { return m_ready; }

   CGmAlertCenter *Alerts(void) { return GetPointer(m_alerts); }
   CGmTradeJournal *Trades(void) { return GetPointer(m_trades); }
   CGmLevelJournal *Levels(void) { return GetPointer(m_levels_j); }
   CGmSessionJournal *Sessions(void) { return GetPointer(m_sessions); }
   CGmJournalSearch *Search(void) { return GetPointer(m_search); }
   SGmJournalReportStats Stats(void) const { return m_stats; }

   void RaiseAlert(const ENUM_GM_ALERT_CATEGORY cat,
                   const string module_name,
                   const string description,
                   const int priority = 3,
                   const ulong trade_id = 0,
                   const string level_id = "",
                   const ulong session_id = 0)
     {
      if(!m_ready)
         return;
      m_alerts.Raise(cat, module_name, description, priority,
                     trade_id, level_id, session_id);
     }

   int SearchTrades(const SGmJournalFilter &filter)
     {
      if(!m_ready)
         return 0;
      return m_search.Execute(GetPointer(m_trades), filter);
     }

   void Sync(const bool force = false)
     {
      if(!m_ready)
         return;
      const datetime now = TimeCurrent();
      if(!force && m_last_sync > 0 && (now - m_last_sync) < GM_JOURNAL_SYNC_SEC)
         return;

      const ulong t0 = GetMicrosecondCount();
      m_trades.SyncFromTerminal();
      m_levels_j.SyncFromLevelManager(m_levels);

      SGmAnalyticsSnapshot an;
      an.Reset();
      if(m_analytics != NULL)
        {
         m_analytics.Collect();
         an = m_analytics.Snapshot();
        }
      m_sessions.SyncFromSession(m_session, an);
      RecomputeStats();
      m_last_sync = now;

      if(m_logger != NULL)
         m_logger.Debug(StringFormat("Journal Updated | trades=%d levels=%d sessions=%d | %I64u us",
                                     m_trades.Count(), m_levels_j.Count(),
                                     m_sessions.Count(), GetMicrosecondCount() - t0),
                        "JournalEngine");
     }

   void Process(void)
     {
      Sync(false);
     }
  };

#endif // GM_CJOURNAL_ENGINE_MQH
//+------------------------------------------------------------------+
