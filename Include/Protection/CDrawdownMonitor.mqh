//+------------------------------------------------------------------+
//|                                         CDrawdownMonitor.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CDRAWDOWN_MONITOR_MQH
#define GM_CDRAWDOWN_MONITOR_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "ProtectionConstants.mqh"
#include "SGmDrawdownState.mqh"
#include "SGmAccountSnapshot.mqh"
#include "CEventLogger.mqh"

/// @file CDrawdownMonitor.mqh
/// @brief Monitors current/max/daily/weekly/monthly DD — WARNING ONLY (no halt).

class CGmDrawdownMonitor
  {
private:
   CGmEventLogger  *m_events;
   SGmDrawdownState m_state;
   double           m_max_dd_warn_pct;
   double           m_max_daily_loss_warn_pct;
   bool             m_ready;
   bool             m_fired_dd_warn;
   bool             m_fired_daily_warn;

   int DayKey(const datetime t) const
     {
      MqlDateTime dt;
      TimeToStruct(t, dt);
      return dt.year * 10000 + dt.mon * 100 + dt.day;
     }

   int WeekKey(const datetime t) const
     {
      MqlDateTime dt;
      TimeToStruct(t, dt);
      // Approximate ISO-ish week key: year*100 + week-of-year
      const int doy = (int)((t - StringToTime(StringFormat("%04d.01.01", dt.year))) / 86400) + 1;
      const int week = (doy + 6) / 7;
      return dt.year * 100 + week;
     }

   int MonthKey(const datetime t) const
     {
      MqlDateTime dt;
      TimeToStruct(t, dt);
      return dt.year * 100 + dt.mon;
     }

   double PctDrop(const double peak, const double equity) const
     {
      if(peak <= 0.0)
         return 0.0;
      if(equity >= peak)
         return 0.0;
      return ((peak - equity) / peak) * 100.0;
     }

public:
                     CGmDrawdownMonitor(void)
                       : m_events(NULL),
                         m_max_dd_warn_pct(GM_PROT_MAX_DD_WARN_PCT_DEFAULT),
                         m_max_daily_loss_warn_pct(GM_PROT_MAX_DAILY_LOSS_WARN_DEFAULT),
                         m_ready(false),
                         m_fired_dd_warn(false),
                         m_fired_daily_warn(false)
     {
      m_state.Reset();
     }

                    ~CGmDrawdownMonitor(void) { m_events = NULL; }

   void Init(CGmEventLogger *events,
             const double max_dd_warn_pct,
             const double max_daily_loss_warn_pct)
     {
      m_events = events;
      m_max_dd_warn_pct = (max_dd_warn_pct > 0.0) ? max_dd_warn_pct : GM_PROT_MAX_DD_WARN_PCT_DEFAULT;
      m_max_daily_loss_warn_pct = (max_daily_loss_warn_pct > 0.0)
                                  ? max_daily_loss_warn_pct
                                  : GM_PROT_MAX_DAILY_LOSS_WARN_DEFAULT;
      m_state.Reset();
      m_fired_dd_warn = false;
      m_fired_daily_warn = false;
      m_ready = true;
      if(m_events != NULL)
         m_events.Risk("DrawdownMonitor",
                       StringFormat("Ready | warnDD=%.1f%% warnDailyLoss=%.1f%% (monitor-only)",
                                    m_max_dd_warn_pct, m_max_daily_loss_warn_pct));
     }

   void Seed(const SGmDrawdownState &saved)
     {
      if(!saved.valid)
         return;
      m_state = saved;
      m_fired_dd_warn = saved.warn_dd;
      m_fired_daily_warn = saved.warn_daily;
     }

   SGmDrawdownState State(void) const { return m_state; }

   /// @brief Update DD metrics from account snapshot. Never stops trading.
   void Update(const SGmAccountSnapshot &acct)
     {
      if(!m_ready || !acct.valid)
         return;

      const datetime now = acct.stamped_at;
      const double equity = acct.equity;
      const int dkey = DayKey(now);
      const int wkey = WeekKey(now);
      const int mkey = MonthKey(now);

      if(m_state.peak_equity <= 0.0)
         m_state.peak_equity = equity;
      if(equity > m_state.peak_equity)
         m_state.peak_equity = equity;

      if(m_state.day_key != dkey)
        {
         m_state.day_key = dkey;
         m_state.day_start_equity = equity;
         m_fired_daily_warn = false;
         m_state.warn_daily = false;
        }
      if(m_state.day_start_equity <= 0.0)
         m_state.day_start_equity = equity;

      if(m_state.week_key != wkey)
        {
         m_state.week_key = wkey;
         m_state.week_start_equity = equity;
        }
      if(m_state.week_start_equity <= 0.0)
         m_state.week_start_equity = equity;

      if(m_state.month_key != mkey)
        {
         m_state.month_key = mkey;
         m_state.month_start_equity = equity;
        }
      if(m_state.month_start_equity <= 0.0)
         m_state.month_start_equity = equity;

      m_state.current_dd_pct = PctDrop(m_state.peak_equity, equity);
      if(m_state.current_dd_pct > m_state.max_dd_pct)
         m_state.max_dd_pct = m_state.current_dd_pct;

      m_state.daily_dd_pct = PctDrop(m_state.day_start_equity, equity);
      m_state.weekly_dd_pct = PctDrop(m_state.week_start_equity, equity);
      m_state.monthly_dd_pct = PctDrop(m_state.month_start_equity, equity);
      m_state.stamped_at = now;
      m_state.valid = true;

      // WARNING ONLY — do not halt trading in Sprint 6
      if(m_state.current_dd_pct >= m_max_dd_warn_pct)
        {
         m_state.warn_dd = true;
         if(!m_fired_dd_warn)
           {
            m_fired_dd_warn = true;
            if(m_events != NULL)
               m_events.Warn("DrawdownMonitor",
                             StringFormat("Max DD warning | current=%.2f%% limit=%.2f%% max=%.2f%%",
                                          m_state.current_dd_pct, m_max_dd_warn_pct, m_state.max_dd_pct));
           }
        }

      const double daily_loss_pct = (m_state.day_start_equity > 0.0 && acct.daily_pnl < 0.0)
                                    ? ((-acct.daily_pnl) / m_state.day_start_equity) * 100.0
                                    : 0.0;
      if(daily_loss_pct >= m_max_daily_loss_warn_pct || m_state.daily_dd_pct >= m_max_daily_loss_warn_pct)
        {
         m_state.warn_daily = true;
         if(!m_fired_daily_warn)
           {
            m_fired_daily_warn = true;
            if(m_events != NULL)
               m_events.Warn("DrawdownMonitor",
                             StringFormat("Daily loss warning | dayDD=%.2f%% dayLossPct=%.2f%% limit=%.2f%%",
                                          m_state.daily_dd_pct, daily_loss_pct, m_max_daily_loss_warn_pct));
           }
        }

      if(m_events != NULL && m_events.Detailed())
         m_events.Risk("DrawdownMonitor",
                       StringFormat("DD cur=%.2f max=%.2f day=%.2f week=%.2f month=%.2f",
                                    m_state.current_dd_pct, m_state.max_dd_pct,
                                    m_state.daily_dd_pct, m_state.weekly_dd_pct, m_state.monthly_dd_pct),
                       GM_LOG_DEBUG);
     }
  };

#endif // GM_CDRAWDOWN_MONITOR_MQH
//+------------------------------------------------------------------+
