//+------------------------------------------------------------------+
//|                                   SGmDashboardSettings.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_SGM_DASHBOARD_SETTINGS_MQH
#define GM_SGM_DASHBOARD_SETTINGS_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "DashboardConstants.mqh"
#include "EnumsDashboard.mqh"
#include "CDashboardTheme.mqh"

/// @file SGmDashboardSettings.mqh
/// @brief Dashboard + personalization settings (UI only — Sprint 8).

struct SGmDashboardSettings
  {
   bool                 enable_dashboard;
   int                  panel_x;
   int                  panel_y;
   int                  panel_width;
   int                  panel_height;
   int                  refresh_ms;
   ENUM_GM_DASH_THEME   theme;
   int                  transparency;
   int                  font_size;
   string               language_code;
   bool                 auto_refresh;
   bool                 start_collapsed;
   bool                 lock_position;

   //--- Sprint 8 personalization
   string               profile_name;
   ENUM_GM_FONT_PRESET  font_preset;
   ENUM_GM_VIEW_MODE    view_mode;
   ENUM_GM_UI_LANG      language;
   bool                 animations_enabled;
   bool                 settings_panel_open;
   bool                 show_ai_section;
   bool                 show_market_section;
   bool                 show_report_section;
   bool                 show_gauges;
   bool                 show_timeline;
   bool                 show_multi_instance;
   bool                 show_notifications;
   SGmCustomColors      custom_colors;

   void Defaults(void)
     {
      enable_dashboard = GM_DASH_ENABLE_DEFAULT;
      panel_x = GM_DASH_DEFAULT_X;
      panel_y = GM_DASH_DEFAULT_Y;
      panel_width = GM_DASH_DEFAULT_WIDTH;
      panel_height = GM_DASH_DEFAULT_HEIGHT;
      refresh_ms = GM_DASH_REFRESH_MS_DEFAULT;
      theme = GM_DASH_THEME_GOLD;
      transparency = GM_DASH_TRANSPARENCY_DEFAULT;
      font_size = GM_DASH_FONT_SIZE_DEFAULT;
      language_code = "en";
      auto_refresh = true;
      start_collapsed = false;
      lock_position = false;
      profile_name = "Default";
      font_preset = GM_FONT_MEDIUM;
      view_mode = GM_VIEW_PROFESSIONAL;
      language = GM_LANG_EN;
      animations_enabled = false;
      settings_panel_open = false;
      show_ai_section = true;
      show_market_section = true;
      show_report_section = true;
      show_gauges = true;
      show_timeline = true;
      show_multi_instance = true;
      show_notifications = true;
      custom_colors.Defaults();
     }

   void ApplyFontPreset(void)
     {
      switch(font_preset)
        {
         case GM_FONT_SMALL:  font_size = 7; break;
         case GM_FONT_LARGE:  font_size = 10; break;
         case GM_FONT_XLARGE: font_size = 12; break;
         default:             font_size = 8; break;
        }
     }

   void Clamp(void)
     {
      if(panel_width < GM_DASH_MIN_WIDTH)
         panel_width = GM_DASH_MIN_WIDTH;
      if(panel_height < GM_DASH_MIN_HEIGHT)
         panel_height = GM_DASH_MIN_HEIGHT;
      if(refresh_ms < GM_DASH_REFRESH_MS_MIN)
         refresh_ms = GM_DASH_REFRESH_MS_MIN;
      if(refresh_ms > GM_DASH_REFRESH_MS_MAX)
         refresh_ms = GM_DASH_REFRESH_MS_MAX;
      if(transparency < 0)
         transparency = 0;
      if(transparency > 100)
         transparency = 100;
      ApplyFontPreset();
      if(font_size < 7)
         font_size = 7;
      if(font_size > 16)
         font_size = 16;
      if(StringLen(language_code) == 0)
         language_code = "en";
      if(StringLen(profile_name) == 0)
         profile_name = "Default";
     }
  };

#endif // GM_SGM_DASHBOARD_SETTINGS_MQH
//+------------------------------------------------------------------+
