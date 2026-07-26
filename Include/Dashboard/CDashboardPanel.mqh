//+------------------------------------------------------------------+
//|                                         CDashboardPanel.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CDASHBOARD_PANEL_MQH
#define GM_CDASHBOARD_PANEL_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "DashboardConstants.mqh"
#include "EnumsDashboard.mqh"
#include "SGmDashboardSettings.mqh"
#include "SGmDashboardSnapshot.mqh"
#include "CDashboardTheme.mqh"
#include "../Core/Version.mqh"

/// @file CDashboardPanel.mqh
/// @brief UI framework — layout sections, move/resize/collapse, theme, scaling.
/// @details Sprint 1 creates layout shells; data widgets arrive in later sprints.

class CGmDashboardPanel
  {
private:
   SGmDashboardSettings m_settings;
   CGmDashboardTheme    m_theme;
   bool                 m_visible;
   bool                 m_collapsed;
   bool                 m_dragging;
   bool                 m_resizing;
   int                  m_drag_dx;
   int                  m_drag_dy;
   int                  m_scale_pct;   // 100 = native
   string               m_prefix;
   string               m_last_body[];

   string Obj(const string key) const { return m_prefix + key; }

   int Scaled(const int v) const
     {
      return (int)MathMax(1.0, (double)v * (double)m_scale_pct / 100.0);
     }

   void EnsureRect(const string name, const int x, const int y,
                   const int w, const int h, const color bg, const color border)
     {
      if(ObjectFind(0, name) < 0)
        {
         ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
         ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
         ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
         ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
         ObjectSetInteger(0, name, OBJPROP_BACK, false);
         ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
        }
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
      ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
      ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
      ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bg);
      ObjectSetInteger(0, name, OBJPROP_COLOR, border);
      ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, border);
     }

   void EnsureLabel(const string name, const int x, const int y,
                    const string text, const color clr, const int font_sz,
                    const string font = "Consolas")
     {
      if(ObjectFind(0, name) < 0)
        {
         ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
         ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
         ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
         ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
         ObjectSetString(0, name, OBJPROP_FONT, font);
        }
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
      ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE, font_sz);
      // Flicker guard — only write text when changed
      if(ObjectGetString(0, name, OBJPROP_TEXT) != text)
         ObjectSetString(0, name, OBJPROP_TEXT, text);
     }

   string SectionTitle(const ENUM_GM_DASH_SECTION sec) const
     {
      switch(sec)
        {
         case GM_DASH_SEC_HEADER:         return "HEADER";
         case GM_DASH_SEC_ACCOUNT:        return "Account Information";
         case GM_DASH_SEC_TRADING:        return "Trading Information";
         case GM_DASH_SEC_RISK:           return "Risk Information";
         case GM_DASH_SEC_PERFORMANCE:    return "Performance";
         case GM_DASH_SEC_SYSTEM:         return "System Status";
         case GM_DASH_SEC_AI:             return "AI Status";
         case GM_DASH_SEC_STATS:          return "Trade Statistics";
         case GM_DASH_SEC_NOTIFICATIONS:  return "Notifications";
         case GM_DASH_SEC_FOOTER:         return "FOOTER";
         default:                         return "Section";
        }
     }

   string SectionBody(const ENUM_GM_DASH_SECTION sec,
                      const SGmDashboardSnapshot &snap) const
     {
      switch(sec)
        {
         case GM_DASH_SEC_ACCOUNT:
            return StringFormat("Bal %.2f | Eq %.2f | Free %.2f | ML %.1f",
                                snap.balance, snap.equity, snap.free_margin, snap.margin_level);
         case GM_DASH_SEC_TRADING:
            return StringFormat("%s | Magic %I64d | Pos %d | Pend %d | Reg %d",
                                snap.symbol, snap.magic, snap.own_positions,
                                snap.own_pendings, snap.registry_count);
         case GM_DASH_SEC_RISK:
            return StringFormat("DD %.2f%% | Float %.2f | DayPnL %.2f | Prot %s",
                                snap.drawdown_pct, snap.floating_pnl, snap.daily_pnl,
                                snap.protection_ready ? "OK" : "--");
         case GM_DASH_SEC_PERFORMANCE:
            return snap.performance_note + StringFormat(" | %I64u us", snap.last_refresh_us);
         case GM_DASH_SEC_SYSTEM:
            return StringFormat("Conn %s | Mem %I64u KB | Frozen %s | SID %I64u",
                                snap.terminal_connected ? "ON" : "OFF",
                                snap.terminal_memory_kb,
                                snap.core_frozen ? "YES" : "NO",
                                snap.session_id);
         case GM_DASH_SEC_AI:
            return snap.ai_status;
         case GM_DASH_SEC_STATS:
            return StringFormat("H4 %s | Recov Pos %d Pend %d %s",
                                TimeToString(snap.h4_cycle, TIME_DATE | TIME_MINUTES),
                                snap.recovery_positions, snap.recovery_pendings,
                                snap.recovery_ok ? "OK" : "--");
         case GM_DASH_SEC_NOTIFICATIONS:
            return (StringLen(snap.notification) > 0) ? snap.notification : "No alerts";
         default:
            return "";
        }
     }

   void UpdateScaleFromScreen(void)
     {
      const int sw = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS);
      // Baseline design width ~1280px
      if(sw <= 0)
        {
         m_scale_pct = 100;
         return;
        }
      m_scale_pct = (int)MathMax(85.0, MathMin(130.0, (double)sw / 12.80));
     }

