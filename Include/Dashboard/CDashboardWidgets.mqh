//+------------------------------------------------------------------+
//|                                       CDashboardWidgets.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CDASHBOARD_WIDGETS_MQH
#define GM_CDASHBOARD_WIDGETS_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "DashboardConstants.mqh"
#include "CDashboardTheme.mqh"

/// @file CDashboardWidgets.mqh
/// @brief Reusable chart-object widgets with flicker-free text updates.

class CGmDashboardWidgets
  {
private:
   string m_prefix;
   CGmDashboardTheme *m_theme;

   string N(const string key) const { return m_prefix + key; }

public:
                     CGmDashboardWidgets(void) : m_prefix(GM_DASH_OBJ_PREFIX), m_theme(NULL) {}

   void Init(CGmDashboardTheme *theme, const string prefix = GM_DASH_OBJ_PREFIX)
     {
      m_theme = theme;
      m_prefix = prefix;
     }

   void DestroyAll(void)
     {
      ObjectsDeleteAll(0, m_prefix);
     }

   void Rect(const string key, const int x, const int y, const int w, const int h,
             const color bg, const color border)
     {
      const string name = N(key);
      if(ObjectFind(0, name) < 0)
        {
         ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
         ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
         ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
         ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
         ObjectSetInteger(0, name, OBJPROP_BACK, false);
         ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
         ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
         ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
         ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
         ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
         ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
         ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bg);
         ObjectSetInteger(0, name, OBJPROP_COLOR, border);
         ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, border);
         return;
        }
      // Skip unchanged geometry / colors — fewer redraw ops under stress
      if((int)ObjectGetInteger(0, name, OBJPROP_XDISTANCE) != x)
         ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
      if((int)ObjectGetInteger(0, name, OBJPROP_YDISTANCE) != y)
         ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
      if((int)ObjectGetInteger(0, name, OBJPROP_XSIZE) != w)
         ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
      if((int)ObjectGetInteger(0, name, OBJPROP_YSIZE) != h)
         ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
      if((color)ObjectGetInteger(0, name, OBJPROP_BGCOLOR) != bg)
         ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bg);
      if((color)ObjectGetInteger(0, name, OBJPROP_BORDER_COLOR) != border)
        {
         ObjectSetInteger(0, name, OBJPROP_COLOR, border);
         ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, border);
        }
     }

   void Label(const string key, const int x, const int y, const string text,
              const color clr, const int font_sz, const string font = "Segoe UI")
     {
      const string name = N(key);
      if(ObjectFind(0, name) < 0)
        {
         ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
         ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
         ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
         ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
         ObjectSetString(0, name, OBJPROP_FONT, font);
         ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
         ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
         ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
         ObjectSetInteger(0, name, OBJPROP_FONTSIZE, font_sz);
         ObjectSetString(0, name, OBJPROP_TEXT, text);
         return;
        }
      if((int)ObjectGetInteger(0, name, OBJPROP_XDISTANCE) != x)
         ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
      if((int)ObjectGetInteger(0, name, OBJPROP_YDISTANCE) != y)
         ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
      if((color)ObjectGetInteger(0, name, OBJPROP_COLOR) != clr)
         ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
      if((int)ObjectGetInteger(0, name, OBJPROP_FONTSIZE) != font_sz)
         ObjectSetInteger(0, name, OBJPROP_FONTSIZE, font_sz);
      if(ObjectGetString(0, name, OBJPROP_TEXT) != text)
         ObjectSetString(0, name, OBJPROP_TEXT, text);
     }

   /// @brief Value-only update (position already set) — zero flicker path.
   void SetText(const string key, const string text, const color clr)
     {
      const string name = N(key);
      if(ObjectFind(0, name) < 0)
         return;
      ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
      if(ObjectGetString(0, name, OBJPROP_TEXT) != text)
         ObjectSetString(0, name, OBJPROP_TEXT, text);
     }

   void Row(const string key, const int x, const int y, const int w,
            const string label, const string value, const color vclr,
            const int font_sz, const color label_clr)
     {
      Label(key + "_L", x, y, label, label_clr, font_sz);
      Label(key + "_V", x + w / 2, y, value, vclr, font_sz);
     }

   void SectionTitle(const string key, const int x, const int y, const int w,
                     const string icon, const string title, const int font_sz,
                     const color accent, const color bg, const color border)
     {
      Rect(key + "_BG", x, y, w, GM_DASH_SECTION_TITLE_H, bg, border);
      Label(key + "_T", x + 6, y + 2, icon + "  " + title, accent, font_sz);
     }
  };

#endif // GM_CDASHBOARD_WIDGETS_MQH
//+------------------------------------------------------------------+
