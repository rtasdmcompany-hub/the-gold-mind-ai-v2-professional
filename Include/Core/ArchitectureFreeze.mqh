//+------------------------------------------------------------------+
//|                                        ArchitectureFreeze.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_ARCHITECTURE_FREEZE_MQH
#define GM_ARCHITECTURE_FREEZE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "Version.mqh"

/// @file ArchitectureFreeze.mqh
/// @brief Phase 1 Core + Phase 2 Dashboard + Phase 3 AI Architecture FROZEN.
///
/// FROZEN MODULES (extend only via new layered modules — never edit math):
///   - Calculation Engine   (Include/Calculation/*)
///   - Trade Engine         (Include/Trading/CPendingOrderEngine, CTradeManager, …)
///   - Lifecycle Engine     (Include/Lifecycle/*)
///   - Risk Engine          (Include/Risk/*)
///   - Session Engine       (Include/Session/*)
///   - Recovery Core Paths  (registry / level DB / session recovery)
///
/// FROZEN PHASE 2 FOUNDATION (do not rewrite — extend via APIs only):
///   - Dashboard Engine / Renderer / Widgets / Theme / Settings / Refresh
///   - Analytics Engine (read-only observation)
///   - Journal / Alert / Reporting surfaces
///   - AI Dashboard Foundation
///   - Multi-Instance monitoring layer
///
/// FROZEN PHASE 3 AI INTELLIGENCE (extend via modular APIs only):
///   - AI Core / Manager / Controller / Data Bus / State / Config
///   - Market / Trend / Volatility / News
///   - Confidence / Learning / Decision+XAI / AIValidation
///   - Future Autonomy interfaces remain INACTIVE until Phase 4+ approval
///
/// FROZEN PHASE 6 ENTERPRISE INFRASTRUCTURE (extend via modular APIs only):
///   - Cloud Core / Device Identity / Sync / Offline
///   - Remote Monitor / Telemetry / Health
///   - Notification Center / Mobile Companion API
///   - VPS / Multi-Terminal / Control Center
///   - Identity / License / Auth / Activation
///   - Backup / DR / Business Continuity
///   - Audit / Compliance / Forensic
///   - API Gateway / Integration Hub
///   - Deployment / Auto-Update / Release Management
///
/// RULES:
///   1. Never change H4 level fractions, SL pips, ATR TP, BE/Partial/Trail constants.
///   2. Never manage Magic 0 / manual trades / foreign Magics.
///   3. Phase 4+ must enhance, not replace, Core / Dashboard / AI foundations.
///   4. New features = new modules that call existing APIs — do not fork foundations.
///   5. AI remains ADVISORY — never open/close/modify trades or risk.
///   6. Dashboard remains READ-ONLY.
///   7. Phase 6 Infrastructure never executes/modifies trades; Phase 7 Trading Ecosystem is FROZEN —
///      Phase 8+ extends via modular APIs only.

#define GM_CORE_ARCHITECTURE_FROZEN          1
#define GM_PHASE1_COMPLETE                   1
#define GM_PHASE1_FREEZE_LABEL               "PHASE1_CORE_FROZEN"

#define GM_DASHBOARD_ARCHITECTURE_FROZEN     1
#define GM_PHASE2_COMPLETE                   1
#define GM_PHASE2_FREEZE_LABEL               "PHASE2_DASHBOARD_FROZEN"

#define GM_AI_ARCHITECTURE_FROZEN            1
#define GM_PHASE3_COMPLETE                   1
#define GM_PHASE3_FREEZE_LABEL               "PHASE3_AI_INTELLIGENCE_FROZEN"

