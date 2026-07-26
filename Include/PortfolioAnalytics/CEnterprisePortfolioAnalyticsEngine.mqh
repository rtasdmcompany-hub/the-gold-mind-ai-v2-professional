//+------------------------------------------------------------------+
//|                      CEnterprisePortfolioAnalyticsEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Phase 7 Sprint 4 — Portfolio / Risk / Capital Analytics     |
//|     READ-ONLY — NEVER interferes with live trading              |
//+------------------------------------------------------------------+
#ifndef GM_CENTERPRISE_PORTFOLIO_ANALYTICS_ENGINE_MQH
#define GM_CENTERPRISE_PORTFOLIO_ANALYTICS_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "PortfolioAnalyticsConstants.mqh"
#include "SGmPortfolioAnalyticsResult.mqh"
#include "CEpaPortfolioEngine.mqh"
#include "CEpaRiskIntelligence.mqh"
#include "CEpaCapitalAnalyzer.mqh"
#include "CEpaPerformanceAnalytics.mqh"
#include "CEpaEquityCurveLab.mqh"
#include "CEpaExportCenter.mqh"
#include "CEpaPortfolioDatabase.mqh"
#include "../Core/CFileManager.mqh"
#include "../Logging/CLogger.mqh"
#include "../AI/SGmAISnapshot.mqh"

class CGmEnterprisePortfolioAnalyticsEngine
  {
private:
   CGmLogger                        *m_logger;
   CGmEpaPortfolioEngine             m_portfolio;
   CGmEpaRiskIntelligence            m_risk;
   CGmEpaCapitalAnalyzer             m_capital;
   CGmEpaPerformanceAnalytics        m_perf;
   CGmEpaEquityCurveLab              m_equity;
   CGmEpaExportCenter                m_export;
   CGmEpaPortfolioDatabase           m_db;
   SGmPortfolioAnalyticsResult       m_last;
   ulong                             m_last_ms;
   bool                              m_ready;
   bool                              m_exported;

   double Clamp100(const double v) const
     {
      if(v < 0.0) return 0.0;
      if(v > 100.0) return 100.0;
      return v;
     }

public:
                     CGmEnterprisePortfolioAnalyticsEngine(void)
                       : m_logger(NULL), m_last_ms(0), m_ready(false), m_exported(false)
     {
      m_last.Reset();
     }

   bool Init(CGmLogger *logger,
             CGmFileManager *files,
             const long magic,
             const string symbol)
     {
      m_logger = logger;
      m_db.Init(logger, files, magic, symbol);
      m_portfolio.Init(logger, magic, symbol);
      m_risk.Init(logger);
      m_capital.Init(logger);
      m_perf.Init(logger);
      m_equity.Init(logger);
      m_export.Init(logger, files, m_db.Prefix());
      m_last.Reset();
      m_ready = true;
      m_exported = false;
      if(m_logger != NULL)
        {
         m_logger.Success("Portfolio Analytics Started | " + GM_EPA_VERSION, "EPA");
         m_logger.Info("POLICY | " + GM_EPA_POLICY, "EPA");
         m_logger.Info("SAFE | " + GM_EPA_SAFE, "EPA");
        }
      return true;
     }

   void Shutdown(void)
     {
      m_db.Shutdown();
      m_ready = false;
     }

   bool IsReady(void) const { return m_ready; }
   SGmPortfolioAnalyticsResult Last(void) const { return m_last; }
   bool MayInterruptTrading(void) const { return false; }

   bool Process(const bool force = false)
     {
      if(!m_ready)
         return false;

      const ulong now = GetTickCount();
      if(!force && m_last_ms != 0 && (now - m_last_ms) < (ulong)GM_EPA_THROTTLE_MS)
         return true;
      m_last_ms = now;

      SGmPortfolioAnalyticsResult r;
      r.Reset();
      r.stamped_at = TimeCurrent();

      m_portfolio.Collect(r);
      m_risk.Calculate(GetPointer(m_portfolio), r);
      m_capital.Analyze(r);
      m_perf.Calculate(GetPointer(m_portfolio), r);
      m_equity.Generate(GetPointer(m_portfolio), r);

      r.portfolio_health = Clamp100(
         0.40 * m_portfolio.Health() +
         0.25 * r.risk_stability +
         0.20 * r.capital_efficiency +
         0.15 * MathMin(100.0, r.profit_factor * 25.0));

      r.may_execute = false;
      r.may_modify_risk = false;
      r.may_interrupt_trading = false;
      r.center_status = "PORTFOLIO ANALYTICS CENTER — READ-ONLY";
      r.insight = StringFormat(
         "Health=%.0f Cap=%.1f%% Risk=%.0f DD=%.1f%% PF=%.2f Sharpe=%.2f Grade=%s | GM trades only",
         r.portfolio_health, r.capital_growth_pct, r.risk_stability,
         r.max_drawdown_pct, r.profit_factor, r.sharpe_ratio,
         GmEpaGradeName(r.performance_grade));
      r.valid = true;

      if(!m_exported || force)
        {
         m_export.Export(r);
         m_exported = true;
        }
      r.export_status = m_export.Status();

      m_last = r;
      m_db.Persist(r);
      return true;
     }

   void ApplyToAISnapshot(SGmAISnapshot &s) const
     {
      if(!m_last.valid)
         return;
      s.ai_status = "Portfolio Analytics Center";
      s.ai_engine = "GoldMind Enterprise Portfolio Analytics";
      s.current_mode = "EPA_READ_ONLY";
      s.confidence_pct = m_last.portfolio_health;
      s.confidence_status = StringFormat("%.1f%%", m_last.yearly_pnl);

      s.w_trend_detector = StringFormat("%.0f", m_last.portfolio_health);     // Portfolio Health
      s.future_ai_score = StringFormat("%.1f%%", m_last.capital_growth_pct);  // Capital Growth
      s.w_recovery_ai = StringFormat("%.0f", m_last.risk_stability);          // Risk Score
      s.prediction_status = StringFormat("%.1f%%", m_last.max_drawdown_pct);  // Drawdown
      s.learning_status = m_last.equity_curve_summary;                        // Equity Curve
      s.w_volatility_scanner = m_last.balance_curve_summary;                  // Balance Curve
      s.w_market_analyzer = StringFormat("%.2f", m_last.profit_factor);         // Profit Factor
      s.w_news_analyzer = StringFormat("%.2f", m_last.sharpe_ratio);           // Sharpe
      s.w_trade_confidence = StringFormat("%.2f", m_last.monthly_pnl);        // Monthly
      s.ai_version = StringFormat("Grade %s | Y=%.2f",
                                  GmEpaGradeName(m_last.performance_grade),
                                  m_last.yearly_pnl);
      s.decision_status = "ANALYTICS ONLY — CORE EXECUTION AUTHORITY";
      s.valid = true;
     }
  };

#endif // GM_CENTERPRISE_PORTFOLIO_ANALYTICS_ENGINE_MQH
//+------------------------------------------------------------------+
