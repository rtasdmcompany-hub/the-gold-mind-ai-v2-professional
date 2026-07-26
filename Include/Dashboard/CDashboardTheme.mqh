//+------------------------------------------------------------------+
//|                                         CDashboardTheme.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CDASHBOARD_THEME_MQH
#define GM_CDASHBOARD_THEME_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "EnumsDashboard.mqh"

/// @file CDashboardTheme.mqh
/// @brief Sprint 8 Theme Engine — multiple enterprise palettes (UI only).

struct SGmDashPalette
  {
   color bg;
   color header_bg;
   color section_bg;
   color border;
   color text;
   color value;
   color muted;
   color accent;
   color profit;
   color loss;
   color warn;
   color paused;
   color success;
   color widget;
   color highlight;
  };

struct SGmCustomColors
  {
   color bg;
   color header;
   color border;
   color text;
   color profit;
   color loss;
   color warn;
   color success;
   color widget;
   color highlight;
   bool  used;

   void Defaults(void)
     {
      bg = C'12,12,14';
      header = C'36,28,12';
      border = C'196,154,58';
      text = C'245,245,245';
      profit = C'46,190,110';
      loss = C'220,70,70';
      warn = C'220,190,60';
      success = C'46,190,110';
      widget = C'18,18,20';
      highlight = C'212,175,55';
      used = false;
     }
  };