#define GM_PHASE4_ASSISTANT_ACTIVE           1
#define GM_PHASE4_SPRINT1_LABEL              "PHASE4_SPRINT1_AI_SUPERVISOR"
#define GM_PHASE4_INTELLIGENCE_ACTIVE        1
#define GM_PHASE4_SPRINT2_LABEL              "PHASE4_SPRINT2_AI_INTELLIGENCE"
#define GM_PHASE4_MEMORY_ACTIVE              1
#define GM_PHASE4_SPRINT3_LABEL              "PHASE4_SPRINT3_AI_LEARNING_MEMORY"
#define GM_PHASE4_REPORTING_ACTIVE           1
#define GM_PHASE4_SPRINT4_LABEL              "PHASE4_SPRINT4_AI_REPORTING"
#define GM_PHASE4_CONVERSATION_ACTIVE        1
#define GM_PHASE4_SPRINT5_LABEL              "PHASE4_SPRINT5_AI_CONVERSATION"
#define GM_PHASE4_ENTERPRISE_MONITOR_ACTIVE  1
#define GM_PHASE4_SPRINT6_LABEL              "PHASE4_SPRINT6_ENTERPRISE_MONITORING"
#define GM_PHASE4_RISK_INTELLIGENCE_ACTIVE   1
#define GM_PHASE4_SPRINT7_LABEL              "PHASE4_SPRINT7_AI_RISK_INTELLIGENCE"
#define GM_PHASE4_FORECASTING_ACTIVE         1
#define GM_PHASE4_SPRINT8_LABEL              "PHASE4_SPRINT8_AI_FORECASTING"
#define GM_PHASE4_ORCHESTRATION_ACTIVE       1
#define GM_PHASE4_SPRINT9_LABEL              "PHASE4_SPRINT9_AI_ORCHESTRATION"
#define GM_PHASE4_MASTER_CONTROL_ACTIVE      1
#define GM_PHASE4_SPRINT10_LABEL             "PHASE4_SPRINT10_MASTER_CONTROL"
#define GM_PHASE4_COMPLETE                   1
#define GM_PHASE4_FREEZE_LABEL               "PHASE4_ENTERPRISE_AI_COMPLETE"
#define GM_PHASE5_MARKET_INTEL_ACTIVE        1
#define GM_PHASE5_SPRINT1_LABEL              "PHASE5_SPRINT1_MARKET_INTELLIGENCE"
#define GM_PHASE5_ORDER_FLOW_ACTIVE          1
#define GM_PHASE5_SPRINT2_LABEL              "PHASE5_SPRINT2_ORDER_FLOW_SESSION_ENERGY"
#define GM_PHASE5_NEWS_INTEL_ACTIVE          1
#define GM_PHASE5_SPRINT3_LABEL              "PHASE5_SPRINT3_NEWS_INTELLIGENCE"
#define GM_PHASE5_RECOVERY_INTEL_ACTIVE      1
#define GM_PHASE5_SPRINT4_LABEL              "PHASE5_SPRINT4_RECOVERY_INTELLIGENCE"
#define GM_PHASE5_MTF_INTEL_ACTIVE           1
#define GM_PHASE5_SPRINT5_LABEL              "PHASE5_SPRINT5_MULTI_TIMEFRAME_INTELLIGENCE"
#define GM_PHASE5_PORTFOLIO_INTEL_ACTIVE     1
#define GM_PHASE5_SPRINT6_LABEL              "PHASE5_SPRINT6_PORTFOLIO_INTELLIGENCE"
#define GM_PHASE5_PREDICTIVE_INTEL_ACTIVE    1
#define GM_PHASE5_SPRINT7_LABEL              "PHASE5_SPRINT7_PREDICTIVE_INTELLIGENCE"
#define GM_PHASE5_EXECUTION_SUPERVISOR_ACTIVE 1
#define GM_PHASE5_SPRINT8_LABEL              "PHASE5_SPRINT8_EXECUTION_SUPERVISOR"
#define GM_PHASE5_SELF_LEARNING_ACTIVE       1
#define GM_PHASE5_SPRINT9_LABEL              "PHASE5_SPRINT9_SELF_LEARNING"
#define GM_PHASE5_CERTIFICATION_ACTIVE       1
#define GM_PHASE5_SPRINT10_LABEL             "PHASE5_SPRINT10_CERTIFICATION_CLOSURE"
#define GM_PHASE5_COMPLETE                   1
#define GM_PHASE5_AI_MARKET_INTEL_FROZEN     1
#define GM_PHASE5_FREEZE_LABEL               "PHASE5_AI_MARKET_INTELLIGENCE_FROZEN"
#define GM_PHASE6_CLOUD_ACTIVE               1
#define GM_PHASE6_SPRINT1_LABEL              "PHASE6_SPRINT1_ENTERPRISE_CLOUD_FOUNDATION"
#define GM_PHASE6_REMOTE_MONITOR_ACTIVE      1
#define GM_PHASE6_SPRINT2_LABEL              "PHASE6_SPRINT2_REMOTE_MONITOR_TELEMETRY"
#define GM_PHASE6_NOTIFICATION_CENTER_ACTIVE 1
#define GM_PHASE6_SPRINT3_LABEL              "PHASE6_SPRINT3_NOTIFICATION_CENTER_MOBILE_API"
#define GM_PHASE6_INFRASTRUCTURE_ACTIVE      1
#define GM_PHASE6_SPRINT4_LABEL              "PHASE6_SPRINT4_VPS_MULTI_TERMINAL_INFRASTRUCTURE"
#define GM_PHASE6_IDENTITY_LICENSE_ACTIVE    1
#define GM_PHASE6_SPRINT5_LABEL              "PHASE6_SPRINT5_IDENTITY_LICENSE_MANAGEMENT"
#define GM_PHASE6_BACKUP_CONTINUITY_ACTIVE   1
#define GM_PHASE6_SPRINT6_LABEL              "PHASE6_SPRINT6_BACKUP_DISASTER_RECOVERY"
#define GM_PHASE6_AUDIT_COMPLIANCE_ACTIVE    1
#define GM_PHASE6_SPRINT7_LABEL              "PHASE6_SPRINT7_AUDIT_COMPLIANCE_FORENSIC"
#define GM_PHASE6_API_GATEWAY_ACTIVE         1
#define GM_PHASE6_SPRINT8_LABEL              "PHASE6_SPRINT8_API_GATEWAY_INTEGRATION_HUB"
#define GM_PHASE6_DEPLOYMENT_ACTIVE          1
#define GM_PHASE6_SPRINT9_LABEL              "PHASE6_SPRINT9_DEPLOYMENT_RELEASE_MANAGEMENT"
#define GM_PHASE6_CERTIFICATION_ACTIVE       1
#define GM_PHASE6_SPRINT10_LABEL             "PHASE6_SPRINT10_CERTIFICATION_CLOSURE"
#define GM_PHASE6_COMPLETE                   1
#define GM_PHASE6_INFRASTRUCTURE_FROZEN      1
#define GM_PHASE6_FREEZE_LABEL               "PHASE6_ENTERPRISE_INFRASTRUCTURE_FROZEN"
#define GM_PHASE7_TRADE_JOURNAL_ACTIVE       1
#define GM_PHASE7_SPRINT1_LABEL              "PHASE7_SPRINT1_TRADE_JOURNAL_ANALYTICS"
#define GM_PHASE7_STRATEGY_LAB_ACTIVE        1
#define GM_PHASE7_SPRINT2_LABEL              "PHASE7_SPRINT2_STRATEGY_LAB_BACKTEST_MC_WFA"
#define GM_PHASE7_OPTIMIZATION_LAB_ACTIVE    1
#define GM_PHASE7_SPRINT3_LABEL              "PHASE7_SPRINT3_STRATEGY_OPTIMIZATION_COMPARISON"
#define GM_PHASE7_PORTFOLIO_ANALYTICS_ACTIVE 1
#define GM_PHASE7_SPRINT4_LABEL              "PHASE7_SPRINT4_PORTFOLIO_RISK_CAPITAL_ANALYTICS"
#define GM_PHASE7_REPORTING_CENTER_ACTIVE    1
#define GM_PHASE7_SPRINT5_LABEL              "PHASE7_SPRINT5_REPORTING_INVESTOR_EXECUTIVE_BI"
#define GM_PHASE7_CONFIGURATION_CENTER_ACTIVE 1
#define GM_PHASE7_SPRINT6_LABEL              "PHASE7_SPRINT6_CONFIGURATION_PROFILES_TEMPLATES"
#define GM_PHASE7_AI_DECISION_CENTER_ACTIVE  1
#define GM_PHASE7_SPRINT7_LABEL              "PHASE7_SPRINT7_AI_DECISION_QUALITY_EXECUTION"
#define GM_PHASE7_MULTI_ACCOUNT_CENTER_ACTIVE 1
#define GM_PHASE7_SPRINT8_LABEL              "PHASE7_SPRINT8_MULTI_ACCOUNT_CLUSTERS_CAPITAL"
#define GM_PHASE7_COMMAND_CENTER_ACTIVE      1
#define GM_PHASE7_SPRINT9_LABEL              "PHASE7_SPRINT9_COMMAND_CENTER_OPS_EXECUTIVE"
#define GM_PHASE7_CERTIFICATION_ACTIVE       1
#define GM_PHASE7_SPRINT10_LABEL             "PHASE7_SPRINT10_CERTIFICATION_CLOSURE"
#define GM_PHASE7_COMPLETE                   1
#define GM_PHASE7_ECOSYSTEM_FROZEN           1
#define GM_PHASE7_FREEZE_LABEL               "PHASE7_TRADING_ECOSYSTEM_FROZEN"

