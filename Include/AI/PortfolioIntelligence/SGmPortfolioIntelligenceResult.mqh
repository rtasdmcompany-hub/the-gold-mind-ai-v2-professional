//+------------------------------------------------------------------+
//|                            SGmPortfolioIntelligenceResult.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_SGM_PORTFOLIO_INTELLIGENCE_RESULT_MQH
#define GM_SGM_PORTFOLIO_INTELLIGENCE_RESULT_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "PortfolioIntelligenceConstants.mqh"

struct SGmPortfolioSymbolSlot
  {
   string  symbol;
   bool    enabled;          // live execution allowed
   bool    architecture_ready;
   string  status;           // LIVE / DISABLED / FUTURE

   void Reset(void)
     {
      symbol = "";
      enabled = false;
      architecture_ready = false;
      status = "DISABLED";
     }
  };

struct SGmPortfolioIntelligenceResult
  {
   datetime                 stamped_at;
   string                   symbol;          // live chart symbol
   ulong                    session_id;
   ENUM_GM_PI_STATUS        status;

   // Portfolio intelligence
   double                   portfolio_health;
   double                   portfolio_exposure;
   double                   capital_allocation_pct;
   int                      open_positions;
   int                      pending_orders;
   bool                     recovery_active;
   string                   recovery_status;
   double                   risk_distribution;
   double                   performance_distribution;
   double                   portfolio_intelligence_score;
   double                   portfolio_health_index;
   double                   portfolio_stability_score;
   ENUM_GM_PI_HEALTH        health_class;
   string                   portfolio_report;

   // Multi-symbol framework
   SGmPortfolioSymbolSlot   symbols[GM_PI_SYMBOL_MAX];
   int                      symbol_count;
   int                      enabled_symbol_count;
   string                   live_symbol;
   string                   multi_symbol_report;

   // Correlation
   double                   positive_correlation;
   double                   negative_correlation;
   double                   weak_correlation;
   double                   strong_correlation;
   double                   portfolio_correlation;
   double                   market_correlation;
   double                   correlation_confidence;
   double                   diversification_score;
   string                   correlation_matrix;
   string                   correlation_report;

   // Capital
   double                   capital_usage_pct;
   double                   free_margin;
   double                   used_margin;
   double                   equity;
   double                   balance;
   double                   floating_pl;
   double                   daily_growth;
   double                   weekly_growth;
   double                   monthly_growth;
   double                   capital_efficiency_score;
   double                   growth_stability_score;
   string                   capital_report;

   // Portfolio risk
   double                   total_exposure;
   double                   long_exposure;
   double                   short_exposure;
   double                   recovery_exposure;
   double                   drawdown_distribution;
   double                   margin_risk;
   double                   portfolio_risk_score;
   double                   capital_protection_rating;
   string                   risk_report;

   string                   ai_portfolio_recommendation;
   string                   center_status;
   string                   advisory_status;
   string                   insight;
   bool                     may_execute;
   bool                     may_enable_symbols;
   bool                     from_cache;
   bool                     valid;

   void Reset(void)
     {
      stamped_at = 0;
      symbol = "";
      session_id = 0;
      status = GM_PI_STATUS_IDLE;
      portfolio_health = portfolio_exposure = capital_allocation_pct = 0.0;
      open_positions = pending_orders = 0;
      recovery_active = false;
      recovery_status = "Idle";
      risk_distribution = performance_distribution = 0.0;
      portfolio_intelligence_score = portfolio_health_index = 0.0;
      portfolio_stability_score = 0.0;
      health_class = GM_PI_HEALTH_UNKNOWN;
      portfolio_report = "";
      for(int i = 0; i < GM_PI_SYMBOL_MAX; i++)
         symbols[i].Reset();
      symbol_count = enabled_symbol_count = 0;
      live_symbol = GM_PI_LIVE_SYMBOL;
      multi_symbol_report = "";
      positive_correlation = negative_correlation = weak_correlation = 0.0;
      strong_correlation = portfolio_correlation = market_correlation = 0.0;
      correlation_confidence = diversification_score = 0.0;
      correlation_matrix = correlation_report = "";
      capital_usage_pct = free_margin = used_margin = 0.0;
      equity = balance = floating_pl = 0.0;
      daily_growth = weekly_growth = monthly_growth = 0.0;
      capital_efficiency_score = growth_stability_score = 0.0;
      capital_report = "";
      total_exposure = long_exposure = short_exposure = 0.0;
      recovery_exposure = drawdown_distribution = margin_risk = 0.0;
      portfolio_risk_score = capital_protection_rating = 0.0;
      risk_report = "";
      ai_portfolio_recommendation = "";
      center_status = "Idle";
      advisory_status = GM_PI_ADVISORY;
      insight = "";
      may_execute = false;
      may_enable_symbols = false;
      from_cache = false;
      valid = false;
     }
  };

#endif // GM_SGM_PORTFOLIO_INTELLIGENCE_RESULT_MQH
//+------------------------------------------------------------------+
