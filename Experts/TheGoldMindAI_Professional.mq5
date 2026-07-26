//+------------------------------------------------------------------+
//|                            TheGoldMindAI_Professional.mq5        |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#property copyright   "Copyright 2026, RTAS Group of Companies"
#property link        "https://rtas.group"
#property version     "2.00"
#property description "THE GOLD MIND AI – Proprietary EA | RTAS Group of Companies"
#property description "Division: RTAS Digital Marketing Company"
#property description "Phase 7 Sprint 10: Enterprise Trading Ecosystem Certification, Hardening & Phase 7 Closure — PHASE 7 COMPLETE"
#property description "Manages ONLY its own Magic Number trades."

#include "../Include/Core/Version.mqh"
#include "../Include/Protection/SGmProtectionSettings.mqh"
#include "../Include/Session/SGmSessionLogSettings.mqh"
#include "../Include/Validation/SGmValidationSettings.mqh"
#include "../Include/Production/SGmProductionSettings.mqh"
#include "../Include/Dashboard/SGmDashboardSettings.mqh"
#include "../Include/AI/Core/SGmAICoreSettings.mqh"
#include "../Include/Core/CApplication.mqh"

input group "=== Identity / Ownership ==="
input long               InpMagicNumber      = 112233;         // Magic Number (unique to this EA)
input string             InpSymbolOverride   = "";             // Symbol Override (empty = chart)

input group "=== Dashboard (Phase 2) ==="
input bool               InpEnableDashboard  = true;           // Enable Dashboard
input ENUM_GM_DASH_THEME InpDashTheme        = GM_DASH_THEME_GOLD; // Dashboard Theme
input int                InpDashRefreshMs    = 500;            // Dashboard Refresh (ms)
input int                InpDashX            = 8;              // Panel X (LEFT)
input int                InpDashY            = 18;             // Panel Y
input int                InpDashWidth        = 392;            // Panel Width
input int                InpDashHeight       = 720;            // Panel Height
input int                InpDashFontSize     = 8;              // Font Size
input int                InpDashTransparency = 15;             // Transparency (0-100)
input bool               InpDashLockPosition = false;          // Lock Panel Position
input string             InpDashLanguage     = "en";           // Language Code

input group "=== AI Core (Phase 3) ==="
input bool               InpEnableAICore     = true;           // Enable AI Core
input ENUM_GM_AI_CORE_MODE InpAICoreMode     = GM_AI_CORE_MODE_ANALYSIS_ONLY; // AI Mode
input bool               InpAISafeMode       = false;          // Safe Mode
input bool               InpAILearningMode   = false;          // Learning Mode
input bool               InpAISimulationMode = false;          // Simulation Mode
input int                InpAIProcessMs      = 500;            // AI Process Throttle (ms)

input group "=== Production / RC-1 ==="
input ENUM_GM_RUNTIME_MODE InpRuntimeMode    = GM_MODE_PRODUCTION; // Runtime Mode
input bool               InpRecoveryMode     = true;           // Recovery Mode
input bool               InpPerformanceMode  = true;           // Performance Mode
input bool               InpEnableFailSafe   = true;           // Enable Fail Safe
input bool               InpEnableSecurityGuard = true;        // Enable Security Guard
input bool               InpEnableLiveValidation = true;       // Enable Live Execution Validation
input bool               InpEnterpriseLogging = true;          // Enterprise Logging

input group "=== Capital Protection ==="
input bool               InpEnableCapitalProtection = true;    // Enable Capital Protection
input int                InpMaxSpreadPoints  = 500;            // Maximum Spread (points)
input double             InpMaxDrawdownWarn  = 10.0;           // Maximum Drawdown Warning (%)
input double             InpMaxDailyLossWarn = 5.0;            // Maximum Daily Loss Warning (%)
input bool               InpEnableDetailedLogs = false;        // Enable Detailed Logs

input group "=== H4 Session / Audit ==="
input bool               InpEnableSessionLogs = true;          // Enable Session Logs
input bool               InpEnablePerformanceLogs = true;      // Enable Performance Logs
input bool               InpEnableAuditLogs = true;            // Enable Audit Logs
input bool               InpEnableRecoveryLogs = true;         // Enable Recovery Logs
input int                InpMaxLogSizeKb = 2048;               // Maximum Log Size (KB)
input bool               InpAutomaticArchive = true;           // Automatic Archive

