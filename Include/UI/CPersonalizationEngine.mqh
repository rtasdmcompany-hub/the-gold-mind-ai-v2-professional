//+------------------------------------------------------------------+
//|                                    CPersonalizationEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//|     Phase 2 Sprint 8 — Theme / Profile / Layout / Locale (UI)   |
//+------------------------------------------------------------------+
#ifndef GM_CPERSONALIZATION_ENGINE_MQH
#define GM_CPERSONALIZATION_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "CLocalization.mqh"
#include "CAnimationEngine.mqh"
#include "CLayoutManager.mqh"
#include "CProfileManager.mqh"
#include "../Dashboard/SGmDashboardSettings.mqh"
#include "../Dashboard/CDashboardTheme.mqh"
#include "../Core/CFileManager.mqh"
#include "../Logging/CLogger.mqh"

/// @file CPersonalizationEngine.mqh
/// @brief UI personalization orchestrator — NEVER touches trading.

class CGmPersonalizationEngine
  {
private:
   CGmLogger             *m_logger;
   CGmFileManager        *m_files;
   CGmLocalization        m_locale;
   CGmAnimationEngine     m_anim;
   CGmLayoutManager       m_layout;
   CGmProfileManager      m_profiles;
   CGmDashboardTheme      m_theme;
   SGmDashboardSettings   m_settings;
   bool                   m_ready;

public:
                     CGmPersonalizationEngine(void)
                       : m_logger(NULL), m_files(NULL), m_ready(false)
     {
      m_settings.Defaults();
     }

   bool Init(CGmLogger *logger,
             CGmFileManager *files,
             const long magic,
             const SGmDashboardSettings &settings)
     {
      m_logger = logger;
      m_files = files;
      m_settings = settings;
      m_settings.Clamp();

      m_layout.Init(logger);
      m_layout.LoadLayout(m_settings);
      m_profiles.Init(logger, files, magic);
      m_locale.Init(logger, m_settings.language);
      m_anim.Init(logger, m_settings.animations_enabled);
      m_theme.SetCustomColors(m_settings.custom_colors);
      m_theme.SetTheme(m_settings.theme);

      // Try load active profile file if present
      SGmDashboardSettings loaded;
      if(m_profiles.LoadProfile(m_profiles.ActiveName(), loaded))
        {
         // Keep panel position from layout GV if newer — merge theme prefs
         const int px = m_settings.panel_x;
         const int py = m_settings.panel_y;
         m_settings = loaded;
         m_settings.panel_x = px;
         m_settings.panel_y = py;
         m_settings.Clamp();
         m_theme.SetCustomColors(m_settings.custom_colors);
         m_theme.SetTheme(m_settings.theme);
         m_locale.SetLanguage(m_settings.language);
         m_anim.SetEnabled(m_settings.animations_enabled);
        }

      m_ready = true;
      if(m_logger != NULL)
         m_logger.Success(StringFormat("Personalization ready | theme=%s | profile=%s | lang=%s",
                                       m_theme.ThemeName(), m_settings.profile_name,
                                       m_locale.Name()),
                          "Personalization");
      return true;
     }

   void Shutdown(void)
     {
      if(m_ready)
         SaveCurrentProfile();
      m_ready = false;
     }

   bool IsReady(void) const { return m_ready; }
   SGmDashboardSettings Settings(void) const { return m_settings; }
   CGmDashboardTheme *Theme(void) { return GetPointer(m_theme); }
   CGmLocalization *Locale(void) { return GetPointer(m_locale); }
   CGmAnimationEngine *Anim(void) { return GetPointer(m_anim); }
   CGmLayoutManager *Layout(void) { return GetPointer(m_layout); }
   CGmProfileManager *Profiles(void) { return GetPointer(m_profiles); }

   void SyncSettings(SGmDashboardSettings &out) const
     {
      out = m_settings;
     }

   void ApplySettings(const SGmDashboardSettings &s)
     {
      m_settings = s;
      m_settings.Clamp();
      m_theme.SetCustomColors(m_settings.custom_colors);
      m_theme.SetTheme(m_settings.theme);
      m_locale.SetLanguage(m_settings.language);
      m_settings.language_code = m_locale.Code();
      m_anim.SetEnabled(m_settings.animations_enabled);
     }

   void CycleTheme(void)
     {
      m_settings.theme = m_theme.CycleNext();
      if(m_logger != NULL)
         m_logger.Info("Theme Changed | " + m_theme.ThemeName(), "ThemeEngine");
     }

   void CycleLanguage(void)
     {
      m_settings.language = m_locale.CycleNext();
      m_settings.language_code = m_locale.Code();
     }

   void CycleFont(void)
     {
      int f = (int)m_settings.font_preset + 1;
      if(f > (int)GM_FONT_XLARGE)
         f = 0;
      m_settings.font_preset = (ENUM_GM_FONT_PRESET)f;
      m_settings.ApplyFontPreset();
      if(m_logger != NULL)
         m_logger.Info(StringFormat("Settings Updated | font_preset=%d size=%d",
                                    (int)m_settings.font_preset, m_settings.font_size),
                       "Personalization");
     }

   void CycleViewMode(void)
     {
      int v = (int)m_settings.view_mode + 1;
      if(v > (int)GM_VIEW_PROFESSIONAL)
         v = 0;
      m_settings.view_mode = (ENUM_GM_VIEW_MODE)v;
     }

   void ToggleAnimations(void)
     {
      m_anim.Toggle();
      m_settings.animations_enabled = m_anim.Enabled();
     }

   void ToggleSettingsPanel(void)
     {
      m_settings.settings_panel_open = !m_settings.settings_panel_open;
     }

   void CycleTransparency(void)
     {
      m_settings.transparency += 10;
      if(m_settings.transparency > 60)
         m_settings.transparency = 0;
      m_settings.Clamp();
      if(m_logger != NULL)
         m_logger.Info(StringFormat("Settings Updated | transparency=%d",
                                    m_settings.transparency),
                       "Personalization");
     }

   void CycleRefresh(void)
     {
      if(m_settings.refresh_ms <= 250)
         m_settings.refresh_ms = 500;
      else if(m_settings.refresh_ms <= 500)
         m_settings.refresh_ms = 1000;
      else if(m_settings.refresh_ms <= 1000)
         m_settings.refresh_ms = 2000;
      else
         m_settings.refresh_ms = 250;
      m_settings.Clamp();
     }

   void ToggleWidgetVisibility(const int which)
     {
      // 0 AI, 1 Market, 2 Report, 3 Gauges, 4 Timeline, 5 Multi, 6 Notify
      switch(which)
        {
         case 0: m_settings.show_ai_section = !m_settings.show_ai_section; break;
         case 1: m_settings.show_market_section = !m_settings.show_market_section; break;
         case 2: m_settings.show_report_section = !m_settings.show_report_section; break;
         case 3: m_settings.show_gauges = !m_settings.show_gauges; break;
         case 4: m_settings.show_timeline = !m_settings.show_timeline; break;
         case 5: m_settings.show_multi_instance = !m_settings.show_multi_instance; break;
         case 6: m_settings.show_notifications = !m_settings.show_notifications; break;
        }
      if(m_logger != NULL)
         m_logger.Info("Widget Hidden/Shown toggled", "Personalization");
     }

   void SaveCurrentProfile(void)
     {
      m_layout.SaveLayout(m_settings);
      m_profiles.SaveProfile(m_settings.profile_name, m_settings);
     }

   void LoadCycledProfile(void)
     {
      const string name = m_profiles.CycleProfileSlot();
      SGmDashboardSettings loaded;
      if(m_profiles.LoadProfile(name, loaded))
         ApplySettings(loaded);
      else
        {
         m_settings.profile_name = name;
         if(name == "Compact")
           {
            m_settings.view_mode = GM_VIEW_COMPACT;
            m_settings.font_preset = GM_FONT_SMALL;
            m_settings.show_timeline = false;
            m_settings.show_gauges = false;
           }
         else if(name == "Pro")
           {
            m_settings.view_mode = GM_VIEW_PROFESSIONAL;
            m_settings.font_preset = GM_FONT_MEDIUM;
            m_settings.show_ai_section = true;
            m_settings.show_multi_instance = true;
           }
         m_settings.Clamp();
         ApplySettings(m_settings);
         SaveCurrentProfile();
        }
     }

   void ResetAll(void)
     {
      m_layout.RestoreDefault(m_settings);
      const bool en = m_settings.enable_dashboard;
      m_settings.Defaults();
      m_settings.enable_dashboard = en;
      m_settings.panel_x = GM_DASH_DEFAULT_X;
      m_settings.panel_y = GM_DASH_DEFAULT_Y;
      ApplySettings(m_settings);
      SaveCurrentProfile();
      if(m_logger != NULL)
         m_logger.Info("Settings Updated | Reset to Default", "Personalization");
     }

   string SettingsSummary(void) const
     {
      return StringFormat("%s | %s | %s | Font%d | T%d | Anim %s | Ref %dms",
                          m_theme.ThemeName(),
                          m_settings.profile_name,
                          m_locale.Name(),
                          m_settings.font_size,
                          m_settings.transparency,
                          m_settings.animations_enabled ? "ON" : "OFF",
                          m_settings.refresh_ms);
     }

   void Process(void)
     {
      if(!m_ready)
         return;
      m_anim.TickPulse();
     }
  };

#endif // GM_CPERSONALIZATION_ENGINE_MQH
//+------------------------------------------------------------------+