string GmArchitectureFreezeBanner(void)
  {
   return StringFormat("%s | %s | Build %d | Core Architecture FROZEN",
                       GM_PRODUCT_NAME,
                       GM_PHASE1_FREEZE_LABEL,
                       GM_VERSION_BUILD);
  }

string GmPhase2FreezeBanner(void)
  {
   return StringFormat("%s | %s | Build %d | Dashboard Architecture FROZEN",
                       GM_PRODUCT_NAME,
                       GM_PHASE2_FREEZE_LABEL,
                       GM_VERSION_BUILD);
  }

string GmPhase3FreezeBanner(void)
  {
   return StringFormat("%s | %s | Build %d | AI Intelligence Architecture FROZEN | ADVISORY ONLY",
                       GM_PRODUCT_NAME,
                       GM_PHASE3_FREEZE_LABEL,
                       GM_VERSION_BUILD);
  }

string GmPhase4Sprint1Banner(void)
  {
   return StringFormat("%s | %s | Build %d | AI Supervisor ACTIVE | SUPERVISION ONLY",
                       GM_PRODUCT_NAME,
                       GM_PHASE4_SPRINT1_LABEL,
                       GM_VERSION_BUILD);
  }

string GmPhase4Sprint2Banner(void)
  {
   return StringFormat("%s | %s | Build %d | AI Decision Intelligence ACTIVE | ADVISORY ONLY",
                       GM_PRODUCT_NAME,
                       GM_PHASE4_SPRINT2_LABEL,
                       GM_VERSION_BUILD);
  }

