//+------------------------------------------------------------------+
//|                                 CDashboardEventHandler.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CDASHBOARD_EVENT_HANDLER_MQH
#define GM_CDASHBOARD_EVENT_HANDLER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "DashboardConstants.mqh"
#include "SGmDashboardSettings.mqh"
#include "CDashboardRenderer.mqh"
#include "QA/DashboardQAConstants.mqh"
#include "../UI/CPersonalizationEngine.mqh"
#include "../Logging/CLogger.mqh"

/// @file CDashboardEventHandler.mqh
/// @brief Panel controls + Sprint 9 layout throttle (UI only).

class CGmDashboardEventHandler
  {
private:
   CGmLogger                 *m_logger;
   CGmDashboardRenderer      *m_renderer;
   CGmPersonalizationEngine  *m_ui;
   SGmDashboardSettings       m_settings;
   bool                       m_dragging;
   bool                       m_resizing;
   int                        m_drag_dx;
   int                        m_drag_dy;
   ulong                      m_last_layout_ms;

   string Obj(const string key) const { return GM_DASH_OBJ_PREFIX + key; }

   void PushSettings(const bool force_layout = true)
     {
      if(m_ui != NULL)
         m_ui.SyncSettings(m_settings);
      else
         m_settings.Clamp();
      if(m_renderer == NULL)
         return;

      // Sprint 9: throttle rebuilds during drag/resize (skip redundant redraws)
      if(!force_layout)
        {
         const ulong now = GetTickCount();
         if(m_last_layout_ms != 0 &&
            (now - m_last_layout_ms) < (ulong)GM_DASH_LAYOUT_THROTTLE_MS)
            return;
         m_last_layout_ms = now;
        }
      else
         m_last_layout_ms = GetTickCount();

      // ApplySettings rebuilds when visible — do not call BuildLayout again
      m_renderer.ApplySettings(m_settings);
     }

   void SavePosition(void)
     {
      if(m_ui != NULL)
        {
         m_ui.ApplySettings(m_settings);
         m_ui.Layout().SaveLayout(m_settings);
        }
      else
        {
         GlobalVariableSet(GM_DASH_POS_GV_X, (double)m_settings.panel_x);
         GlobalVariableSet(GM_DASH_POS_GV_Y, (double)m_settings.panel_y);
        }
      if(m_logger != NULL)
         m_logger.Info(StringFormat("Panel position saved | x=%d y=%d",
                                    m_settings.panel_x, m_settings.panel_y),
                       "Dashboard");
     }

public:
                     CGmDashboardEventHandler(void)
                       : m_logger(NULL), m_renderer(NULL), m_ui(NULL),
                         m_dragging(false), m_resizing(false),
                         m_drag_dx(0), m_drag_dy(0), m_last_layout_ms(0)
     {
      m_settings.Defaults();
     }

   void Init(CGmLogger *logger,
             CGmDashboardRenderer *renderer,
             const SGmDashboardSettings &settings,
             CGmPersonalizationEngine *ui = NULL)
     {
      m_logger = logger;
      m_renderer = renderer;
      m_ui = ui;
      if(m_ui != NULL)
         m_ui.SyncSettings(m_settings);
      else
        {
         m_settings = settings;
         m_settings.Clamp();
        }
      if(m_renderer != NULL)
         m_renderer.ApplySettings(m_settings);
     }

   SGmDashboardSettings Settings(void) const { return m_settings; }

   bool OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
     {
      if(m_renderer == NULL || !m_renderer.Visible())
         return false;

      if(id == CHARTEVENT_OBJECT_CLICK)
        {
         if(sparam == Obj("BTN_COLLAPSE"))
           {
            m_renderer.ToggleCollapse();
            if(m_logger != NULL)
               m_logger.Info(m_renderer.Collapsed() ? "Panel minimized" : "Panel expanded",
                             "Dashboard");
            return true;
           }
         if(sparam == Obj("BTN_MAX"))
           {
            if(m_settings.view_mode == GM_VIEW_COMPACT)
               m_settings.view_mode = GM_VIEW_STANDARD;
            else
               m_settings.view_mode = GM_VIEW_COMPACT;
            if(m_logger != NULL)
               m_logger.Info(m_settings.view_mode == GM_VIEW_COMPACT ? "Compact view"
                                                                     : "Standard view",
                             "Dashboard");
            PushSettings();
            return true;
           }
         if(sparam == Obj("BTN_LOCK"))
           {
            m_settings.lock_position = !m_settings.lock_position;
            if(m_settings.lock_position)
               SavePosition();
            if(m_ui != NULL)
               m_ui.ApplySettings(m_settings);
            PushSettings();
            if(m_logger != NULL)
               m_logger.Info(m_settings.lock_position ? "Panel Locked" : "Panel Unlocked",
                             "Dashboard");
            return true;
           }
         if(sparam == Obj("BTN_RESET"))
           {
            if(m_ui != NULL)
              {
               m_ui.ResetAll();
               m_ui.SyncSettings(m_settings);
              }
            else
              {
               m_settings.panel_x = GM_DASH_DEFAULT_X;
               m_settings.panel_y = GM_DASH_DEFAULT_Y;
               m_settings.panel_width = GM_DASH_DEFAULT_WIDTH;
              }
            PushSettings();
            return true;
           }
         if(sparam == Obj("BTN_THEME") && m_ui != NULL)
           {
            m_ui.CycleTheme();
            m_ui.SyncSettings(m_settings);
            PushSettings();
            return true;
           }
         if(sparam == Obj("BTN_PROFILE") && m_ui != NULL)
           {
            m_ui.LoadCycledProfile();
            m_ui.SyncSettings(m_settings);
            PushSettings();
            return true;
           }
         if(sparam == Obj("BTN_SETTINGS") && m_ui != NULL)
           {
            m_ui.ToggleSettingsPanel();
            m_ui.SyncSettings(m_settings);
            PushSettings();
            return true;
           }
         if(sparam == Obj("BTN_ANIM") && m_ui != NULL)
           {
            m_ui.ToggleAnimations();
            m_ui.SyncSettings(m_settings);
            PushSettings();
            return true;
           }
         if(sparam == Obj("BTN_LANG") && m_ui != NULL)
           {
            m_ui.CycleLanguage();
            m_ui.SyncSettings(m_settings);
            PushSettings();
            return true;
           }
         if(sparam == Obj("BTN_FONT") && m_ui != NULL)
           {
            m_ui.CycleFont();
            m_ui.SyncSettings(m_settings);
            PushSettings();
            return true;
           }
         if(sparam == Obj("BTN_TRANS") && m_ui != NULL)
           {
            m_ui.CycleTransparency();
            m_ui.SyncSettings(m_settings);
            PushSettings();
            return true;
           }
         if(sparam == Obj("BTN_REFRESH") && m_ui != NULL)
           {
            m_ui.CycleRefresh();
            m_ui.SyncSettings(m_settings);
            PushSettings();
            return true;
           }
         if(sparam == Obj("BTN_SAVE") && m_ui != NULL)
           {
            m_ui.ApplySettings(m_settings);
            m_ui.SaveCurrentProfile();
            return true;
           }
        }

      if(id == CHARTEVENT_MOUSE_MOVE)
        {
         if(m_settings.lock_position)
           {
            m_dragging = false;
            m_resizing = false;
            return false;
           }

         const int mx = (int)lparam;
         const int my = (int)dparam;
         const int flags = (int)StringToInteger(sparam);
         const int x = m_settings.panel_x;
         const int y = m_settings.panel_y;
         const int w = m_settings.panel_width;
         const int h = m_settings.panel_height;

         if((flags & 1) == 1)
           {
            if(!m_dragging && !m_resizing)
              {
               if(mx >= x + w - 24 && my >= y + h - 24)
                 {
                  m_resizing = true;
                  m_drag_dx = mx;
                  m_drag_dy = my;
                 }
               else if(mx >= x && mx <= x + w &&
                       my >= y && my <= y + GM_DASH_HEADER_H)
                 {
                  m_dragging = true;
                  m_drag_dx = mx - x;
                  m_drag_dy = my - y;
                 }
              }
            else if(m_dragging)
              {
               m_settings.panel_x = MathMax(0, mx - m_drag_dx);
               m_settings.panel_y = MathMax(0, my - m_drag_dy);
               if(m_ui != NULL)
                  m_ui.ApplySettings(m_settings);
               PushSettings(false);
               if(m_logger != NULL)
                  m_logger.Debug("Widget Moved", "LayoutManager");
              }
            else if(m_resizing)
              {
               m_settings.panel_width = MathMax(GM_DASH_MIN_WIDTH, w + (mx - m_drag_dx));
               m_settings.panel_height = MathMax(GM_DASH_MIN_HEIGHT, h + (my - m_drag_dy));
               m_drag_dx = mx;
               m_drag_dy = my;
               m_settings.Clamp();
               if(m_ui != NULL)
                  m_ui.ApplySettings(m_settings);
               PushSettings(false);
              }
           }
         else
           {
            if(m_dragging || m_resizing)
              {
               PushSettings(true);
               SavePosition();
              }
            m_dragging = false;
            m_resizing = false;
           }
         return (m_dragging || m_resizing);
        }

      if(id == CHARTEVENT_CHART_CHANGE)
        {
         m_renderer.BuildLayout();
         return true;
        }

      return false;
     }
  };

#endif // GM_CDASHBOARD_EVENT_HANDLER_MQH
//+------------------------------------------------------------------+
