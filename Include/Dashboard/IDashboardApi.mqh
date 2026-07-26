//+------------------------------------------------------------------+
//|                                          IDashboardApi.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_IDASHBOARD_API_MQH
#define GM_IDASHBOARD_API_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmDashboardSnapshot.mqh"
#include "EnumsDashboard.mqh"

/// @file IDashboardApi.mqh
/// @brief Clean API for Trading/Risk/Analytics/AI/Cloud/Mobile/Web consumers.
/// @warning Implementations are READ-ONLY monitors. No trade mutations.

interface IGmDashboardApi
  {
   bool IsVisible(void);
   bool Show(void);
   bool Hide(void);
   bool RefreshNow(void);
   bool GetSnapshot(SGmDashboardSnapshot &out);
   void PublishEvent(const ENUM_GM_DASH_EVENT type, const string message);
  };

/// Future external consumers (contracts only — Sprint 1 stubs).
interface IGmDashboardTradingView
  {
   bool BindReadOnly(void);
  };

interface IGmDashboardRiskView
  {
   bool BindReadOnly(void);
  };

interface IGmDashboardAnalyticsView
  {
   bool BindReadOnly(void);
  };

interface IGmDashboardAIView
  {
   bool BindReadOnly(void);
  };

interface IGmDashboardCloudView
  {
   bool BindReadOnly(void);
  };

interface IGmDashboardMobileView
  {
   bool BindReadOnly(void);
  };

interface IGmDashboardWebView
  {
   bool BindReadOnly(void);
  };

#endif // GM_IDASHBOARD_API_MQH
//+------------------------------------------------------------------+
