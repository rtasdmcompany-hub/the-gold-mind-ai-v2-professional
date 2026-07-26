//+------------------------------------------------------------------+
//|                                            CLocalization.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CLOCALIZATION_MQH
#define GM_CLOCALIZATION_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "../Dashboard/EnumsDashboard.mqh"
#include "../Logging/CLogger.mqh"

/// @file CLocalization.mqh
/// @brief Multi-language string resources — separated from trading logic.

class CGmLocalization
  {
private:
   CGmLogger       *m_logger;
   ENUM_GM_UI_LANG  m_lang;

public:
                     CGmLocalization(void) : m_logger(NULL), m_lang(GM_LANG_EN) {}

   void Init(CGmLogger *logger, const ENUM_GM_UI_LANG lang)
     {
      m_logger = logger;
      m_lang = lang;
     }

   ENUM_GM_UI_LANG Language(void) const { return m_lang; }

   void SetLanguage(const ENUM_GM_UI_LANG lang)
     {
      m_lang = lang;
      if(m_logger != NULL)
         m_logger.Info("Settings Updated | language=" + Code(), "Localization");
     }

   ENUM_GM_UI_LANG CycleNext(void)
     {
      int l = (int)m_lang + 1;
      if(l > (int)GM_LANG_AR)
         l = 0;
      SetLanguage((ENUM_GM_UI_LANG)l);
      return m_lang;
     }

   string Code(void) const
     {
      if(m_lang == GM_LANG_UR)
         return "ur";
      if(m_lang == GM_LANG_AR)
         return "ar";
      return "en";
     }

   string Name(void) const
     {
      if(m_lang == GM_LANG_UR)
         return "Urdu";
      if(m_lang == GM_LANG_AR)
         return "Arabic";
      return "English";
     }

   /// @brief Lookup UI label by key (resource table — future packs extend here).
   string T(const string key) const
     {
      if(m_lang == GM_LANG_UR)
        {
         if(key == "settings") return "Settings";
         if(key == "theme") return "Theme";
         if(key == "profile") return "Profile";
         if(key == "layout") return "Layout";
         if(key == "coming") return "جلد";
        }
      if(m_lang == GM_LANG_AR)
        {
         if(key == "settings") return "Settings";
         if(key == "theme") return "Theme";
         if(key == "profile") return "Profile";
         if(key == "layout") return "Layout";
         if(key == "coming") return "قريبا";
        }
      // English + future packs default
      if(key == "settings") return "Settings";
      if(key == "theme") return "Theme";
      if(key == "profile") return "Profile";
      if(key == "layout") return "Layout";
      if(key == "anim_on") return "Animations ON";
      if(key == "anim_off") return "Animations OFF";
      if(key == "reset") return "Reset Default";
      if(key == "coming") return "Coming Soon";
      return key;
     }
  };

#endif // GM_CLOCALIZATION_MQH
//+------------------------------------------------------------------+