string GmPhase4Sprint3Banner(void)
  {
   return StringFormat("%s | %s | Build %d | AI Learning Memory ACTIVE | LEARN/ADVISE ONLY",
                       GM_PRODUCT_NAME,
                       GM_PHASE4_SPRINT3_LABEL,
                       GM_VERSION_BUILD);
  }

string GmPhase4Sprint4Banner(void)
  {
   return StringFormat("%s | %s | Build %d | AI Reporting ACTIVE | REPORT/ADVISE ONLY",
                       GM_PRODUCT_NAME,
                       GM_PHASE4_SPRINT4_LABEL,
                       GM_VERSION_BUILD);
  }

string GmPhase4Sprint5Banner(void)
  {
   return StringFormat("%s | %s | Build %d | AI Conversational Assistant ACTIVE | NL ADVISORY ONLY",
                       GM_PRODUCT_NAME,
                       GM_PHASE4_SPRINT5_LABEL,
                       GM_VERSION_BUILD);
  }

string GmPhase4Sprint6Banner(void)
  {
   return StringFormat("%s | %s | Build %d | Enterprise Multi-Account Monitor ACTIVE | MONITOR ONLY",
                       GM_PRODUCT_NAME,
                       GM_PHASE4_SPRINT6_LABEL,
                       GM_VERSION_BUILD);
  }

string GmPhase4Sprint7Banner(void)
  {
   return StringFormat("%s | %s | Build %d | AI Risk Intelligence Center ACTIVE | ADVISORY ONLY",
                       GM_PRODUCT_NAME,
                       GM_PHASE4_SPRINT7_LABEL,
                       GM_VERSION_BUILD);
  }

