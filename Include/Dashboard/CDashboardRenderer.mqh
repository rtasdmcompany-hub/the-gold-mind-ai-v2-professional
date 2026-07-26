//+------------------------------------------------------------------+
//|                                     CDashboardRenderer.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CDASHBOARD_RENDERER_MQH
#define GM_CDASHBOARD_RENDERER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "DashboardConstants.mqh"
#include "SGmDashboardSettings.mqh"
#include "SGmDashboardSnapshot.mqh"
#include "CDashboardTheme.mqh"
#include "CDashboardWidgets.mqh"
#include "CDashboardAIWidgetManager.mqh"
#include "CPerformanceGauges.mqh"
#include "../Core/Version.mqh"

/// @file CDashboardRenderer.mqh
/// @brief Professional Live Dashboard Renderer — LEFT-side institutional panel.

class CGmDashboardRenderer
  {
private:
   SGmDashboardSettings        m_settings;
   CGmDashboardTheme           m_theme;
   CGmDashboardWidgets         m_widgets;
   CGmDashboardAIWidgetManager m_ai;
   bool                        m_visible;
   bool                        m_collapsed;
   bool                        m_layout_built;
   int                         m_scale_pct;
   string                      m_last_vals[];
   int                         m_val_count;

   int Scaled(const int v) const
     {
      return (int)MathMax(1.0, (double)v * (double)m_scale_pct / 100.0);
     }

   void UpdateScale(void)
     {
      const int sw = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS);
      if(sw <= 0)
        {
         m_scale_pct = 100;
         return;
        }
      m_scale_pct = (int)MathMax(90.0, MathMin(120.0, (double)sw / 12.80));
     }

   color ValClr(const double v) const { return m_theme.SignedColor(v); }
   color StClr(const string s) const { return m_theme.StatusColor(s); }

   string Money(const double v) const
     {
      return StringFormat("%+.2f", v);
     }

   string MoneyAbs(const double v) const
     {
      return StringFormat("%.2f", v);
     }

   string Pct(const double v) const
     {
      return StringFormat("%.2f%%", v);
     }

   string Countdown(const int sec) const
     {
      if(sec <= 0)
         return "00:00:00";
      const int h = sec / 3600;
      const int m = (sec % 3600) / 60;
      const int s = sec % 60;
      return StringFormat("%02d:%02d:%02d", h, m, s);
     }

   void EnsureValSlots(const int n)
     {
      if(m_val_count >= n)
         return;
      ArrayResize(m_last_vals, n);
      for(int i = m_val_count; i < n; i++)
         m_last_vals[i] = "";
      m_val_count = n;
     }

   bool Put(const int idx, const string key, const string text, const color clr)
     {
      EnsureValSlots(idx + 1);
      if(m_last_vals[idx] == text)
         return false;
      m_last_vals[idx] = text;
      m_widgets.SetText(key, text, clr);
      return true;
     }

   int DrawSection(const string sid, int y, const int x, const int w,
                   const string icon, const string title, const int font,
                   const SGmDashPalette &pal)
     {
      m_widgets.SectionTitle(sid, x + 4, y, w - 8, icon, title, font,
                             pal.accent, pal.section_bg, pal.border);
      return y + Scaled(GM_DASH_SECTION_TITLE_H) + 2;
     }

   void StaticRow(const string key, const int x, const int y, const int w,
                  const string label, const int font, const SGmDashPalette &pal)
     {
      m_widgets.Label(key + "_L", x + 10, y, label, pal.muted, font);
      m_widgets.Label(key + "_V", x + w / 2, y, "—", pal.value, font);
     }

