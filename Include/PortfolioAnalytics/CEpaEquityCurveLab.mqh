//+------------------------------------------------------------------+
//|                                   CEpaEquityCurveLab.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CEPA_EQUITY_CURVE_LAB_MQH
#define GM_CEPA_EQUITY_CURVE_LAB_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "CEpaPortfolioEngine.mqh"
#include "../Logging/CLogger.mqh"

class CGmEpaEquityCurveLab
  {
private:
   CGmLogger          *m_logger;
   SGmEpaEquityPoint   m_pts[GM_EPA_EQUITY_MAX];
   int                 m_n;

public:
                     CGmEpaEquityCurveLab(void) : m_logger(NULL), m_n(0) {}

   void Init(CGmLogger *logger)
     {
      m_logger = logger;
      m_n = 0;
     }

   int Count(void) const { return m_n; }

   void Generate(CGmEpaPortfolioEngine *port, SGmPortfolioAnalyticsResult &out)
     {
      m_n = 0;
      out.equity_points = 0;
      out.equity_curve_summary = "No curve";
      out.balance_curve_summary = "";
      out.drawdown_curve_summary = "";
      out.growth_curve_summary = "";
      out.recovery_curve_summary = "";
      out.monthly_heatmap = "";
      out.performance_timeline = "";

      if(port == NULL || port.Count() == 0)
         return;

      double equity = 100.0; // indexed curve start
      double peak = equity;
      double start = equity;
      double month_pnl[12];
      for(int m = 0; m < 12; m++) month_pnl[m] = 0.0;

      string timeline = "";
      for(int i = 0; i < port.Count() && m_n < GM_EPA_EQUITY_MAX; i++)
        {
         double pnl = 0.0, hold = 0.0;
         datetime t = 0;
         if(!port.GetPnl(i, pnl, t, hold)) continue;

         equity += pnl;
         if(equity > peak) peak = equity;
         const double dd = (peak > 0.0) ? (100.0 * (peak - equity) / peak) : 0.0;
         const double growth = (start > 0.0) ? (100.0 * (equity - start) / start) : 0.0;

         m_pts[m_n].t = t;
         m_pts[m_n].equity = equity;
         m_pts[m_n].balance = equity; // analytical proxy
         m_pts[m_n].drawdown_pct = dd;
         m_pts[m_n].growth_pct = growth;
         m_n++;

         MqlDateTime dt;
         TimeToStruct(t, dt);
         if(dt.mon >= 1 && dt.mon <= 12)
            month_pnl[dt.mon - 1] += pnl;

         if(i >= port.Count() - 6)
            timeline += StringFormat("%s:%.1f|", TimeToString(t, TIME_DATE), equity);
        }

      out.equity_points = m_n;
      const double last_eq = (m_n > 0) ? m_pts[m_n - 1].equity : 100.0;
      const double last_dd = (m_n > 0) ? m_pts[m_n - 1].drawdown_pct : 0.0;
      const double last_g = (m_n > 0) ? m_pts[m_n - 1].growth_pct : 0.0;

      out.equity_curve_summary = StringFormat("EquityCurve pts=%d last=%.2f (indexed)", m_n, last_eq);
      out.balance_curve_summary = StringFormat("BalanceCurve last=%.2f", last_eq);
      out.drawdown_curve_summary = StringFormat("DrawdownCurve last=%.1f%% max=%.1f%%",
                                                last_dd, out.max_drawdown_pct);
      out.growth_curve_summary = StringFormat("GrowthCurve=%.1f%%", last_g);
      out.recovery_curve_summary = StringFormat("RecoveryCurve RF=%.2f", out.recovery_factor);
      out.performance_timeline = timeline;

      out.monthly_heatmap = "MonthlyHeatmap|";
      const string months = "JanFebMarAprMayJunJulAugSepOctNovDec";
      for(int m = 0; m < 12; m++)
         out.monthly_heatmap += StringFormat("%s:%.1f|",
                                            StringSubstr(months, m * 3, 3), month_pnl[m]);

      if(m_logger != NULL)
         m_logger.Info("Equity Curve Generated | " + out.equity_curve_summary, "EPA");
     }
  };

#endif // GM_CEPA_EQUITY_CURVE_LAB_MQH
//+------------------------------------------------------------------+