string GmPhase4Sprint8Banner(void)
  {
   return StringFormat("%s | %s | Build %d | AI Market Forecasting ACTIVE | ANALYSIS ONLY",
                       GM_PRODUCT_NAME,
                       GM_PHASE4_SPRINT8_LABEL,
                       GM_VERSION_BUILD);
  }

string GmPhase4Sprint9Banner(void)
  {
   return StringFormat("%s | %s | Build %d | AI Knowledge Orchestration ACTIVE | SUPPORT ONLY",
                       GM_PRODUCT_NAME,
                       GM_PHASE4_SPRINT9_LABEL,
                       GM_VERSION_BUILD);
  }

string GmPhase4Sprint10Banner(void)
  {
   return StringFormat("%s | %s | Build %d | AI Master Control Center ACTIVE | READ-ONLY",
                       GM_PRODUCT_NAME,
                       GM_PHASE4_SPRINT10_LABEL,
                       GM_VERSION_BUILD);
  }

string GmPhase4CompleteBanner(void)
  {
   return StringFormat("%s | %s | Build %d | PHASE 4 COMPLETE | ENTERPRISE AI READY",
                       GM_PRODUCT_NAME,
                       GM_PHASE4_FREEZE_LABEL,
                       GM_VERSION_BUILD);
  }

string GmPhase5Sprint1Banner(void)
  {
   return StringFormat("%s | %s | Build %d | Market Intelligence ACTIVE | ANALYSIS ONLY",
                       GM_PRODUCT_NAME,
                       GM_PHASE5_SPRINT1_LABEL,
                       GM_VERSION_BUILD);
  }

string GmPhase5Sprint2Banner(void)
  {
   return StringFormat("%s | %s | Build %d | Order Flow / Session / Energy ACTIVE | ANALYSIS ONLY",
                       GM_PRODUCT_NAME,
                       GM_PHASE5_SPRINT2_LABEL,
                       GM_VERSION_BUILD);
  }

string GmPhase5Sprint3Banner(void)
  {
   return StringFormat("%s | %s | Build %d | News Intelligence ACTIVE | NEVER DISABLE TRADING",
                       GM_PRODUCT_NAME,
                       GM_PHASE5_SPRINT3_LABEL,
                       GM_VERSION_BUILD);
  }

string GmPhase5Sprint4Banner(void)
  {
   return StringFormat("%s | %s | Build %d | Recovery Intelligence ACTIVE | ANALYSIS ONLY",
                       GM_PRODUCT_NAME,
                       GM_PHASE5_SPRINT4_LABEL,
                       GM_VERSION_BUILD);
  }

string GmPhase5Sprint5Banner(void)
  {
   return StringFormat("%s | %s | Build %d | Multi-Timeframe Intelligence ACTIVE | H4 EXECUTION ONLY",
                       GM_PRODUCT_NAME,
                       GM_PHASE5_SPRINT5_LABEL,
                       GM_VERSION_BUILD);
  }

string GmPhase5Sprint6Banner(void)
  {
   return StringFormat("%s | %s | Build %d | Portfolio Intelligence ACTIVE | XAUUSD ONLY | ANALYSIS ONLY",
                       GM_PRODUCT_NAME,
                       GM_PHASE5_SPRINT6_LABEL,
                       GM_VERSION_BUILD);
  }

string GmPhase5Sprint7Banner(void)
  {
   return StringFormat("%s | %s | Build %d | Predictive Intelligence ACTIVE | ANALYSIS ONLY",
                       GM_PRODUCT_NAME,
                       GM_PHASE5_SPRINT7_LABEL,
                       GM_VERSION_BUILD);
  }

string GmPhase5Sprint8Banner(void)
  {
   return StringFormat("%s | %s | Build %d | Execution Supervisor ACTIVE | OBSERVE/AUDIT ONLY",
                       GM_PRODUCT_NAME,
                       GM_PHASE5_SPRINT8_LABEL,
                       GM_VERSION_BUILD);
  }

string GmPhase5Sprint9Banner(void)
  {
   return StringFormat("%s | %s | Build %d | Self-Learning Platform ACTIVE | LEARN/ADVISE ONLY",
                       GM_PRODUCT_NAME,
                       GM_PHASE5_SPRINT9_LABEL,
                       GM_VERSION_BUILD);
  }