public:
                     CGmDashboardRenderer(void)
                       : m_visible(false), m_collapsed(false),
                         m_layout_built(false), m_scale_pct(100), m_val_count(0)
     {
      m_settings.Defaults();
     }

   bool Visible(void) const { return m_visible; }
   bool Collapsed(void) const { return m_collapsed; }
   SGmDashboardSettings Settings(void) const { return m_settings; }

   void Init(const SGmDashboardSettings &settings)
     {
      m_settings = settings;
      m_settings.Clamp();
      m_theme.SetCustomColors(m_settings.custom_colors);
      m_theme.SetTheme(m_settings.theme);
      m_widgets.Init(GetPointer(m_theme));
      m_collapsed = m_settings.start_collapsed;
      UpdateScale();
     }

   void ApplySettings(const SGmDashboardSettings &settings)
     {
      m_settings = settings;
      m_settings.Clamp();
      m_theme.SetCustomColors(m_settings.custom_colors);
      m_theme.SetTheme(m_settings.theme);
      if(m_visible)
         BuildLayout();
     }

   void Destroy(void)
     {
      m_widgets.DestroyAll();
      m_visible = false;
      m_layout_built = false;
      for(int i = 0; i < m_val_count; i++)
         m_last_vals[i] = "";
     }

   void ToggleCollapse(void)
     {
      m_collapsed = !m_collapsed;
      if(m_visible)
         BuildLayout();
     }

   void SetCollapsed(const bool c)
     {
      m_collapsed = c;
      if(m_visible)
         BuildLayout();
     }

   bool Show(void)
     {
      m_visible = true;
      BuildLayout();
      ChartRedraw(0);
      return true;
     }

   bool Hide(void)
     {
      Destroy();
      ChartRedraw(0);
      return true;
     }

   void BuildLayout(void)
     {
      if(!m_visible)
         return;
      UpdateScale();
      const SGmDashPalette pal = m_theme.Palette();
      const int x = m_settings.panel_x;
      const int y0 = m_settings.panel_y;
      const int w = Scaled(m_settings.panel_width);
      const int font = MathMax(7, Scaled(m_settings.font_size));
      const int rh = Scaled(GM_DASH_ROW_H);
      const int header_h = Scaled(GM_DASH_HEADER_H);
      const int footer_h = Scaled(GM_DASH_FOOTER_H);

      int content_rows = 0;
      // Approximate rows for height: account5 + risk3 + trade4 + today4 + overall4 + sess4 + sys4 + ai6 + mon5 = 39
      content_rows = 125;
      const int h = m_collapsed
                    ? (header_h + footer_h + 10)
                    : (header_h + footer_h + content_rows * rh + 12 * Scaled(GM_DASH_SECTION_TITLE_H));

      m_settings.panel_height = MathMax(m_settings.panel_height, h / (m_scale_pct > 0 ? m_scale_pct : 100) * 100);
      // Use computed height for drawing
      const int panel_h = m_collapsed ? (header_h + footer_h + 10) : h;

      m_widgets.Rect("BG", x, y0, w, panel_h, pal.bg, pal.border);
      m_widgets.Rect("HDR", x, y0, w, header_h, pal.header_bg, pal.border);

      // Gold logo glyph + branding
      m_widgets.Label("LOGO", x + 8, y0 + 6, "◆", pal.accent, font + 4);
      m_widgets.Label("TITLE", x + 28, y0 + 4, "THE GOLD MIND AI", pal.accent, font + 2);
      m_widgets.Label("EDITION", x + 28, y0 + 20, "Professional Edition", pal.text, font);
      m_widgets.Label("DIV", x + 28, y0 + 34,
                      GM_OWNER_DIVISION, pal.muted, font - 1);
      m_widgets.Label("VER", x + w - 118, y0 + 6,
                      StringFormat("v%s  #%d", GM_VERSION_STRING, GM_VERSION_BUILD),
                      pal.accent, font);
      m_widgets.Label("STATUS_L", x + w - 118, y0 + 22, "EA Status", pal.muted, font - 1);
      m_widgets.Label("STATUS_V", x + w - 118, y0 + 34, "RUNNING", pal.success, font);

      // Controls — collapse / lock / reset
      m_widgets.Label("BTN_COLLAPSE", x + w - 54, y0 + 6, m_collapsed ? "[+]" : "[-]", pal.text, font);
      m_widgets.Label("BTN_LOCK", x + w - 54, y0 + 22,
                      m_settings.lock_position ? "[L]" : "[U]", pal.accent, font);
      m_widgets.Label("BTN_RESET", x + w - 54, y0 + 38, "[R]", pal.muted, font);

      // Quick personalization (Sprint 8)
      m_widgets.Label("BTN_THEME", x + w - 108, y0 + 6, "[T]", pal.accent, font);
      m_widgets.Label("BTN_PROFILE", x + w - 108, y0 + 22, "[P]", pal.value, font);
      m_widgets.Label("BTN_SETTINGS", x + w - 108, y0 + 38, "[S]", pal.warn, font);
      m_widgets.Label("BTN_ANIM", x + w - 162, y0 + 6, "[A]", pal.muted, font);
      m_widgets.Label("BTN_LANG", x + w - 162, y0 + 22, "[L]", pal.muted, font);
      m_widgets.Label("BTN_FONT", x + w - 162, y0 + 38, "[F]", pal.muted, font);

      if(m_collapsed)
        {
         m_widgets.Label("COLLAPSED", x + 10, y0 + header_h + 4,
                         "Panel collapsed — click [+] to expand", pal.muted, font);
         m_widgets.Rect("FTR", x, y0 + panel_h - footer_h, w, footer_h, pal.header_bg, pal.border);
         m_widgets.Label("FTR1", x + 8, y0 + panel_h - footer_h + 6,
                         "Owner: " + GM_OWNER_GROUP, pal.muted, font - 1);
         m_layout_built = true;
         return;
        }

      int y = y0 + header_h + 4;

      //--- SETTINGS PANEL (Sprint 8)
      if(m_settings.settings_panel_open)
        {
         y = DrawSection("SS", y, x, w, "⚙", "SETTINGS PANEL", font, pal);
         StaticRow("ST1", x, y, w, "Theme", font, pal); y += rh;
         StaticRow("ST2", x, y, w, "Profile", font, pal); y += rh;
         StaticRow("ST3", x, y, w, "Language", font, pal); y += rh;
         StaticRow("ST4", x, y, w, "Font / View", font, pal); y += rh;
         StaticRow("ST5", x, y, w, "Animations", font, pal); y += rh;
         StaticRow("ST6", x, y, w, "Transparency", font, pal); y += rh;
         StaticRow("ST7", x, y, w, "Refresh Speed", font, pal); y += rh;
         StaticRow("ST8", x, y, w, "Layout Lock", font, pal); y += rh;
         m_widgets.Label("BTN_TRANS", x + 10, y, "[Transparency]", pal.accent, font - 1);
         m_widgets.Label("BTN_REFRESH", x + w / 2, y, "[Refresh]", pal.accent, font - 1);
         y += rh;
         m_widgets.Label("BTN_SAVE", x + 10, y, "[Save Profile]", pal.success, font - 1);
         y += rh + 2;
        }

      //--- CLOCK / CONTEXT
      y = DrawSection("SC", y, x, w, "⏱", "CLOCK & CONTEXT", font, pal);
      StaticRow("C1", x, y, w, "Local Time", font, pal); y += rh;
      StaticRow("C2", x, y, w, "Server Time", font, pal); y += rh;
      StaticRow("C3", x, y, w, "Symbol / TF / Build", font, pal); y += rh;
      StaticRow("C4", x, y, w, "Spread / ATR-14", font, pal); y += rh;
      StaticRow("C5", x, y, w, "H4 Countdown / Session", font, pal); y += rh + 2;

      //--- LIVE PERFORMANCE WIDGETS
      y = DrawSection("SP", y, x, w, "◆", "REAL-TIME PERFORMANCE", font, pal);
      StaticRow("P1", x, y, w, "Balance / Equity", font, pal); y += rh;
      StaticRow("P2", x, y, w, "Free Margin / Margin Level", font, pal); y += rh;
      StaticRow("P3", x, y, w, "Floating Profit / Loss", font, pal); y += rh;
      StaticRow("P4", x, y, w, "Today / Week Net", font, pal); y += rh;
      StaticRow("P5", x, y, w, "Month / Total Net", font, pal); y += rh + 2;

      //--- LIVE TRADE WIDGETS
      y = DrawSection("ST", y, x, w, "▶", "LIVE TRADE WIDGETS", font, pal);
      StaticRow("L1", x, y, w, "Open / Pending", font, pal); y += rh;
      StaticRow("L2", x, y, w, "Winning / Losing Open", font, pal); y += rh;
      StaticRow("L3", x, y, w, "Buy / Sell Positions", font, pal); y += rh;
      StaticRow("L4", x, y, w, "Hedge Positions", font, pal); y += rh;
      StaticRow("L5", x, y, w, "Success Rate / Avg Duration", font, pal); y += rh + 2;

      //--- KPI strip (analytics)
      y = DrawSection("SK", y, x, w, "◆", "LIVE ANALYTICS KPI", font, pal);
      StaticRow("K1", x, y, w, "Today Win % / Loss %", font, pal); y += rh;
      StaticRow("K2", x, y, w, "Balance / Equity", font, pal); y += rh;
      StaticRow("K3", x, y, w, "Floating Profit / Loss", font, pal); y += rh;
      StaticRow("K4", x, y, w, "Avg RR / Profit Factor", font, pal); y += rh;
      StaticRow("K5", x, y, w, "Recovery Factor", font, pal); y += rh;
      StaticRow("K6", x, y, w, "Spread / ATR-14", font, pal); y += rh;
      StaticRow("K7", x, y, w, "Session Timer", font, pal); y += rh;
      StaticRow("K8", x, y, w, "Trade Counter", font, pal); y += rh;
      StaticRow("K9", x, y, w, "DD Current / Max", font, pal); y += rh + 2;

      //--- 1 Account
      y = DrawSection("S1", y, x, w, "▣", "ACCOUNT INFORMATION", font, pal);
      StaticRow("A1", x, y, w, "Account Number", font, pal); y += rh;
      StaticRow("A2", x, y, w, "Broker Name", font, pal); y += rh;
      StaticRow("A3", x, y, w, "Server", font, pal); y += rh;
      StaticRow("A4", x, y, w, "Account Type", font, pal); y += rh;
      StaticRow("A5", x, y, w, "Currency / Leverage", font, pal); y += rh;
      StaticRow("A6", x, y, w, "Balance", font, pal); y += rh;
      StaticRow("A7", x, y, w, "Equity", font, pal); y += rh;
      StaticRow("A8", x, y, w, "Free Margin", font, pal); y += rh;
      StaticRow("A9", x, y, w, "Margin Level %", font, pal); y += rh + 2;

      //--- 2 Risk
      y = DrawSection("S2", y, x, w, "⚠", "RISK INFORMATION", font, pal);
      StaticRow("R1", x, y, w, "Auto Risk %", font, pal); y += rh;
      StaticRow("R2", x, y, w, "Current Risk", font, pal); y += rh;
      StaticRow("R3", x, y, w, "Maximum Daily Risk", font, pal); y += rh;
      StaticRow("R4", x, y, w, "Current Drawdown", font, pal); y += rh;
      StaticRow("R5", x, y, w, "Maximum Drawdown", font, pal); y += rh;
      StaticRow("R6", x, y, w, "Risk Status", font, pal); y += rh + 2;

      //--- 3 Live Trade Status
      y = DrawSection("S3", y, x, w, "▶", "LIVE TRADE STATUS", font, pal);
      StaticRow("T1", x, y, w, "Running Trades", font, pal); y += rh;
      StaticRow("T2", x, y, w, "Pending Orders", font, pal); y += rh;
      StaticRow("T3", x, y, w, "Buy / Sell Trades", font, pal); y += rh;
      StaticRow("T4", x, y, w, "Winning / Losing", font, pal); y += rh;
      StaticRow("T5", x, y, w, "Active Hedge Trades", font, pal); y += rh;
      StaticRow("T6", x, y, w, "Trade Engine Status", font, pal); y += rh + 2;

      //--- 4 Today
      y = DrawSection("S4", y, x, w, "☀", "TODAY PERFORMANCE", font, pal);
      StaticRow("D1", x, y, w, "Today's Profit", font, pal); y += rh;
      StaticRow("D2", x, y, w, "Today's Loss", font, pal); y += rh;
      StaticRow("D3", x, y, w, "Today's Net Profit", font, pal); y += rh;
      StaticRow("D4", x, y, w, "Opened / Closed", font, pal); y += rh;
      StaticRow("D5", x, y, w, "W / L Today", font, pal); y += rh;
      StaticRow("D6", x, y, w, "Today's Win Rate", font, pal); y += rh + 2;

      //--- 5 Overall
      y = DrawSection("S5", y, x, w, "★", "OVERALL PERFORMANCE", font, pal);
      StaticRow("O1", x, y, w, "Total Trades", font, pal); y += rh;
      StaticRow("O2", x, y, w, "Winners / Losers", font, pal); y += rh;
      StaticRow("O3", x, y, w, "Overall Win Rate", font, pal); y += rh;
      StaticRow("O4", x, y, w, "Profit Factor", font, pal); y += rh;
      StaticRow("O5", x, y, w, "Recovery Factor", font, pal); y += rh;
      StaticRow("O6", x, y, w, "Avg Win / Avg Loss", font, pal); y += rh + 2;

      //--- 6 Session
      y = DrawSection("S6", y, x, w, "◷", "SESSION INFORMATION", font, pal);
      StaticRow("E1", x, y, w, "Symbol / Timeframe", font, pal); y += rh;
      StaticRow("E2", x, y, w, "H4 Session ID", font, pal); y += rh;
      StaticRow("E3", x, y, w, "Last H4 Close", font, pal); y += rh;
      StaticRow("E4", x, y, w, "Next H4 Countdown", font, pal); y += rh;
      StaticRow("E5", x, y, w, "ATR-14 / Spread", font, pal); y += rh;
      StaticRow("E6", x, y, w, "Market Status", font, pal); y += rh + 2;

      //--- 7 System Health
      y = DrawSection("S7", y, x, w, "⚙", "SYSTEM HEALTH PANEL", font, pal);
      StaticRow("Y1", x, y, w, "EA Status", font, pal); y += rh;
      StaticRow("Y2", x, y, w, "Broker / Internet", font, pal); y += rh;
      StaticRow("Y3", x, y, w, "Market / Trading Permission", font, pal); y += rh;
      StaticRow("Y4", x, y, w, "Recovery / Logging", font, pal); y += rh;
      StaticRow("Y5", x, y, w, "Analytics / Dashboard", font, pal); y += rh;
      StaticRow("Y6", x, y, w, "CPU / RAM", font, pal); y += rh + 2;

      //--- GAUGES
      y = DrawSection("SG", y, x, w, "◎", "PERFORMANCE GAUGES", font, pal);
      StaticRow("G1", x, y, w, "Risk Level", font, pal); y += rh;
      StaticRow("G2", x, y, w, "Drawdown", font, pal); y += rh;
      StaticRow("G3", x, y, w, "Win Rate", font, pal); y += rh;
      StaticRow("G4", x, y, w, "Profit Factor", font, pal); y += rh;
      StaticRow("G5", x, y, w, "Recovery Factor", font, pal); y += rh;
      StaticRow("G6", x, y, w, "Execution Speed", font, pal); y += rh;
      StaticRow("G7", x, y, w, "Connection Quality", font, pal); y += rh;
      StaticRow("G8", x, y, w, "System Health", font, pal); y += rh + 2;

      //--- 8 AI Decision Center + Information Panel
      y = DrawSection("S8", y, x, w, "◎", "AI DECISION CENTER", font, pal);
      for(int ai = 0; ai < m_ai.PlaceholderCount(); ai++)
        {
         StaticRow("AI" + IntegerToString(ai), x, y, w, m_ai.LabelAt(ai), font, pal);
         y += rh;
        }
      y += 2;

      //--- MARKET INFORMATION (Sprint 6)
      y = DrawSection("SM", y, x, w, "◈", "MARKET INFORMATION", font, pal);
      StaticRow("MK1", x, y, w, "Current Symbol", font, pal); y += rh;
      StaticRow("MK2", x, y, w, "Current Spread", font, pal); y += rh;
      StaticRow("MK3", x, y, w, "ATR-14", font, pal); y += rh;
      StaticRow("MK4", x, y, w, "Current Candle Size", font, pal); y += rh;
      StaticRow("MK5", x, y, w, "Previous Candle Size", font, pal); y += rh;
      StaticRow("MK6", x, y, w, "Daily Range", font, pal); y += rh;
      StaticRow("MK7", x, y, w, "Weekly Range", font, pal); y += rh;
      StaticRow("MK8", x, y, w, "Current H4 Session", font, pal); y += rh;
      StaticRow("MK9", x, y, w, "Market Volatility", font, pal); y += rh;
      StaticRow("MK10", x, y, w, "Market Activity", font, pal); y += rh + 2;

      //--- MULTI-INSTANCE (Sprint 7)
      y = DrawSection("SI", y, x, w, "⧉", "MULTI-INSTANCE MONITOR", font, pal);
      StaticRow("MI1", x, y, w, "Current Instance ID", font, pal); y += rh;
      StaticRow("MI2", x, y, w, "Current Chart ID", font, pal); y += rh;
      StaticRow("MI3", x, y, w, "Running Instances", font, pal); y += rh;
      StaticRow("MI4", x, y, w, "Current Symbol", font, pal); y += rh;
      StaticRow("MI5", x, y, w, "Current Timeframe", font, pal); y += rh;
      StaticRow("MI6", x, y, w, "Instance Health", font, pal); y += rh;
      StaticRow("MI7", x, y, w, "Global Health", font, pal); y += rh;
      StaticRow("MI8", x, y, w, "Global Floating Profit", font, pal); y += rh;
      StaticRow("MI9", x, y, w, "Global Floating Loss", font, pal); y += rh;
      StaticRow("MI10", x, y, w, "Global Open Trades", font, pal); y += rh + 2;

      //--- NOTIFICATIONS + TIMELINE
      y = DrawSection("SN", y, x, w, "!", "SMART NOTIFICATIONS", font, pal);
      StaticRow("N0", x, y, w, "Latest Alert", font, pal); y += rh + 2;

      y = DrawSection("SL", y, x, w, "=", "ACTIVITY TIMELINE", font, pal);
      for(int ti = 0; ti < GM_DASH_TIMELINE_VIEW; ti++)
        {
         StaticRow("TL" + IntegerToString(ti), x, y, w, StringFormat("#%d", ti + 1), font, pal);
         y += rh;
        }
      y += 2;

      //--- REPORT PANEL (Sprint 5)
      y = DrawSection("SR", y, x, w, "▤", "REPORT PANEL", font, pal);
      StaticRow("RP1", x, y, w, "Today's Summary", font, pal); y += rh;
      StaticRow("RP2", x, y, w, "Last Winning Trade", font, pal); y += rh;
      StaticRow("RP3", x, y, w, "Last Losing Trade", font, pal); y += rh;
      StaticRow("RP4", x, y, w, "Largest Win", font, pal); y += rh;
      StaticRow("RP5", x, y, w, "Largest Loss", font, pal); y += rh;
      StaticRow("RP6", x, y, w, "Longest Winning Streak", font, pal); y += rh;
      StaticRow("RP7", x, y, w, "Longest Losing Streak", font, pal); y += rh;
      StaticRow("RP8", x, y, w, "Current Session Result", font, pal); y += rh;
      StaticRow("RP9", x, y, w, "Average Trade Time", font, pal); y += rh;
      StaticRow("RP10", x, y, w, "Alert Center", font, pal); y += rh + 2;

      //--- 9 Live monitor
      y = DrawSection("S9", y, x, w, "◉", "LIVE TRADE MONITOR", font, pal);
      StaticRow("M1", x, y, w, "Last Trade Result", font, pal); y += rh;
      StaticRow("M2", x, y, w, "Last Trade P/L", font, pal); y += rh;
      StaticRow("M3", x, y, w, "Floating Profit", font, pal); y += rh;
      StaticRow("M4", x, y, w, "Floating Loss", font, pal); y += rh;
      StaticRow("M5", x, y, w, "Floating Pips", font, pal); y += rh;
      StaticRow("M6", x, y, w, "Break Even Status", font, pal); y += rh;
      StaticRow("M7", x, y, w, "Trailing Status", font, pal); y += rh;
      StaticRow("M8", x, y, w, "Hedge Status", font, pal); y += rh;
      StaticRow("M9", x, y, w, "Current Trade Stage", font, pal); y += rh + 2;

      // Footer
      m_widgets.Rect("FTR", x, y0 + panel_h - footer_h, w, footer_h, pal.header_bg, pal.border);
      m_widgets.Label("FTR1", x + 8, y0 + panel_h - footer_h + 4,
                      "Project Owner: " + GM_OWNER_GROUP, pal.text, font - 1);
      m_widgets.Label("FTR2", x + 8, y0 + panel_h - footer_h + 18,
                      "Powered by " + GM_OWNER_DIVISION, pal.muted, font - 1);
      m_widgets.Label("FTR3", x + 8, y0 + panel_h - footer_h + 32,
                      StringFormat("Build %d  |  © %s", GM_VERSION_BUILD, GM_OWNER_GROUP),
                      pal.accent, font - 1);
      m_widgets.Label("RESIZE", x + w - 16, y0 + panel_h - 16, "◢", pal.muted, font);
      m_layout_built = true;

      // invalidate value cache so first Apply fills values
      for(int i = 0; i < m_val_count; i++)
         m_last_vals[i] = "";
     }

   void ApplySnapshot(const SGmDashboardSnapshot &s)
     {
      if(!m_visible || m_collapsed || !m_layout_built)
        {
         if(m_visible && !m_collapsed)
            Put(0, "STATUS_V", s.ea_status, StClr(s.ea_status));
         return;
        }

      const SGmDashPalette pal = m_theme.Palette();
      int i = 0;
      bool dirty = false;

      dirty |= Put(i++, "STATUS_V", s.ea_status, StClr(s.ea_status));

      if(m_settings.settings_panel_open)
        {
         dirty |= Put(i++, "ST1_V", m_theme.ThemeName(), pal.accent);
         dirty |= Put(i++, "ST2_V", m_settings.profile_name, pal.value);
         dirty |= Put(i++, "ST3_V", m_settings.language_code, pal.value);
         dirty |= Put(i++, "ST4_V",
                      StringFormat("%d / %s", m_settings.font_size,
                                   (m_settings.view_mode == GM_VIEW_COMPACT) ? "Compact"
                                   : ((m_settings.view_mode == GM_VIEW_STANDARD) ? "Standard" : "Pro")),
                      pal.value);
         dirty |= Put(i++, "ST5_V", m_settings.animations_enabled ? "ON" : "OFF",
                      m_settings.animations_enabled ? pal.success : pal.muted);
         dirty |= Put(i++, "ST6_V", IntegerToString(m_settings.transparency), pal.value);
         dirty |= Put(i++, "ST7_V", IntegerToString(m_settings.refresh_ms) + " ms", pal.value);
         dirty |= Put(i++, "ST8_V", m_settings.lock_position ? "LOCKED" : "UNLOCKED", pal.warn);
        }

      // Clock & context
      dirty |= Put(i++, "C1_V", s.clock_local, pal.value);
      dirty |= Put(i++, "C2_V", s.clock_server, pal.accent);
      dirty |= Put(i++, "C3_V",
                   StringFormat("%s / %s / #%d", s.symbol, s.timeframe, GM_VERSION_BUILD),
                   pal.accent);
      dirty |= Put(i++, "C4_V",
                   StringFormat("%.1f / %.5f", s.spread_points, s.atr14), pal.value);
      dirty |= Put(i++, "C5_V",
                   StringFormat("%s | SID %I64u", Countdown(s.h4_countdown_sec), s.session_id),
                   pal.warn);

      // Real-time performance
      dirty |= Put(i++, "P1_V",
                   StringFormat("%.2f / %.2f", s.balance, s.equity),
                   ValClr(s.equity - s.balance));
      dirty |= Put(i++, "P2_V",
                   StringFormat("%.2f / %.1f%%", s.free_margin, s.margin_level),
                   s.margin_level > 0 && s.margin_level < 200.0 ? pal.warn : pal.success);
      dirty |= Put(i++, "P3_V",
                   StringFormat("%.2f / %.2f", s.floating_profit, s.floating_loss),
                   ValClr(s.floating_profit - s.floating_loss));
      dirty |= Put(i++, "P4_V",
                   StringFormat("%+.2f / %+.2f", s.today_net, s.week_net),
                   ValClr(s.today_net));
      dirty |= Put(i++, "P5_V",
                   StringFormat("%+.2f / %+.2f", s.month_net, s.total_net),
                   ValClr(s.total_net));

      // Live trade widgets
      dirty |= Put(i++, "L1_V",
                   StringFormat("%d / %d", s.running_trades, s.pending_orders),
                   s.pending_orders > 0 ? pal.warn : pal.value);
      dirty |= Put(i++, "L2_V",
                   StringFormat("%d / %d", s.winning_open, s.losing_open), pal.value);
      dirty |= Put(i++, "L3_V",
                   StringFormat("%d / %d", s.buy_trades, s.sell_trades), pal.value);
      dirty |= Put(i++, "L4_V", IntegerToString(s.active_hedge), pal.muted);
      dirty |= Put(i++, "L5_V",
                   StringFormat("%.1f%% / %.0fs", s.trade_success_rate, s.avg_trade_duration_sec),
                   s.trade_success_rate >= 50.0 ? pal.profit : pal.loss);

      // KPI strip
      dirty |= Put(i++, "K1_V",
                   StringFormat("%.1f%% / %.1f%%", s.today_win_rate, s.today_loss_rate),
                   s.today_win_rate >= s.today_loss_rate ? pal.profit : pal.loss);
      dirty |= Put(i++, "K2_V",
                   StringFormat("%.2f / %.2f", s.balance, s.equity),
                   ValClr(s.equity - s.balance));
      dirty |= Put(i++, "K3_V",
                   StringFormat("%.2f / %.2f", s.floating_profit, s.floating_loss),
                   ValClr(s.floating_profit - s.floating_loss));
      dirty |= Put(i++, "K4_V",
                   StringFormat("%.2f / %.2f", s.risk_reward, s.profit_factor),
                   s.profit_factor >= 1.0 ? pal.profit : pal.loss);
      dirty |= Put(i++, "K5_V", StringFormat("%.2f", s.recovery_factor), pal.value);
      dirty |= Put(i++, "K6_V",
                   StringFormat("%.1f / %.5f", s.spread_points, s.atr14), pal.accent);
      dirty |= Put(i++, "K7_V", Countdown(s.h4_countdown_sec), pal.warn);
      dirty |= Put(i++, "K8_V", IntegerToString(s.trade_counter), pal.value);
      dirty |= Put(i++, "K9_V",
                   StringFormat("%.2f%% / %.2f%%", s.current_dd_pct, s.max_dd_pct),
                   ValClr(-s.current_dd_pct));

      dirty |= Put(i++, "A1_V", IntegerToString(s.account_login), pal.value);
      dirty |= Put(i++, "A2_V", s.broker_name, pal.value);
      dirty |= Put(i++, "A3_V", s.server_name, pal.value);
      dirty |= Put(i++, "A4_V", s.account_type, pal.value);
      dirty |= Put(i++, "A5_V", StringFormat("%s  1:%d", s.currency, s.leverage), pal.value);
      dirty |= Put(i++, "A6_V", MoneyAbs(s.balance), pal.value);
      dirty |= Put(i++, "A7_V", MoneyAbs(s.equity), ValClr(s.equity - s.balance));
      dirty |= Put(i++, "A8_V", MoneyAbs(s.free_margin), pal.value);
      dirty |= Put(i++, "A9_V", Pct(s.margin_level),
                   s.margin_level > 0 && s.margin_level < 200.0 ? pal.warn : pal.success);

      dirty |= Put(i++, "R1_V", Pct(s.auto_risk_pct), pal.accent);
      dirty |= Put(i++, "R2_V", Pct(s.current_risk_pct), ValClr(-s.current_risk_pct));
      dirty |= Put(i++, "R3_V", Pct(s.max_daily_risk_pct), pal.muted);
      dirty |= Put(i++, "R4_V", Pct(s.current_dd_pct), ValClr(-s.current_dd_pct));
      dirty |= Put(i++, "R5_V", Pct(s.max_dd_pct), pal.muted);
      dirty |= Put(i++, "R6_V", s.risk_status, StClr(s.risk_status));

      dirty |= Put(i++, "T1_V", IntegerToString(s.running_trades), pal.value);
      dirty |= Put(i++, "T2_V", IntegerToString(s.pending_orders),
                   s.pending_orders > 0 ? pal.warn : pal.value);
      dirty |= Put(i++, "T3_V", StringFormat("%d / %d", s.buy_trades, s.sell_trades), pal.value);
      dirty |= Put(i++, "T4_V", StringFormat("%d / %d", s.winning_open, s.losing_open), pal.value);
      dirty |= Put(i++, "T5_V",
                   StringFormat("%d (Cxl %d Exp %d)", s.active_hedge,
                                s.cancelled_orders, s.expired_orders), pal.muted);
      dirty |= Put(i++, "T6_V", s.trade_engine_status, StClr(s.trade_engine_status));

      dirty |= Put(i++, "D1_V", MoneyAbs(s.today_profit), pal.profit);
      dirty |= Put(i++, "D2_V", MoneyAbs(s.today_loss), pal.loss);
      dirty |= Put(i++, "D3_V", Money(s.today_net), ValClr(s.today_net));
      dirty |= Put(i++, "D4_V", StringFormat("%d / %d", s.today_opened, s.today_closed), pal.value);
      dirty |= Put(i++, "D5_V", StringFormat("%d / %d", s.today_winners, s.today_losers), pal.value);
      dirty |= Put(i++, "D6_V", Pct(s.today_win_rate),
                   s.today_win_rate >= 50.0 ? pal.profit : pal.loss);

      dirty |= Put(i++, "O1_V", IntegerToString(s.total_trades), pal.value);
      dirty |= Put(i++, "O2_V", StringFormat("%d / %d", s.total_winners, s.total_losers), pal.value);
      dirty |= Put(i++, "O3_V", Pct(s.overall_win_rate),
                   s.overall_win_rate >= 50.0 ? pal.profit : pal.loss);
      dirty |= Put(i++, "O4_V", StringFormat("%.2f", s.profit_factor),
                   s.profit_factor >= 1.0 ? pal.profit : pal.loss);
      dirty |= Put(i++, "O5_V", StringFormat("%.2f", s.recovery_factor), pal.value);
      dirty |= Put(i++, "O6_V",
                   StringFormat("%.2f / %.2f | RR %.2f", s.avg_win, s.avg_loss, s.risk_reward),
                   pal.value);

      dirty |= Put(i++, "E1_V", s.symbol + " / " + s.timeframe, pal.accent);
      dirty |= Put(i++, "E2_V", StringFormat("%I64u", s.session_id), pal.value);
      dirty |= Put(i++, "E3_V",
                   s.h4_cycle > 0 ? TimeToString(s.h4_cycle, TIME_DATE | TIME_MINUTES) : "—",
                   pal.value);
      dirty |= Put(i++, "E4_V", Countdown(s.h4_countdown_sec), pal.warn);
      dirty |= Put(i++, "E5_V",
                   StringFormat("%.5f / %.1f", s.atr14, s.spread_points), pal.value);
      dirty |= Put(i++, "E6_V", s.market_status, StClr(s.market_status));

      dirty |= Put(i++, "Y1_V", s.ea_module_status, StClr(s.ea_module_status));
      dirty |= Put(i++, "Y2_V",
                   StringFormat("%s / %s", s.broker_module_status, s.internet_module_status),
                   StClr(s.broker_module_status));
      dirty |= Put(i++, "Y3_V",
                   StringFormat("%s / %s", s.market_module_status, s.trading_perm_status),
                   StClr(s.trading_perm_status));
      dirty |= Put(i++, "Y4_V",
                   StringFormat("%s / %s", s.recovery_module_status, s.logging_module_status),
                   StClr(s.recovery_module_status));
      dirty |= Put(i++, "Y5_V",
                   StringFormat("%s / %s", s.analytics_module_status, s.dashboard_module_status),
                   StClr(s.dashboard_module_status));
      dirty |= Put(i++, "Y6_V",
                   StringFormat("n/a / %I64u KB", s.terminal_memory_kb), pal.muted);

      // Gauges
      dirty |= Put(i++, "G1_V", CGmPerformanceGauges::Bar(s.gauge_risk),
                   s.gauge_risk >= 70.0 ? pal.loss : (s.gauge_risk >= 40.0 ? pal.warn : pal.success));
      dirty |= Put(i++, "G2_V", CGmPerformanceGauges::Bar(s.gauge_dd),
                   s.gauge_dd >= 70.0 ? pal.loss : (s.gauge_dd >= 40.0 ? pal.warn : pal.success));
      dirty |= Put(i++, "G3_V", CGmPerformanceGauges::Bar(s.gauge_wr),
                   s.gauge_wr >= 50.0 ? pal.profit : pal.loss);
      dirty |= Put(i++, "G4_V", CGmPerformanceGauges::Bar(s.gauge_pf),
                   s.gauge_pf >= 33.0 ? pal.profit : pal.loss);
      dirty |= Put(i++, "G5_V", CGmPerformanceGauges::Bar(s.gauge_rf), pal.value);
      dirty |= Put(i++, "G6_V", CGmPerformanceGauges::Bar(s.gauge_speed),
                   s.gauge_speed >= 60.0 ? pal.success : pal.warn);
      dirty |= Put(i++, "G7_V", CGmPerformanceGauges::Bar(s.gauge_conn),
                   StClr(s.broker_module_status));
      dirty |= Put(i++, "G8_V", CGmPerformanceGauges::Bar(s.gauge_health),
                   StClr(s.analytics_health));

      // Sync AI widget values from snapshot
      SGmAISnapshot ai_snap;
      ai_snap.Reset();
      ai_snap.ai_status = s.ai_status;
      ai_snap.ai_version = s.ai_version;
      ai_snap.ai_engine = s.ai_engine;
      ai_snap.learning_status = s.ai_learning_status;
      ai_snap.decision_status = s.ai_decision_status;
      ai_snap.prediction_status = s.ai_prediction_status;
      ai_snap.confidence_status = s.ai_confidence_status;
      ai_snap.current_mode = s.ai_current_mode;
      ai_snap.future_ai_score = s.ai_future_score;
      ai_snap.w_market_analyzer = s.ai_market_analyzer;
      ai_snap.w_trend_detector = s.ai_trend_analyzer;
      ai_snap.w_volatility_scanner = s.ai_volatility_analyzer;
      ai_snap.w_news_analyzer = s.ai_news_analyzer;
      ai_snap.w_recovery_ai = s.ai_recovery;
      ai_snap.atr14 = s.atr14;
      ai_snap.valid = true;
      m_ai.Apply(ai_snap);

      for(int ai = 0; ai < m_ai.PlaceholderCount(); ai++)
         dirty |= Put(i++, "AI" + IntegerToString(ai) + "_V", m_ai.ValueAt(ai),
                      (StringFind(m_ai.ValueAt(ai), "COMING") >= 0 ||
                       StringFind(m_ai.ValueAt(ai), "NOT INIT") >= 0) ? pal.muted : pal.accent);

      dirty |= Put(i++, "MK1_V", s.symbol, pal.accent);
      dirty |= Put(i++, "MK2_V", StringFormat("%.1f", s.spread_points), pal.value);
      dirty |= Put(i++, "MK3_V", StringFormat("%.5f", s.atr14), pal.value);
      dirty |= Put(i++, "MK4_V", StringFormat("%.5f", s.mkt_candle_cur), pal.value);
      dirty |= Put(i++, "MK5_V", StringFormat("%.5f", s.mkt_candle_prev), pal.value);
      dirty |= Put(i++, "MK6_V", StringFormat("%.5f", s.mkt_daily_range), pal.value);
      dirty |= Put(i++, "MK7_V", StringFormat("%.5f", s.mkt_weekly_range), pal.value);
      dirty |= Put(i++, "MK8_V", StringFormat("%I64u", s.session_id), pal.value);
      dirty |= Put(i++, "MK9_V", s.mkt_volatility, pal.warn);
      dirty |= Put(i++, "MK10_V", s.mkt_activity, pal.value);

      dirty |= Put(i++, "MI1_V", s.mi_instance_id, pal.accent);
      dirty |= Put(i++, "MI2_V", IntegerToString(s.mi_chart_id), pal.value);
      dirty |= Put(i++, "MI3_V",
                   StringFormat("%d (%d symbols)", s.mi_running_instances, s.mi_active_symbols),
                   pal.value);
      dirty |= Put(i++, "MI4_V", s.mi_symbol, pal.accent);
      dirty |= Put(i++, "MI5_V", s.mi_timeframe, pal.value);
      dirty |= Put(i++, "MI6_V", StringFormat("%.0f", s.mi_instance_health),
                   s.mi_instance_health >= 70.0 ? pal.success : pal.warn);
      dirty |= Put(i++, "MI7_V", StringFormat("%.0f", s.mi_global_health),
                   s.mi_global_health >= 70.0 ? pal.success : pal.warn);
      dirty |= Put(i++, "MI8_V", StringFormat("%.2f", s.mi_global_floating_profit), pal.profit);
      dirty |= Put(i++, "MI9_V", StringFormat("%.2f", s.mi_global_floating_loss), pal.loss);
      dirty |= Put(i++, "MI10_V", IntegerToString(s.mi_global_open_trades), pal.value);

      dirty |= Put(i++, "N0_V",
                   (StringLen(s.notify_banner) > 0) ? s.notify_banner : "No alerts",
                   pal.accent);

      dirty |= Put(i++, "TL0_V", s.timeline_line0, pal.muted);
      dirty |= Put(i++, "TL1_V", s.timeline_line1, pal.muted);
      dirty |= Put(i++, "TL2_V", s.timeline_line2, pal.muted);
      dirty |= Put(i++, "TL3_V", s.timeline_line3, pal.muted);
      dirty |= Put(i++, "TL4_V", s.timeline_line4, pal.muted);
      dirty |= Put(i++, "TL5_V", s.timeline_line5, pal.muted);
      dirty |= Put(i++, "TL6_V", s.timeline_line6, pal.muted);
      dirty |= Put(i++, "TL7_V", s.timeline_line7, pal.muted);

      dirty |= Put(i++, "RP1_V", s.rpt_today_summary, pal.value);
      dirty |= Put(i++, "RP2_V", s.rpt_last_win, pal.profit);
      dirty |= Put(i++, "RP3_V", s.rpt_last_loss, pal.loss);
      dirty |= Put(i++, "RP4_V", s.rpt_largest_win, pal.profit);
      dirty |= Put(i++, "RP5_V", s.rpt_largest_loss, pal.loss);
      dirty |= Put(i++, "RP6_V", s.rpt_win_streak, pal.profit);
      dirty |= Put(i++, "RP7_V", s.rpt_loss_streak, pal.loss);
      dirty |= Put(i++, "RP8_V", s.rpt_session_result, pal.accent);
      dirty |= Put(i++, "RP9_V", s.rpt_avg_trade_time, pal.value);
      dirty |= Put(i++, "RP10_V",
                   StringFormat("%d | %s", s.rpt_alert_count,
                                (StringLen(s.rpt_last_alert) > 0) ? s.rpt_last_alert : "—"),
                   pal.warn);

      dirty |= Put(i++, "M1_V", s.last_trade_result, StClr(s.last_trade_result));
      dirty |= Put(i++, "M2_V", Money(s.last_trade_pnl), ValClr(s.last_trade_pnl));
      dirty |= Put(i++, "M3_V", MoneyAbs(s.floating_profit), pal.profit);
      dirty |= Put(i++, "M4_V", MoneyAbs(s.floating_loss), pal.loss);
      dirty |= Put(i++, "M5_V", StringFormat("%+.1f", s.floating_pips), ValClr(s.floating_pips));
      dirty |= Put(i++, "M6_V", s.be_status, StClr(s.be_status));
      dirty |= Put(i++, "M7_V", s.trail_status, StClr(s.trail_status));
      dirty |= Put(i++, "M8_V", s.hedge_status, pal.muted);
      dirty |= Put(i++, "M9_V", s.trade_stage, pal.accent);

      if(dirty)
         ChartRedraw(0);
     }
  };

#endif // GM_CDASHBOARD_RENDERER_MQH
//+------------------------------------------------------------------+