input group "=== Validation / Backtest ==="
input bool               InpEnableValidation = true;           // Enable Validation Framework
input bool               InpEnableBacktestMetrics = true;      // Enable Backtest Metrics
input bool               InpEnableStressTests = true;          // Enable Stress Tests
input bool               InpRunValidationOnStartup = true;     // Run Validation On Startup

input group "=== Logging ==="
input ENUM_GM_LOG_LEVEL  InpLogLevel         = GM_LOG_INFO;    // Minimum Log Level
input bool               InpLogToFile        = false;          // Write Logs To File

input group "=== Runtime ==="
input bool               InpEnableTimer      = true;           // Enable Timer Heartbeat
input int                InpTimerIntervalMs  = 1000;           // Timer Interval (ms)

CGmApplication g_app;

int OnInit()
  {
   SGmProtectionSettings prot;
   prot.enable_capital_protection = InpEnableCapitalProtection;
   prot.max_spread_points         = InpMaxSpreadPoints;
   prot.max_drawdown_warn_pct     = InpMaxDrawdownWarn;
   prot.max_daily_loss_warn_pct   = InpMaxDailyLossWarn;
   prot.enable_detailed_logs      = InpEnableDetailedLogs;

   SGmSessionLogSettings slog;
   slog.enable_session_logs      = InpEnableSessionLogs;
   slog.enable_performance_logs  = InpEnablePerformanceLogs;
   slog.enable_audit_logs        = InpEnableAuditLogs;
   slog.enable_recovery_logs     = InpEnableRecoveryLogs;
   slog.max_log_size_kb          = InpMaxLogSizeKb;
   slog.automatic_archive        = InpAutomaticArchive;

   SGmValidationSettings vset;
   vset.enable_validation        = InpEnableValidation;
   vset.enable_backtest_metrics  = InpEnableBacktestMetrics;
   vset.enable_stress_tests      = InpEnableStressTests;
   vset.run_on_startup           = InpRunValidationOnStartup;

   SGmProductionSettings pset;
   pset.runtime_mode             = InpRuntimeMode;
   pset.logging_level            = InpLogLevel;
   pset.recovery_mode            = InpRecoveryMode;
   pset.performance_mode         = InpPerformanceMode;
   pset.enable_fail_safe         = InpEnableFailSafe;
   pset.enable_security_guard    = InpEnableSecurityGuard;
   pset.enable_live_validation   = InpEnableLiveValidation;
   pset.enterprise_logging       = InpEnterpriseLogging;

   SGmDashboardSettings dash;
   dash.Defaults();
   dash.enable_dashboard = InpEnableDashboard;
   dash.theme            = InpDashTheme;
   dash.refresh_ms       = InpDashRefreshMs;
   dash.panel_x          = InpDashX;
   dash.panel_y          = InpDashY;
   dash.panel_width      = InpDashWidth;
   dash.panel_height     = InpDashHeight;
   dash.font_size        = InpDashFontSize;
   dash.transparency     = InpDashTransparency;
   dash.language_code    = InpDashLanguage;
   dash.auto_refresh     = true;
   dash.lock_position    = InpDashLockPosition;
   dash.Clamp();

   SGmAICoreSettings ai;
   ai.Defaults();
   ai.enable_ai = InpEnableAICore;
   ai.mode = InpAICoreMode;
   ai.safe_mode = InpAISafeMode;
   ai.learning_mode = InpAILearningMode;
   ai.simulation_mode = InpAISimulationMode;
   ai.analysis_only = true;
   ai.future_live_blocked = true;
   ai.process_throttle_ms = InpAIProcessMs;
   ai.Clamp();

   return g_app.Init(InpSymbolOverride,
                     PERIOD_CURRENT,
                     InpMagicNumber,
                     InpLogLevel,
                     InpLogToFile,
                     InpEnableTimer,
                     InpTimerIntervalMs,
                     prot,
                     slog,
                     vset,
                     pset,
                     dash,
                     ai);
  }

void OnDeinit(const int reason)
  {
   g_app.Deinit(reason);
  }

void OnTick()
  {
   g_app.OnTick();
  }

void OnTimer()
  {
   g_app.OnTimer();
  }

void OnTrade()
  {
   g_app.OnTrade();
  }

void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
  {
   g_app.OnTradeTransaction(trans, request, result);
  }

void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {
   g_app.OnChartEvent(id, lparam, dparam, sparam);
  }
//+------------------------------------------------------------------+
