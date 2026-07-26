//+------------------------------------------------------------------+
//|                                            CLayoutManager.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CLAYOUT_MANAGER_MQH
#define GM_CLAYOUT_MANAGER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "UIConstants.mqh"
#include "../Dashboard/SGmDashboardSettings.mqh"
#include "../Dashboard/DashboardConstants.mqh"
#include "../Logging/CLogger.mqh"

/// @file CLayoutManager.mqh
/// @brief Save/restore panel layout — move/resize/lock (UI only).

class CGmLayoutManager
  {
private:
   CGmLogger *m_logger;

public:
                     CGmLayoutManager(void) : m_logger(NULL) {}

   void Init(CGmLogger *logger) { m_logger = logger; }

   void SaveLayout(const SGmDashboardSettings &s)
     {
      GlobalVariableSet(GM_DASH_POS_GV_X, (double)s.panel_x);
      GlobalVariableSet(GM_DASH_POS_GV_Y, (double)s.panel_y);
      GlobalVariableSet(GM_UI_LAYOUT_GV_PREFIX + "W", (double)s.panel_width);
      GlobalVariableSet(GM_UI_LAYOUT_GV_PREFIX + "H", (double)s.panel_height);
      GlobalVariableSet(GM_UI_LAYOUT_GV_PREFIX + "LOCK", s.lock_position ? 1.0 : 0.0);
      if(m_logger != NULL)
         m_logger.Info(StringFormat("Layout Saved | x=%d y=%d w=%d",
                                    s.panel_x, s.panel_y, s.panel_width),
                       "LayoutManager");
     }

   void LoadLayout(SGmDashboardSettings &s)
     {
      if(GlobalVariableCheck(GM_DASH_POS_GV_X))
         s.panel_x = (int)GlobalVariableGet(GM_DASH_POS_GV_X);
      if(GlobalVariableCheck(GM_DASH_POS_GV_Y))
         s.panel_y = (int)GlobalVariableGet(GM_DASH_POS_GV_Y);
      if(GlobalVariableCheck(GM_UI_LAYOUT_GV_PREFIX + "W"))
         s.panel_width = (int)GlobalVariableGet(GM_UI_LAYOUT_GV_PREFIX + "W");
      if(GlobalVariableCheck(GM_UI_LAYOUT_GV_PREFIX + "H"))
         s.panel_height = (int)GlobalVariableGet(GM_UI_LAYOUT_GV_PREFIX + "H");
      if(GlobalVariableCheck(GM_UI_LAYOUT_GV_PREFIX + "LOCK"))
         s.lock_position = (GlobalVariableGet(GM_UI_LAYOUT_GV_PREFIX + "LOCK") > 0.5);
      s.Clamp();
     }

   void RestoreDefault(SGmDashboardSettings &s)
     {
      s.panel_x = GM_DASH_DEFAULT_X;
      s.panel_y = GM_DASH_DEFAULT_Y;
      s.panel_width = GM_DASH_DEFAULT_WIDTH;
      s.panel_height = GM_DASH_DEFAULT_HEIGHT;
      s.lock_position = false;
      if(GlobalVariableCheck(GM_DASH_POS_GV_X))
         GlobalVariableDel(GM_DASH_POS_GV_X);
      if(GlobalVariableCheck(GM_DASH_POS_GV_Y))
         GlobalVariableDel(GM_DASH_POS_GV_Y);
      if(GlobalVariableCheck(GM_UI_LAYOUT_GV_PREFIX + "W"))
         GlobalVariableDel(GM_UI_LAYOUT_GV_PREFIX + "W");
      if(GlobalVariableCheck(GM_UI_LAYOUT_GV_PREFIX + "H"))
         GlobalVariableDel(GM_UI_LAYOUT_GV_PREFIX + "H");
      if(GlobalVariableCheck(GM_UI_LAYOUT_GV_PREFIX + "LOCK"))
         GlobalVariableDel(GM_UI_LAYOUT_GV_PREFIX + "LOCK");
      if(m_logger != NULL)
         m_logger.Info("Layout restored to default", "LayoutManager");
     }

   void ToggleLock(SGmDashboardSettings &s)
     {
      s.lock_position = !s.lock_position;
      SaveLayout(s);
      if(m_logger != NULL)
         m_logger.Info(s.lock_position ? "Panel Locked" : "Panel Unlocked", "LayoutManager");
     }
  };

#endif // GM_CLAYOUT_MANAGER_MQH
//+------------------------------------------------------------------+
