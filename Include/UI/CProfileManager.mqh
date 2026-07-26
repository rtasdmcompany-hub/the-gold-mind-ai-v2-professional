//+------------------------------------------------------------------+
//|                                           CProfileManager.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CPROFILE_MANAGER_MQH
#define GM_CPROFILE_MANAGER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "UIConstants.mqh"
#include "../Dashboard/SGmDashboardSettings.mqh"
#include "../Core/CFileManager.mqh"
#include "../Logging/CLogger.mqh"

/// @file CProfileManager.mqh
/// @brief User UI profiles — theme/layout/widgets/display (no trading state).

class CGmProfileManager
  {
private:
   CGmLogger       *m_logger;
   CGmFileManager  *m_files;
   long             m_magic;
   string           m_names[GM_UI_PROFILE_MAX];
   int              m_count;
   int              m_active;

   string ProfileFile(const string name) const
     {
      string n = name;
      StringReplace(n, " ", "_");
      return StringFormat("%s%I64d_%s.prof", GM_UI_PROFILE_PREFIX, m_magic, n);
     }

   string Serialize(const SGmDashboardSettings &s) const
     {
      return StringFormat(
                "%s|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|"
                "%d|%d|%d|%d|%d|%d|%d|%d|%d|%d",
                s.profile_name, s.panel_x, s.panel_y, s.panel_width, s.panel_height,
                s.refresh_ms, (int)s.theme, s.transparency, s.font_size,
                (int)s.font_preset, (int)s.view_mode, (int)s.language,
                s.animations_enabled ? 1 : 0,
                s.show_ai_section ? 1 : 0, s.show_market_section ? 1 : 0,
                s.show_report_section ? 1 : 0, s.show_gauges ? 1 : 0,
                s.show_timeline ? 1 : 0, s.show_multi_instance ? 1 : 0,
                s.show_notifications ? 1 : 0, s.lock_position ? 1 : 0,
                (int)s.custom_colors.bg, (int)s.custom_colors.header,
                (int)s.custom_colors.border, (int)s.custom_colors.text,
                (int)s.custom_colors.profit, (int)s.custom_colors.loss,
                (int)s.custom_colors.warn, (int)s.custom_colors.success,
                (int)s.custom_colors.widget, (int)s.custom_colors.highlight,
                s.custom_colors.used ? 1 : 0);
     }

   bool Deserialize(const string line, SGmDashboardSettings &s)
     {
      string p[];
      if(StringSplit(line, '|', p) < 22)
         return false;
      s.Defaults();
      s.profile_name = p[0];
      s.panel_x = (int)StringToInteger(p[1]);
      s.panel_y = (int)StringToInteger(p[2]);
      s.panel_width = (int)StringToInteger(p[3]);
      s.panel_height = (int)StringToInteger(p[4]);
      s.refresh_ms = (int)StringToInteger(p[5]);
      s.theme = (ENUM_GM_DASH_THEME)StringToInteger(p[6]);
      s.transparency = (int)StringToInteger(p[7]);
      s.font_size = (int)StringToInteger(p[8]);
      s.font_preset = (ENUM_GM_FONT_PRESET)StringToInteger(p[9]);
      s.view_mode = (ENUM_GM_VIEW_MODE)StringToInteger(p[10]);
      s.language = (ENUM_GM_UI_LANG)StringToInteger(p[11]);
      s.animations_enabled = (StringToInteger(p[12]) != 0);
      s.show_ai_section = (StringToInteger(p[13]) != 0);
      s.show_market_section = (StringToInteger(p[14]) != 0);
      s.show_report_section = (StringToInteger(p[15]) != 0);
      s.show_gauges = (StringToInteger(p[16]) != 0);
      s.show_timeline = (StringToInteger(p[17]) != 0);
      s.show_multi_instance = (StringToInteger(p[18]) != 0);
      s.show_notifications = (StringToInteger(p[19]) != 0);
      s.lock_position = (StringToInteger(p[20]) != 0);
      if(ArraySize(p) >= 32)
        {
         s.custom_colors.bg = (color)StringToInteger(p[21]);
         s.custom_colors.header = (color)StringToInteger(p[22]);
         s.custom_colors.border = (color)StringToInteger(p[23]);
         s.custom_colors.text = (color)StringToInteger(p[24]);
         s.custom_colors.profit = (color)StringToInteger(p[25]);
         s.custom_colors.loss = (color)StringToInteger(p[26]);
         s.custom_colors.warn = (color)StringToInteger(p[27]);
         s.custom_colors.success = (color)StringToInteger(p[28]);
         s.custom_colors.widget = (color)StringToInteger(p[29]);
         s.custom_colors.highlight = (color)StringToInteger(p[30]);
         s.custom_colors.used = (StringToInteger(p[31]) != 0);
        }
      s.language_code = (s.language == GM_LANG_UR) ? "ur" : ((s.language == GM_LANG_AR) ? "ar" : "en");
      s.Clamp();
      return true;
     }

public:
                     CGmProfileManager(void)
                       : m_logger(NULL), m_files(NULL), m_magic(0), m_count(0), m_active(0)
     {
      for(int i = 0; i < GM_UI_PROFILE_MAX; i++)
         m_names[i] = "";
     }

   void Init(CGmLogger *logger, CGmFileManager *files, const long magic)
     {
      m_logger = logger;
      m_files = files;
      m_magic = magic;
      m_count = 1;
      m_names[0] = "Default";
      m_active = 0;
      if(GlobalVariableCheck(GM_UI_ACTIVE_PROFILE_GV))
        {
         const int idx = (int)GlobalVariableGet(GM_UI_ACTIVE_PROFILE_GV);
         if(idx >= 0 && idx < GM_UI_PROFILE_MAX)
            m_active = idx;
        }
     }

   int Count(void) const { return m_count; }
   int ActiveIndex(void) const { return m_active; }
   string ActiveName(void) const
     {
      if(m_active >= 0 && m_active < m_count)
         return m_names[m_active];
      return "Default";
     }

   bool SaveProfile(const string name, const SGmDashboardSettings &s_in)
     {
      if(m_files == NULL || StringLen(name) == 0)
         return false;
      SGmDashboardSettings s = s_in;
      s.profile_name = name;
      s.Clamp();
      const bool ok = m_files.WriteText(ProfileFile(name),
                                        "#GM_UI_PROFILE\r\n" + Serialize(s) + "\r\n");
      if(ok)
        {
         bool known = false;
         for(int i = 0; i < m_count; i++)
           {
            if(m_names[i] == name)
              {
               known = true;
               m_active = i;
               break;
              }
           }
         if(!known && m_count < GM_UI_PROFILE_MAX)
           {
            m_names[m_count] = name;
            m_active = m_count;
            m_count++;
           }
         GlobalVariableSet(GM_UI_ACTIVE_PROFILE_GV, (double)m_active);
         if(m_logger != NULL)
            m_logger.Info("Profile Saved | " + name, "ProfileManager");
        }
      return ok;
     }

   bool LoadProfile(const string name, SGmDashboardSettings &s)
     {
      if(m_files == NULL)
         return false;
      const string file = ProfileFile(name);
      if(!m_files.Exists(file))
         return false;
      string body = "";
      if(!m_files.ReadText(file, body))
         return false;
      string lines[];
      const int n = StringSplit(body, '\n', lines);
      for(int i = 0; i < n; i++)
        {
         string line = lines[i];
         StringTrimLeft(line);
         StringTrimRight(line);
         if(StringLen(line) < 8 || StringGetCharacter(line, 0) == '#')
            continue;
         if(!Deserialize(line, s))
            continue;
         for(int k = 0; k < m_count; k++)
           {
            if(m_names[k] == name)
              {
               m_active = k;
               break;
              }
           }
         GlobalVariableSet(GM_UI_ACTIVE_PROFILE_GV, (double)m_active);
         if(m_logger != NULL)
            m_logger.Info("Profile Loaded | " + name, "ProfileManager");
         return true;
        }
      return false;
     }

   string CycleProfileSlot(void)
     {
      string presets0 = "Default";
      string presets1 = "Pro";
      string presets2 = "Compact";
      string presets3 = "Favorite";
      m_active = (m_active + 1) % 4;
      m_names[0] = presets0;
      m_names[1] = presets1;
      m_names[2] = presets2;
      m_names[3] = presets3;
      if(m_count < 4)
         m_count = 4;
      GlobalVariableSet(GM_UI_ACTIVE_PROFILE_GV, (double)m_active);
      return m_names[m_active];
     }
  };

#endif // GM_CPROFILE_MANAGER_MQH
//+------------------------------------------------------------------+