string GmPhase5Sprint10Banner(void)
  {
   return StringFormat("%s | %s | Build %d | Phase 5 Certification & Closure ACTIVE",
                       GM_PRODUCT_NAME,
                       GM_PHASE5_SPRINT10_LABEL,
                       GM_VERSION_BUILD);
  }

string GmPhase5CompleteBanner(void)
  {
   return StringFormat("%s | %s | Build %d | PHASE 5 COMPLETE | AI MARKET INTELLIGENCE FROZEN",
                       GM_PRODUCT_NAME,
                       GM_PHASE5_FREEZE_LABEL,
                       GM_VERSION_BUILD);
  }

string GmPhase6Sprint1Banner(void)
  {
   return StringFormat("%s | %s | Build %d | Enterprise Cloud Foundation ACTIVE | NO TRADING AUTHORITY",
                       GM_PRODUCT_NAME,
                       GM_PHASE6_SPRINT1_LABEL,
                       GM_VERSION_BUILD);
  }

string GmPhase6Sprint2Banner(void)
  {
   return StringFormat("%s | %s | Build %d | Remote Monitor & Telemetry ACTIVE | MONITOR ONLY",
                       GM_PRODUCT_NAME,
                       GM_PHASE6_SPRINT2_LABEL,
                       GM_VERSION_BUILD);
  }

string GmPhase6Sprint3Banner(void)
  {
   return StringFormat("%s | %s | Build %d | Notification Center & Mobile API ACTIVE | NOTIFY ONLY",
                       GM_PRODUCT_NAME,
                       GM_PHASE6_SPRINT3_LABEL,
                       GM_VERSION_BUILD);
  }

string GmPhase6Sprint4Banner(void)
  {
   return StringFormat("%s | %s | Build %d | VPS & Multi-Terminal Infrastructure ACTIVE | MONITOR ONLY",
                       GM_PRODUCT_NAME,
                       GM_PHASE6_SPRINT4_LABEL,
                       GM_VERSION_BUILD);
  }

string GmPhase6Sprint5Banner(void)
  {
   return StringFormat("%s | %s | Build %d | Identity & License Management ACTIVE | NEVER INTERRUPTS TRADING",
                       GM_PRODUCT_NAME,
                       GM_PHASE6_SPRINT5_LABEL,
                       GM_VERSION_BUILD);
  }

string GmPhase6Sprint6Banner(void)
  {
   return StringFormat("%s | %s | Build %d | Backup & Disaster Recovery ACTIVE | NEVER INTERRUPTS TRADING",
                       GM_PRODUCT_NAME,
                       GM_PHASE6_SPRINT6_LABEL,
                       GM_VERSION_BUILD);
  }

string GmPhase6Sprint7Banner(void)
  {
   return StringFormat("%s | %s | Build %d | Audit & Compliance Center ACTIVE | NEVER INTERRUPTS TRADING",
                       GM_PRODUCT_NAME,
                       GM_PHASE6_SPRINT7_LABEL,
                       GM_VERSION_BUILD);
  }

string GmPhase6Sprint8Banner(void)
  {
   return StringFormat("%s | %s | Build %d | API Gateway & Integration Hub ACTIVE | READ-ONLY",
                       GM_PRODUCT_NAME,
                       GM_PHASE6_SPRINT8_LABEL,
                       GM_VERSION_BUILD);
  }

string GmPhase6Sprint9Banner(void)
  {
   return StringFormat("%s | %s | Build %d | Deployment & Release Management ACTIVE | NEVER INTERRUPTS TRADING",
                       GM_PRODUCT_NAME,
                       GM_PHASE6_SPRINT9_LABEL,
                       GM_VERSION_BUILD);
  }

string GmPhase6Sprint10Banner(void)
  {
   return StringFormat("%s | %s | Build %d | Phase 6 Certification & Closure ACTIVE",
                       GM_PRODUCT_NAME,
                       GM_PHASE6_SPRINT10_LABEL,
                       GM_VERSION_BUILD);
  }

