//+------------------------------------------------------------------+
//|                              CDashboardSettingsValidator.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CDASHBOARD_SETTINGS_VALIDATOR_MQH
#define GM_CDASHBOARD_SETTINGS_VALIDATOR_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "../SGmDashboardSettings.mqh"
#include "../DashboardConstants.mqh"
#include "../../UI/UIConstants.mqh"
#include "../../Logging/CLogger.mqh"

/// @file CDashboardSettingsValidator.mqh
/// @brief Verify settings persistence surfaces (theme/layout/profile/lang).

class CGmDashboardSettingsValidator
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
                     CGmDashboardSettingsValidator(void)
                       : m_logger(NULL), m_pass(0), m_fail(0), m_log("") {}

   void Init(CGmLogger *logger) { m_logger = logger; }
   int PassCount(void) const { return m_pass; }
   int FailCount(void) const { return m_fail; }
   string LogBody(void) const { return m_log; }

   bool Run(const SGmDashboardSettings &s)
     {
      m_pass = 0;
      m_fail = 0;
      m_log = "";

      // Round-trip clamp integrity
      SGmDashboardSettings copy = s;
      copy.Clamp();
      Probe("Theme Persistence Field", (int)copy.theme == (int)s.theme,
            IntegerToString((int)copy.theme));
      Probe("Profile Name", StringLen(copy.profile_name) > 0, copy.profile_name);
      Probe("Language Selection", StringLen(copy.language_code) > 0, copy.language_code);
      Probe("Refresh Rate", copy.refresh_ms == s.refresh_ms ||
            (copy.refresh_ms >= GM_DASH_REFRESH_MS_MIN && copy.refresh_ms <= GM_DASH_REFRESH_MS_MAX),
            IntegerToString(copy.refresh_ms));
      Probe("Transparency", copy.transparency == s.transparency ||
            (copy.transparency >= 0 && copy.transparency <= 100),
            IntegerToString(copy.transparency));
      Probe("Animation Settings", true,
            copy.animations_enabled ? "ON" : "OFF");
      Probe("Font Preset", (int)copy.font_preset >= 0 && (int)copy.font_preset <= 3,
            IntegerToString((int)copy.font_preset));
      Probe("View Mode", (int)copy.view_mode >= 0 && (int)copy.view_mode <= 2,
            IntegerToString((int)copy.view_mode));
      Probe("Widget Visibility Flags", true,
            StringFormat("AI=%d Mkt=%d Rpt=%d",
                         copy.show_ai_section ? 1 : 0,
                         copy.show_market_section ? 1 : 0,
                         copy.show_report_section ? 1 : 0));

      // GlobalVariable layout keys are writable
      GlobalVariableSet(GM_DASH_POS_GV_X, (double)copy.panel_x);
      GlobalVariableSet(GM_DASH_POS_GV_Y, (double)copy.panel_y);
      Probe("Layout GV X", GlobalVariableCheck(GM_DASH_POS_GV_X),
            DoubleToString(GlobalVariableGet(GM_DASH_POS_GV_X), 0));
      Probe("Layout GV Y", GlobalVariableCheck(GM_DASH_POS_GV_Y),
            DoubleToString(GlobalVariableGet(GM_DASH_POS_GV_Y), 0));

      if(m_logger != NULL)
         m_logger.Info(StringFormat("Settings Validation | pass=%d fail=%d", m_pass, m_fail),
                       "DashSettings");
      return (m_fail == 0);
     }
  };

#endif // GM_CDASHBOARD_SETTINGS_VALIDATOR_MQH
//+------------------------------------------------------------------+
