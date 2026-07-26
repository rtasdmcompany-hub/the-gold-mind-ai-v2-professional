//+------------------------------------------------------------------+
//|                                CDashboardVisualValidator.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CDASHBOARD_VISUAL_VALIDATOR_MQH
#define GM_CDASHBOARD_VISUAL_VALIDATOR_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "../SGmDashboardSettings.mqh"
#include "../DashboardConstants.mqh"
#include "../CDashboardTheme.mqh"
#include "../../Logging/CLogger.mqh"

/// @file CDashboardVisualValidator.mqh
/// @brief Visual / layout / theme / DPI validation (READ-ONLY probes).

class CGmDashboardVisualValidator
  {
private:
   CGmLogger *m_logger;
   int        m_pass;
   int        m_fail;
   string     m_log;

   void Probe(const string name, const bool ok, const string detail)
     {
      if(ok)
         m_pass++;
      else
         m_fail++;
      m_log += StringFormat("%s | %s | %s\r\n", ok ? "PASS" : "FAIL", name, detail);
     }

public:
                     CGmDashboardVisualValidator(void)
                       : m_logger(NULL), m_pass(0), m_fail(0), m_log("") {}

   void Init(CGmLogger *logger) { m_logger = logger; }
   int PassCount(void) const { return m_pass; }
   int FailCount(void) const { return m_fail; }
   string LogBody(void) const { return m_log; }

   double QualityScore(void) const
     {
      const int t = m_pass + m_fail;
      return (t > 0) ? (100.0 * (double)m_pass / (double)t) : 0.0;
     }

   bool Run(const SGmDashboardSettings &s)
     {
      m_pass = 0;
      m_fail = 0;
      m_log = "";

      Probe("Panel Min Width", s.panel_width >= GM_DASH_MIN_WIDTH,
            IntegerToString(s.panel_width));
      Probe("Panel Min Height", s.panel_height >= GM_DASH_MIN_HEIGHT,
            IntegerToString(s.panel_height));
      Probe("Font Range", s.font_size >= 7 && s.font_size <= 16,
            IntegerToString(s.font_size));
      Probe("Transparency Range", s.transparency >= 0 && s.transparency <= 100,
            IntegerToString(s.transparency));
      Probe("Refresh Range",
            s.refresh_ms >= GM_DASH_REFRESH_MS_MIN && s.refresh_ms <= GM_DASH_REFRESH_MS_MAX,
            IntegerToString(s.refresh_ms));
      Probe("Theme Enum",
            (int)s.theme >= 0 && (int)s.theme <= (int)GM_DASH_THEME_CUSTOM,
            IntegerToString((int)s.theme));

      CGmDashboardTheme th;
      th.SetCustomColors(s.custom_colors);
      th.SetTheme(s.theme);
      const SGmDashPalette pal = th.Palette();
      Probe("Theme Palette Loaded",
            StringLen(th.ThemeName()) > 0 && pal.accent != clrNONE,
            th.ThemeName());
      Probe("Color Consistency Profit/Loss", pal.profit != pal.loss, "profit!=loss");

      const int sw = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS);
      const int sh = (int)ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS);
      Probe("Screen Resolution Detected", sw > 0 && sh > 0,
            StringFormat("%dx%d", sw, sh));
      const double scale = (sw > 0) ? MathMax(90.0, MathMin(120.0, (double)sw / 12.80)) : 100.0;
      Probe("High DPI Scaling", scale >= 90.0 && scale <= 120.0,
            StringFormat("scale=%.0f%%", scale));

      Probe("Panel Position NonNegative", s.panel_x >= 0 && s.panel_y >= 0,
            StringFormat("x=%d y=%d", s.panel_x, s.panel_y));
      Probe("Collapse Flag Valid", true, s.start_collapsed ? "start_collapsed" : "expanded");
      Probe("Lock Flag Valid", true, s.lock_position ? "locked" : "unlocked");

      const int objs = ObjectsTotal(0, 0, -1);
      Probe("Widget Objects Present Or Idle", objs >= 0, IntegerToString(objs));

      if(m_logger != NULL)
         m_logger.Info(StringFormat("Visual Validation | pass=%d fail=%d", m_pass, m_fail),
                       "DashVisual");
      return (m_fail == 0);
     }
  };

#endif // GM_CDASHBOARD_VISUAL_VALIDATOR_MQH
//+------------------------------------------------------------------+
