//+------------------------------------------------------------------+
//|                                    CGlobalSessionAnalyzer.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CGLOBAL_SESSION_ANALYZER_MQH
#define GM_CGLOBAL_SESSION_ANALYZER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmOrderFlowResult.mqh"
#include "../Volatility/SGmVolatilityAnalysisResult.mqh"
#include "../Trend/SGmTrendAnalysisResult.mqh"
#include "../MarketIntelligence/SGmMarketIntelligenceResult.mqh"

class CGmGlobalSessionAnalyzer
  {
private:
   bool InRange(const int h, const int start, const int end) const
     {
      if(start <= end)
         return (h >= start && h < end);
      return (h >= start || h < end); // wraps midnight
     }

public:
   void Analyze(const SGmVolatilityAnalysisResult &vol,
                const SGmTrendAnalysisResult &trend,
                const SGmMarketIntelligenceResult &mi,
                SGmOrderFlowResult &r)
     {
      MqlDateTime gmt;
      TimeToStruct(TimeGMT(), gmt);
      const int h = gmt.hour;
      const int m = gmt.min;

      const bool sydney = InRange(h, 22, 7);
      const bool tokyo  = InRange(h, 0, 9);
      const bool london = InRange(h, 7, 16);
      const bool newyork= InRange(h, 12, 21);
      const bool asia_ov = (h >= 7 && h < 9);          // Tokyo/London
      const bool lon_ny  = (h >= 12 && h < 16);        // London/NY

      r.overlap_active = (asia_ov || lon_ny);
      if(lon_ny)
         r.active_session = GM_OF_SESSION_OVERLAP_LONDON_NY;
      else if(asia_ov)
         r.active_session = GM_OF_SESSION_OVERLAP_ASIA;
      else if(london)
         r.active_session = GM_OF_SESSION_LONDON;
      else if(newyork)
         r.active_session = GM_OF_SESSION_NEWYORK;
      else if(tokyo)
         r.active_session = GM_OF_SESSION_TOKYO;
      else if(sydney)
         r.active_session = GM_OF_SESSION_SYDNEY;
      else
         r.active_session = GM_OF_SESSION_UNKNOWN;

      // Open/close windows (±15 min of classic opens)
      r.session_open_flag = ((h == 0 || h == 7 || h == 12 || h == 22) && m < 15);
      r.session_close_flag = ((h == 7 || h == 9 || h == 16 || h == 21) && m >= 45);

      // Session metrics from observed AI layers
      r.session_volatility = vol.valid ? GmOfClamp(vol.energy_score) : 50.0;
      r.session_liquidity = mi.valid ? mi.liquidity_score
                            : (vol.valid ? GmOfClamp(vol.vol_stability) : 55.0);
      r.session_momentum = mi.valid ? mi.momentum_index
                           : (trend.valid ? trend.momentum_strength : 50.0);

      double strength = 45.0;
      if(r.overlap_active) strength += 18.0;
      if(r.active_session == GM_OF_SESSION_LONDON ||
         r.active_session == GM_OF_SESSION_NEWYORK ||
         r.active_session == GM_OF_SESSION_OVERLAP_LONDON_NY)
         strength += 12.0;
      if(vol.valid && vol.atr_expansion) strength += 8.0;
      if(vol.valid && vol.atr_compression) strength -= 6.0;
      r.session_strength = GmOfClamp(strength + r.session_momentum * 0.15);

      // Soft historical success proxy by session type (observational heuristic)
      if(r.active_session == GM_OF_SESSION_OVERLAP_LONDON_NY)
         r.historical_session_success = 78.0;
      else if(r.active_session == GM_OF_SESSION_LONDON)
         r.historical_session_success = 72.0;
      else if(r.active_session == GM_OF_SESSION_NEWYORK)
         r.historical_session_success = 70.0;
      else if(r.active_session == GM_OF_SESSION_OVERLAP_ASIA)
         r.historical_session_success = 62.0;
      else if(r.active_session == GM_OF_SESSION_TOKYO)
         r.historical_session_success = 58.0;
      else
         r.historical_session_success = 52.0;
      if(mi.valid)
         r.historical_session_success = GmOfClamp(
            0.7 * r.historical_session_success + 0.3 * mi.structure_quality);

      r.session_report = StringFormat(
                            "Global Session Analyzer:\r\nActive=%s | Open=%s Close=%s Overlap=%s\r\nStrength=%.0f Vol=%.0f Liq=%.0f Mom=%.0f HistSuccess=%.0f\r\nGMT=%02d:%02d\r\n%s\r\n",
                            GmOfSessionName(r.active_session),
                            (r.session_open_flag ? "Y" : "N"),
                            (r.session_close_flag ? "Y" : "N"),
                            (r.overlap_active ? "Y" : "N"),
                            r.session_strength, r.session_volatility,
                            r.session_liquidity, r.session_momentum,
                            r.historical_session_success, h, m,
                            GM_OF_ANALYSIS_ONLY);
     }
  };

#endif // GM_CGLOBAL_SESSION_ANALYZER_MQH
//+------------------------------------------------------------------+
