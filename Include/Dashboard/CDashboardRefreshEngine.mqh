//+------------------------------------------------------------------+
//|                                 CDashboardRefreshEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CDASHBOARD_REFRESH_ENGINE_MQH
#define GM_CDASHBOARD_REFRESH_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "CDashboardDataProvider.mqh"
#include "CDashboardEventManager.mqh"
#include "SGmDashboardSettings.mqh"

/// @file CDashboardRefreshEngine.mqh
/// @brief Auto-refresh with change detection — avoids CPU waste / flicker.

class CGmDashboardRefreshEngine
  {
private:
   CGmDashboardDataProvider  *m_data;
   CGmDashboardEventManager  *m_events;
   SGmDashboardSettings       m_settings;
   ulong                      m_last_ms;
   ulong                      m_last_fp;
   bool                       m_force;
   ulong                      m_refresh_count;
   ulong                      m_skip_count;

public:
                     CGmDashboardRefreshEngine(void)
                       : m_data(NULL), m_events(NULL),
                         m_last_ms(0), m_last_fp(0), m_force(false),
                         m_refresh_count(0), m_skip_count(0)
     {
      m_settings.Defaults();
     }

   void Init(CGmDashboardDataProvider *data,
             CGmDashboardEventManager *events,
             const SGmDashboardSettings &settings)
     {
      m_data = data;
      m_events = events;
      m_settings = settings;
      m_settings.Clamp();
      m_last_ms = 0;
      m_force = true;
     }

   void SetSettings(const SGmDashboardSettings &settings)
     {
      m_settings = settings;
      m_settings.Clamp();
     }

   void RequestImmediate(void) { m_force = true; }

   ulong RefreshCount(void) const { return m_refresh_count; }
   ulong SkipCount(void) const { return m_skip_count; }

   /// @return true when snapshot changed and UI should repaint.
   bool Tick(SGmDashboardSnapshot &out)
     {
      out.Reset();
      if(m_data == NULL || (!m_settings.auto_refresh && !m_force))
         return false;

      const ulong now_ms = GetTickCount();
      if(!m_force && m_last_ms != 0 &&
         (now_ms - m_last_ms) < (ulong)m_settings.refresh_ms)
        {
         m_skip_count++;
         return false;
      }

      if(!m_data.Collect(out))
         return false;

      m_last_ms = now_ms;
      m_force = false;

      if(out.fingerprint == m_last_fp)
        {
         m_skip_count++;
         return false;
        }

      m_last_fp = out.fingerprint;
      m_refresh_count++;
      if(m_events != NULL)
         m_events.Publish(GM_DASH_EVT_DASHBOARD_REFRESH,
                          StringFormat("Refresh #%I64u | %I64u us",
                                       m_refresh_count, out.last_refresh_us));
      return true;
     }
  };

#endif // GM_CDASHBOARD_REFRESH_ENGINE_MQH
//+------------------------------------------------------------------+
