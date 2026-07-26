//+------------------------------------------------------------------+
//|                                             CConfiguration.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CCONFIGURATION_MQH
#define GM_CCONFIGURATION_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "../Core/Version.mqh"
#include "../Core/Defines.mqh"
#include "../Core/TradingRules.mqh"
#include "../Risk/RiskConstants.mqh"
#include "../Protection/SGmProtectionSettings.mqh"
#include "../Session/SGmSessionLogSettings.mqh"
#include "../Validation/SGmValidationSettings.mqh"
#include "../Production/SGmProductionSettings.mqh"
#include "../Dashboard/SGmDashboardSettings.mqh"
#include "../AI/Core/SGmAICoreSettings.mqh"
#include "../Logging/EnumsLogging.mqh"

/// @file CConfiguration.mqh
/// @brief Centralized configuration — Phase 2 Sprint 1 Dashboard settings.

class CGmConfiguration
  {
private:
   bool                 m_initialized;
   string               m_symbol;
   ENUM_TIMEFRAMES      m_chart_timeframe;
   ENUM_TIMEFRAMES      m_strategy_timeframe;
   long                 m_magic_number;
   string               m_ea_comment;

   double               m_risk_fraction;
   double               m_sl_pips;
   int                  m_atr_period;
   double               m_atr_tp_mult;
   int                  m_max_spread_points;

   bool                 m_enable_capital_protection;
   double               m_max_drawdown_warn_pct;
   double               m_max_daily_loss_warn_pct;
   bool                 m_enable_detailed_logs;

   bool                 m_enable_session_logs;
   bool                 m_enable_performance_logs;
   bool                 m_enable_audit_logs;
   bool                 m_enable_recovery_logs;
   int                  m_max_log_size_kb;
   bool                 m_automatic_archive;

   bool                 m_enable_validation;
   bool                 m_enable_backtest_metrics;
   bool                 m_enable_stress_tests;
   bool                 m_run_validation_on_startup;

   ENUM_GM_RUNTIME_MODE m_runtime_mode;
   bool                 m_recovery_mode;
   bool                 m_performance_mode;
   bool                 m_enable_fail_safe;
   bool                 m_enable_security_guard;
   bool                 m_enable_live_validation;
   bool                 m_enterprise_logging;

   SGmDashboardSettings m_dashboard;
   SGmAICoreSettings    m_ai_core;

   ENUM_GM_LOG_LEVEL    m_log_level;
   ENUM_GM_LOG_DESTINATION m_log_destination;
   bool                 m_log_to_file;

   bool                 m_enable_timer;
   int                  m_timer_interval_ms;
   bool                 m_strict_symbol_check;

public:
                     CGmConfiguration(void)
                       : m_initialized(false),
                         m_symbol(""),
                         m_chart_timeframe(PERIOD_CURRENT),
                         m_strategy_timeframe(GM_POLICY_STRATEGY_TIMEFRAME),
                         m_magic_number(GM_MAGIC_DEFAULT),
                         m_ea_comment(GM_PRODUCT_SHORT),
                         m_risk_fraction(GM_RISK_EQUITY_FRACTION),
                         m_sl_pips(GM_FIXED_SL_PIPS),
                         m_atr_period(GM_ATR_PERIOD),
                         m_atr_tp_mult(GM_ATR_TP_MULTIPLIER),
                         m_max_spread_points(GM_PROT_MAX_SPREAD_POINTS_DEFAULT),
                         m_enable_capital_protection(GM_PROT_ENABLE_DEFAULT),
                         m_max_drawdown_warn_pct(GM_PROT_MAX_DD_WARN_PCT_DEFAULT),
                         m_max_daily_loss_warn_pct(GM_PROT_MAX_DAILY_LOSS_WARN_DEFAULT),
                         m_enable_detailed_logs(GM_PROT_DETAILED_LOGS_DEFAULT),
                         m_enable_session_logs(GM_SESSION_ENABLE_LOGS_DEFAULT),
                         m_enable_performance_logs(GM_SESSION_ENABLE_PERF_DEFAULT),
                         m_enable_audit_logs(GM_SESSION_ENABLE_AUDIT_DEFAULT),
                         m_enable_recovery_logs(GM_SESSION_ENABLE_RECOVERY_DEFAULT),
                         m_max_log_size_kb(GM_SESSION_LOG_SIZE_DEFAULT_KB),
                         m_automatic_archive(GM_SESSION_AUTO_ARCHIVE_DEFAULT),
                         m_enable_validation(GM_VAL_ENABLE_DEFAULT),
                         m_enable_backtest_metrics(GM_VAL_BACKTEST_DEFAULT),
                         m_enable_stress_tests(GM_VAL_STRESS_DEFAULT),
                         m_run_validation_on_startup(true),
                         m_runtime_mode(GM_MODE_PRODUCTION),
                         m_recovery_mode(true),
                         m_performance_mode(true),
                         m_enable_fail_safe(true),
                         m_enable_security_guard(true),
                         m_enable_live_validation(true),
                         m_enterprise_logging(true),
                         m_log_level(GM_LOG_INFO),
                         m_log_destination(GM_LOG_DEST_TERMINAL),
                         m_log_to_file(false),
                         m_enable_timer(true),
                         m_timer_interval_ms(GM_TIMER_INTERVAL_DEFAULT_MS),
                         m_strict_symbol_check(true)
     {
      m_dashboard.Defaults();
      m_ai_core.Defaults();
     }

                    ~CGmConfiguration(void) {}

   bool Init(const string symbol,
             const ENUM_TIMEFRAMES timeframe,
             const long magic_number,
             const ENUM_GM_LOG_LEVEL log_level,
             const bool log_to_file,
             const bool enable_timer,
             const int timer_interval_ms,
             const SGmProtectionSettings &protection,
             const SGmSessionLogSettings &session_logs,
             const SGmValidationSettings &validation,
             const SGmProductionSettings &production,
             const SGmDashboardSettings &dashboard,
             const SGmAICoreSettings &ai_core)
     {
      m_symbol = (StringLen(symbol) > 0) ? symbol : _Symbol;
      m_chart_timeframe = (timeframe == PERIOD_CURRENT) ? (ENUM_TIMEFRAMES)_Period : timeframe;
      m_strategy_timeframe = GM_POLICY_STRATEGY_TIMEFRAME;
      m_magic_number = magic_number;
      if(m_magic_number == GM_MAGIC_MANUAL_TRADE)
         return false;

      m_risk_fraction = GM_RISK_EQUITY_FRACTION;
      m_sl_pips = GM_FIXED_SL_PIPS;
      m_atr_period = GM_ATR_PERIOD;
      m_atr_tp_mult = GM_ATR_TP_MULTIPLIER;

      m_enable_capital_protection = protection.enable_capital_protection;
      m_max_spread_points = (protection.max_spread_points > 0)
                            ? protection.max_spread_points
                            : GM_PROT_MAX_SPREAD_POINTS_DEFAULT;
      m_max_drawdown_warn_pct = (protection.max_drawdown_warn_pct > 0.0)
                                ? protection.max_drawdown_warn_pct
                                : GM_PROT_MAX_DD_WARN_PCT_DEFAULT;
      m_max_daily_loss_warn_pct = (protection.max_daily_loss_warn_pct > 0.0)
                                  ? protection.max_daily_loss_warn_pct
                                  : GM_PROT_MAX_DAILY_LOSS_WARN_DEFAULT;
      m_enable_detailed_logs = protection.enable_detailed_logs;

      m_enable_session_logs = session_logs.enable_session_logs;
      m_enable_performance_logs = session_logs.enable_performance_logs;
      m_enable_audit_logs = session_logs.enable_audit_logs;
      m_enable_recovery_logs = session_logs.enable_recovery_logs;
      m_max_log_size_kb = (session_logs.max_log_size_kb > 0)
                         ? session_logs.max_log_size_kb
                         : GM_SESSION_LOG_SIZE_DEFAULT_KB;
      m_automatic_archive = session_logs.automatic_archive;

      m_enable_validation = validation.enable_validation;
      m_enable_backtest_metrics = validation.enable_backtest_metrics;
      m_enable_stress_tests = validation.enable_stress_tests;
      m_run_validation_on_startup = validation.run_on_startup;

      m_runtime_mode = production.runtime_mode;
      m_recovery_mode = production.recovery_mode;
      m_performance_mode = production.performance_mode;
      m_enable_fail_safe = production.enable_fail_safe;
      m_enable_security_guard = production.enable_security_guard;
      m_enable_live_validation = production.enable_live_validation;
      m_enterprise_logging = production.enterprise_logging;
      // Production mode forces INFO+ unless Debug/Dev
      if(production.IsProduction())
         m_log_level = (log_level < GM_LOG_INFO) ? GM_LOG_INFO : log_level;
      else
         m_log_level = production.logging_level != GM_LOG_INFO
                       ? production.logging_level
                       : log_level;

      m_log_to_file = log_to_file;
      m_log_destination = log_to_file ? GM_LOG_DEST_BOTH : GM_LOG_DEST_TERMINAL;
      m_enable_timer = enable_timer;
      m_timer_interval_ms = (timer_interval_ms > 0) ? timer_interval_ms : GM_TIMER_INTERVAL_DEFAULT_MS;

      m_dashboard = dashboard;
      m_dashboard.Clamp();
      m_ai_core = ai_core;
      m_ai_core.Clamp();

      if(m_strict_symbol_check && StringLen(m_symbol) == 0)
         return false;

      m_initialized = true;
      return true;
     }

   bool IsInitialized(void) const { return m_initialized; }

   string            Symbol(void) const              { return m_symbol; }
   ENUM_TIMEFRAMES   Timeframe(void) const           { return m_chart_timeframe; }
   ENUM_TIMEFRAMES   StrategyTimeframe(void) const   { return m_strategy_timeframe; }
   long              MagicNumber(void) const         { return m_magic_number; }
   string            EaComment(void) const           { return m_ea_comment; }

   double            RiskFraction(void) const        { return m_risk_fraction; }
   double            StopLossPips(void) const        { return m_sl_pips; }
   int               AtrPeriod(void) const           { return m_atr_period; }
   double            AtrTpMultiplier(void) const     { return m_atr_tp_mult; }
   int               MaxSpreadPoints(void) const     { return m_max_spread_points; }

   bool              EnableCapitalProtection(void) const { return m_enable_capital_protection; }
   double            MaxDrawdownWarnPct(void) const  { return m_max_drawdown_warn_pct; }
   double            MaxDailyLossWarnPct(void) const { return m_max_daily_loss_warn_pct; }
   bool              EnableDetailedLogs(void) const  { return m_enable_detailed_logs; }

   SGmProtectionSettings ProtectionSettings(void) const
     {
      SGmProtectionSettings s;
      s.enable_capital_protection = m_enable_capital_protection;
      s.max_spread_points = m_max_spread_points;
      s.max_drawdown_warn_pct = m_max_drawdown_warn_pct;
      s.max_daily_loss_warn_pct = m_max_daily_loss_warn_pct;
      s.enable_detailed_logs = m_enable_detailed_logs;
      return s;
     }

   SGmSessionLogSettings SessionLogSettings(void) const
     {
      SGmSessionLogSettings s;
      s.enable_session_logs = m_enable_session_logs;
      s.enable_performance_logs = m_enable_performance_logs;
      s.enable_audit_logs = m_enable_audit_logs;
      s.enable_recovery_logs = m_enable_recovery_logs;
      s.max_log_size_kb = m_max_log_size_kb;
      s.automatic_archive = m_automatic_archive;
      return s;
     }

   SGmValidationSettings ValidationSettings(void) const
     {
      SGmValidationSettings s;
      s.enable_validation = m_enable_validation;
      s.enable_backtest_metrics = m_enable_backtest_metrics;
      s.enable_stress_tests = m_enable_stress_tests;
      s.run_on_startup = m_run_validation_on_startup;
      return s;
     }

   SGmProductionSettings ProductionSettings(void) const
     {
      SGmProductionSettings s;
      s.runtime_mode = m_runtime_mode;
      s.logging_level = m_log_level;
      s.recovery_mode = m_recovery_mode;
      s.performance_mode = m_performance_mode;
      s.enable_fail_safe = m_enable_fail_safe;
      s.enable_security_guard = m_enable_security_guard;
      s.enable_live_validation = m_enable_live_validation;
      s.enterprise_logging = m_enterprise_logging;
      return s;
     }

   SGmDashboardSettings DashboardSettings(void) const { return m_dashboard; }
   bool EnableDashboard(void) const { return m_dashboard.enable_dashboard; }

   SGmAICoreSettings AICoreSettings(void) const { return m_ai_core; }
   bool EnableAICore(void) const { return m_ai_core.enable_ai; }

   bool RunValidationOnStartup(void) const { return m_run_validation_on_startup; }

   ENUM_GM_LOG_LEVEL LogLevel(void) const            { return m_log_level; }
   ENUM_GM_LOG_DESTINATION LogDestination(void) const { return m_log_destination; }
   bool              LogToFile(void) const           { return m_log_to_file; }
   bool              EnableTimer(void) const         { return m_enable_timer; }
   int               TimerIntervalMs(void) const     { return m_timer_interval_ms; }

   string Summary(void) const
     {
      return StringFormat("Symbol=%s | Magic=%I64d | Prot=%s | Dash=%s | AICore=%s",
                          m_symbol, m_magic_number,
                          m_enable_capital_protection ? "ON" : "OFF",
                          m_dashboard.enable_dashboard ? "ON" : "OFF",
                          m_ai_core.enable_ai ? "ON" : "OFF");
     }
  };

#endif // GM_CCONFIGURATION_MQH
//+------------------------------------------------------------------+