public:
                     CGmDashboardPanel(void)
                       : m_visible(false), m_collapsed(false),
                         m_dragging(false), m_resizing(false),
                         m_drag_dx(0), m_drag_dy(0), m_scale_pct(100),
                         m_prefix(GM_DASH_OBJ_PREFIX)
     {
      m_settings.Defaults();
      ArrayResize(m_last_body, (int)GM_DASH_SEC_COUNT);
      for(int i = 0; i < (int)GM_DASH_SEC_COUNT; i++)
         m_last_body[i] = "";
     }

   bool Visible(void) const { return m_visible; }
   bool Collapsed(void) const { return m_collapsed; }

   void Init(const SGmDashboardSettings &settings)
     {
      m_settings = settings;
      m_settings.Clamp();
      m_theme.SetTheme(m_settings.theme);
      m_collapsed = m_settings.start_collapsed;
      UpdateScaleFromScreen();
     }

   void SetTheme(const ENUM_GM_DASH_THEME theme)
     {
      m_settings.theme = theme;
      m_theme.SetTheme(theme);
     }

   void DestroyObjects(void)
     {
      ObjectsDeleteAll(0, m_prefix);
      m_visible = false;
     }

   bool Show(void)
     {
      m_visible = true;
      RebuildLayout();
      ChartRedraw(0);
      return true;
     }

   bool Hide(void)
     {
      DestroyObjects();
      ChartRedraw(0);
      return true;
     }

   void ToggleCollapse(void)
     {
      m_collapsed = !m_collapsed;
      if(m_visible)
         RebuildLayout();
     }

   void RebuildLayout(void)
     {
      if(!m_visible)
         return;
      UpdateScaleFromScreen();
      const SGmDashPalette pal = m_theme.Palette();
      const int x = m_settings.panel_x;
      const int y = m_settings.panel_y;
      const int w = Scaled(m_settings.panel_width);
      const int header_h = Scaled(GM_DASH_HEADER_H);
      const int section_h = Scaled(GM_DASH_SECTION_H);
      const int footer_h = Scaled(GM_DASH_FOOTER_H);
      const int font = MathMax(7, Scaled(m_settings.font_size));
      const int h = m_collapsed ? (header_h + footer_h + 8)
                                : Scaled(m_settings.panel_height);

      EnsureRect(Obj("BG"), x, y, w, h, pal.bg, pal.border);
      EnsureRect(Obj("HDR"), x, y, w, header_h, pal.header_bg, pal.border);
      EnsureLabel(Obj("HDR_TXT"), x + 8, y + 6,
                  StringFormat("%s | Dashboard", GM_PRODUCT_SHORT),
                  pal.accent, font + 1);
      EnsureLabel(Obj("HDR_BTN"), x + w - 70, y + 6,
                  m_collapsed ? "[+]" : "[-]", pal.text, font);

      // Resize grip
      EnsureLabel(Obj("RESIZE"), x + w - 18, y + h - 18, "◢", pal.muted, font);

      if(m_collapsed)
        {
         EnsureLabel(Obj("FOOT"), x + 8, y + header_h + 4,
                     "Collapsed — click [-]/+] to expand", pal.muted, font);
         return;
        }

      int cy = y + header_h + 4;
      for(int s = (int)GM_DASH_SEC_ACCOUNT; s <= (int)GM_DASH_SEC_NOTIFICATIONS; s++)
        {
         const string sk = IntegerToString(s);
         EnsureRect(Obj("SEC_" + sk), x + 4, cy, w - 8, section_h - 2, pal.header_bg, pal.border);
         EnsureLabel(Obj("SEC_T_" + sk), x + 10, cy + 2,
                     SectionTitle((ENUM_GM_DASH_SECTION)s), pal.accent, font);
         EnsureLabel(Obj("SEC_B_" + sk), x + 10, cy + 16,
                     "— layout ready —", pal.muted, font);
         cy += section_h;
        }

      EnsureRect(Obj("FTR"), x, y + h - footer_h, w, footer_h, pal.header_bg, pal.border);
      EnsureLabel(Obj("FTR_TXT"), x + 8, y + h - footer_h + 4,
                  StringFormat("Build %d | Monitor only | Lang=%s",
                               GM_VERSION_BUILD, m_settings.language_code),
                  pal.muted, font - 1);
     }

   /// @brief Apply snapshot texts only when section body changed.
   void ApplySnapshot(const SGmDashboardSnapshot &snap, const string notification)
     {
      if(!m_visible || m_collapsed)
         return;
      const SGmDashPalette pal = m_theme.Palette();
      const int font = MathMax(7, Scaled(m_settings.font_size));
      SGmDashboardSnapshot local = snap;
      local.notification = notification;

      for(int s = (int)GM_DASH_SEC_ACCOUNT; s <= (int)GM_DASH_SEC_NOTIFICATIONS; s++)
        {
         const string body = SectionBody((ENUM_GM_DASH_SECTION)s, local);
         if(m_last_body[s] == body)
            continue;
         m_last_body[s] = body;
         const string name = Obj("SEC_B_" + IntegerToString(s));
         if(ObjectFind(0, name) >= 0)
           {
            ObjectSetInteger(0, name, OBJPROP_COLOR, pal.text);
            ObjectSetInteger(0, name, OBJPROP_FONTSIZE, font);
            ObjectSetString(0, name, OBJPROP_TEXT, body);
           }
        }
      ChartRedraw(0);
     }

   bool OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
     {
      if(!m_visible)
         return false;

      if(id == CHARTEVENT_OBJECT_CLICK && sparam == Obj("HDR_BTN"))
        {
         ToggleCollapse();
         return true;
        }

      if(id == CHARTEVENT_MOUSE_MOVE)
        {
         const int mx = (int)lparam;
         const int my = (int)dparam;
         const int flags = (int)StringToInteger(sparam);
         const int x = m_settings.panel_x;
         const int y = m_settings.panel_y;
         const int w = Scaled(m_settings.panel_width);
         const int h = m_collapsed ? Scaled(GM_DASH_HEADER_H + GM_DASH_FOOTER_H + 8)
                                   : Scaled(m_settings.panel_height);

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
                       my >= y && my <= y + Scaled(GM_DASH_HEADER_H))
                 {
                  m_dragging = true;
                  m_drag_dx = mx - x;
                  m_drag_dy = my - y;
                 }
              }
            else if(m_dragging)
              {
               m_settings.panel_x = mx - m_drag_dx;
               m_settings.panel_y = my - m_drag_dy;
               if(m_settings.panel_x < 0)
                  m_settings.panel_x = 0;
               if(m_settings.panel_y < 0)
                  m_settings.panel_y = 0;
               RebuildLayout();
              }
            else if(m_resizing)
              {
               m_settings.panel_width = MathMax(GM_DASH_MIN_WIDTH, w + (mx - m_drag_dx));
               m_settings.panel_height = MathMax(GM_DASH_MIN_HEIGHT, h + (my - m_drag_dy));
               m_drag_dx = mx;
               m_drag_dy = my;
               m_settings.Clamp();
               RebuildLayout();
              }
           }
         else
           {
            m_dragging = false;
            m_resizing = false;
           }
         return (m_dragging || m_resizing);
        }

      if(id == CHARTEVENT_CHART_CHANGE)
        {
         UpdateScaleFromScreen();
         RebuildLayout();
         return true;
        }

      return false;
     }

   SGmDashboardSettings Settings(void) const { return m_settings; }
  };

#endif // GM_CDASHBOARD_PANEL_MQH
//+------------------------------------------------------------------+
