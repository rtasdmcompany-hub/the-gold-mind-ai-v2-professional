//+------------------------------------------------------------------+
//|                                CAIForecastAccuracyTracker.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CAI_FORECAST_ACCURACY_TRACKER_MQH
#define GM_CAI_FORECAST_ACCURACY_TRACKER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmForecastResult.mqh"
#include "../Trend/SGmTrendAnalysisResult.mqh"
#include "../Trend/TrendAIConstants.mqh"

class CGmAIForecastAccuracyTracker
  {
private:
   int    m_correct;
   int    m_incorrect;
   double m_last_score;
   ENUM_GM_FCST_OUTLOOK m_prev_outlook;
   ENUM_GM_TREND_DIR    m_prev_primary;

public:
                     CGmAIForecastAccuracyTracker(void)
                       : m_correct(0), m_incorrect(0), m_last_score(75.0),
                         m_prev_outlook(GM_FCST_OUTLOOK_UNKNOWN),
                         m_prev_primary(GM_TREND_DIR_UNKNOWN) {}

   void Reset(void)
     {
      m_correct = m_incorrect = 0;
      m_last_score = 75.0;
      m_prev_outlook = GM_FCST_OUTLOOK_UNKNOWN;
      m_prev_primary = GM_TREND_DIR_UNKNOWN;
     }

   void Analyze(const SGmTrendAnalysisResult &trend,
                const SGmForecastResult &partial,
                SGmForecastResult &r)
     {
      // Soft online accuracy: compare prior outlook bias vs current trend direction
      if(m_prev_outlook != GM_FCST_OUTLOOK_UNKNOWN && trend.valid &&
         trend.primary != GM_TREND_DIR_UNKNOWN)
        {
         const bool expected_bull = (m_prev_outlook == GM_FCST_OUTLOOK_POSITIVE ||
                                     m_prev_outlook == GM_FCST_OUTLOOK_MOD_POSITIVE);
         const bool expected_bear = (m_prev_outlook == GM_FCST_OUTLOOK_NEGATIVE);
         const bool expected_flat = (m_prev_outlook == GM_FCST_OUTLOOK_NEUTRAL);
         bool hit = false;
         if(expected_bull && trend.primary == GM_TREND_DIR_BULL) hit = true;
         else if(expected_bear && trend.primary == GM_TREND_DIR_BEAR) hit = true;
         else if(expected_flat && (trend.primary == GM_TREND_DIR_FLAT ||
                                   MathAbs(trend.directional_bias) < 15.0)) hit = true;
         else if(!expected_bull && !expected_bear && !expected_flat) hit = true;

         if(hit) m_correct++;
         else m_incorrect++;
        }

      m_prev_outlook = partial.outlook;
      if(trend.valid)
         m_prev_primary = trend.primary;

      const int total = m_correct + m_incorrect;
      double score = m_last_score;
      if(total > 0)
         score = 100.0 * (double)m_correct / (double)total;
      else
         score = GmFcstClamp(55.0 + partial.forecast_confidence * 0.25);

      // Blend with confidence calibration for early sessions
      if(total < 5)
         score = 0.55 * score + 0.45 * partial.forecast_confidence;

      r.accuracy_improvement = score - m_last_score;
      m_last_score = score;
      r.accuracy_score = GmFcstClamp(score);
      r.correct_forecasts = m_correct;
      r.incorrect_forecasts = m_incorrect;

      r.accuracy_report = StringFormat(
                             "Forecast Accuracy Score:\r\nAI Forecast Accuracy:\r\n%.0f%%\r\n\r\nImprovement:\r\n%+.0f%%\r\n\r\nCorrect=%d Incorrect=%d\r\n%s\r\n",
                             r.accuracy_score,
                             r.accuracy_improvement,
                             r.correct_forecasts,
                             r.incorrect_forecasts,
                             GM_FCST_ANALYSIS_ONLY);
     }
  };

#endif // GM_CAI_FORECAST_ACCURACY_TRACKER_MQH
//+------------------------------------------------------------------+