class CGmDashboardTheme
  {
private:
   ENUM_GM_DASH_THEME m_theme;
   SGmDashPalette     m_pal;
   SGmCustomColors    m_custom;

   void Fill(const color bg, const color header, const color section, const color border,
             const color text, const color value, const color muted, const color accent,
             const color profit, const color loss, const color warn, const color paused,
             const color success, const color widget, const color highlight)
     {
      m_pal.bg = bg;
      m_pal.header_bg = header;
      m_pal.section_bg = section;
      m_pal.border = border;
      m_pal.text = text;
      m_pal.value = value;
      m_pal.muted = muted;
      m_pal.accent = accent;
      m_pal.profit = profit;
      m_pal.loss = loss;
      m_pal.warn = warn;
      m_pal.paused = paused;
      m_pal.success = success;
      m_pal.widget = widget;
      m_pal.highlight = highlight;
     }

   void ApplyBlackGold(void)
     {
      Fill(C'12,12,14', C'36,28,12', C'18,18,20', C'196,154,58',
           C'245,245,245', C'255,255,255', C'140,140,148', C'212,175,55',
           C'46,190,110', C'220,70,70', C'220,190,60', C'230,140,50',
           C'46,190,110', C'22,22,26', C'232,196,80');
     }

   void ApplyDarkGray(void)
     {
      Fill(C'28,28,30', C'40,40,44', C'34,34,38', C'120,120,128',
           C'235,235,238', C'250,250,252', C'150,150,158', C'180,180,190',
           C'70,200,130', C'220,80,80', C'210,180,70', C'220,140,60',
           C'70,200,130', C'36,36,40', C'200,200,210');
     }

   void ApplyDarkBlue(void)
     {
      Fill(C'10,16,28', C'16,28,48', C'14,22,38', C'70,130,190',
           C'230,238,250', C'255,255,255', C'120,140,170', C'90,170,220',
           C'50,200,140', C'220,80,90', C'220,190,70', C'230,150,60',
           C'50,200,140', C'18,28,48', C'110,190,240');
     }

   void ApplyMidnight(void)
     {
      Fill(C'4,4,6', C'10,10,14', C'8,8,12', C'80,80,90',
           C'220,220,230', C'245,245,250', C'110,110,120', C'160,160,175',
           C'40,180,100', C'200,60,60', C'200,170,50', C'210,130,40',
           C'40,180,100', C'12,12,16', C'180,180,200');
     }

   void ApplyLight(void)
     {
      Fill(C'245,246,248', C'232,234,240', C'255,255,255', C'160,168,180',
           C'30,34,42', C'16,18,24', C'100,108,120', C'160,120,40',
           C'20,140,80', C'180,40,40', C'170,130,20', C'190,110,30',
           C'20,140,80', C'250,250,252', C'180,140,50');
     }

   void ApplyCustom(void)
     {
      Fill(m_custom.bg, m_custom.header, m_custom.widget, m_custom.border,
           m_custom.text, m_custom.text, C'140,140,148', m_custom.highlight,
           m_custom.profit, m_custom.loss, m_custom.warn, C'230,140,50',
           m_custom.success, m_custom.widget, m_custom.highlight);
     }

public:
                     CGmDashboardTheme(void) : m_theme(GM_DASH_THEME_GOLD)
     {
      m_custom.Defaults();
      ApplyBlackGold();
     }

   void SetCustomColors(const SGmCustomColors &c)
     {
      m_custom = c;
      m_custom.used = true;
      if(m_theme == GM_DASH_THEME_CUSTOM)
         ApplyCustom();
     }

   SGmCustomColors CustomColors(void) const { return m_custom; }

   void SetTheme(const ENUM_GM_DASH_THEME theme)
     {
      m_theme = theme;
      switch(theme)
        {
         case GM_DASH_THEME_DARK:     ApplyDarkGray(); break;
         case GM_DASH_THEME_FUTURE:   ApplyDarkBlue(); break;
         case GM_DASH_THEME_MIDNIGHT: ApplyMidnight(); break;
         case GM_DASH_THEME_LIGHT:    ApplyLight(); break;
         case GM_DASH_THEME_CUSTOM:   ApplyCustom(); break;
         default:                     ApplyBlackGold(); break;
        }
     }

   ENUM_GM_DASH_THEME Theme(void) const { return m_theme; }
   SGmDashPalette Palette(void) const { return m_pal; }

   string ThemeName(void) const
     {
      switch(m_theme)
        {
         case GM_DASH_THEME_DARK:     return "Dark Gray";
         case GM_DASH_THEME_FUTURE:   return "Dark Blue";
         case GM_DASH_THEME_MIDNIGHT: return "Midnight Black";
         case GM_DASH_THEME_LIGHT:    return "Light Theme";
         case GM_DASH_THEME_CUSTOM:   return "Custom Theme";
         default:                     return "Professional Black Gold";
        }
     }

   ENUM_GM_DASH_THEME CycleNext(void)
     {
      int t = (int)m_theme + 1;
      if(t > (int)GM_DASH_THEME_CUSTOM)
         t = 0;
      SetTheme((ENUM_GM_DASH_THEME)t);
      return m_theme;
     }

   color StatusColor(const string status) const
     {
      string s = status;
      StringToUpper(s);
      if(StringFind(s, "ERROR") >= 0 || StringFind(s, "DISCONNECT") >= 0 ||
         StringFind(s, "LOSS") >= 0 || StringFind(s, "FAIL") >= 0)
         return m_pal.loss;
      if(StringFind(s, "PAUSE") >= 0 || StringFind(s, "INACTIVE") >= 0)
         return m_pal.paused;
      if(StringFind(s, "WARN") >= 0 || StringFind(s, "WAIT") >= 0 ||
         StringFind(s, "PENDING") >= 0)
         return m_pal.warn;
      if(StringFind(s, "RUN") >= 0 || StringFind(s, "HEALTH") >= 0 ||
         StringFind(s, "CONNECT") >= 0 || StringFind(s, "PROFIT") >= 0 ||
         StringFind(s, "OK") >= 0 || StringFind(s, "ON") >= 0 ||
         StringFind(s, "ACTIVE") >= 0 || StringFind(s, "ALLOWED") >= 0 ||
         StringFind(s, "OPEN") >= 0 || StringFind(s, "WIN") >= 0 ||
         StringFind(s, "READY") >= 0)
         return m_pal.success;
      return m_pal.muted;
     }

   color SignedColor(const double v) const
     {
      if(v > 0.0)
         return m_pal.profit;
      if(v < 0.0)
         return m_pal.loss;
      return m_pal.muted;
     }
  };

#endif // GM_CDASHBOARD_THEME_MQH
//+------------------------------------------------------------------+