string GmPhase6CompleteBanner(void)
  {
   return StringFormat("%s | %s | Build %d | PHASE 6 COMPLETE | ENTERPRISE INFRASTRUCTURE FROZEN",
                       GM_PRODUCT_NAME,
                       GM_PHASE6_FREEZE_LABEL,
                       GM_VERSION_BUILD);
  }

string GmPhase7Sprint1Banner(void)
  {
   return StringFormat("%s | %s | Build %d | Trade Journal & Analytics ACTIVE | ANALYSIS ONLY",
                       GM_PRODUCT_NAME,
                       GM_PHASE7_SPRINT1_LABEL,
                       GM_VERSION_BUILD);
  }

string GmPhase7Sprint2Banner(void)
  {
   return StringFormat("%s | %s | Build %d | Strategy Lab / Backtest / Monte Carlo / WFA ACTIVE | RESEARCH ONLY",
                       GM_PRODUCT_NAME,
                       GM_PHASE7_SPRINT2_LABEL,
                       GM_VERSION_BUILD);
  }

string GmPhase7Sprint3Banner(void)
  {
   return StringFormat("%s | %s | Build %d | Strategy Optimization & Comparison ACTIVE | RECOMMEND ONLY",
                       GM_PRODUCT_NAME,
                       GM_PHASE7_SPRINT3_LABEL,
                       GM_VERSION_BUILD);
  }

string GmPhase7Sprint4Banner(void)
  {
   return StringFormat("%s | %s | Build %d | Portfolio Analytics / Risk / Capital ACTIVE | READ-ONLY",
                       GM_PRODUCT_NAME,
                       GM_PHASE7_SPRINT4_LABEL,
                       GM_VERSION_BUILD);
  }

string GmPhase7Sprint5Banner(void)
  {
   return StringFormat("%s | %s | Build %d | Reporting Center / Investor / Executive BI ACTIVE | READ-ONLY",
                       GM_PRODUCT_NAME,
                       GM_PHASE7_SPRINT5_LABEL,
                       GM_VERSION_BUILD);
  }

string GmPhase7Sprint6Banner(void)
  {
   return StringFormat("%s | %s | Build %d | Configuration Center / Profiles / Templates ACTIVE | CONFIG-ONLY",
                       GM_PRODUCT_NAME,
                       GM_PHASE7_SPRINT6_LABEL,
                       GM_VERSION_BUILD);
  }

string GmPhase7Sprint7Banner(void)
  {
   return StringFormat("%s | %s | Build %d | AI Decision Center / Trade Quality / Execution ACTIVE | READ-ONLY",
                       GM_PRODUCT_NAME,
                       GM_PHASE7_SPRINT7_LABEL,
                       GM_VERSION_BUILD);
  }

string GmPhase7Sprint8Banner(void)
  {
   return StringFormat("%s | %s | Build %d | Multi-Account Center / Clusters / Capital ACTIVE | MONITOR-ONLY",
                       GM_PRODUCT_NAME,
                       GM_PHASE7_SPRINT8_LABEL,
                       GM_VERSION_BUILD);
  }

string GmPhase7Sprint9Banner(void)
  {
   return StringFormat("%s | %s | Build %d | Command Center / Ops Room / Executive Monitor ACTIVE | MONITOR-ONLY",
                       GM_PRODUCT_NAME,
                       GM_PHASE7_SPRINT9_LABEL,
                       GM_VERSION_BUILD);
  }

string GmPhase7Sprint10Banner(void)
  {
   return StringFormat("%s | %s | Build %d | Trading Ecosystem Certification & Closure ACTIVE",
                       GM_PRODUCT_NAME,
                       GM_PHASE7_SPRINT10_LABEL,
                       GM_VERSION_BUILD);
  }

string GmPhase7CompleteBanner(void)
  {
   return StringFormat("%s | %s | Build %d | PHASE 7 COMPLETE — Trading Ecosystem FROZEN",
                       GM_PRODUCT_NAME,
                       GM_PHASE7_FREEZE_LABEL,
                       GM_VERSION_BUILD);
  }

#endif // GM_ARCHITECTURE_FREEZE_MQH
//+------------------------------------------------------------------+
