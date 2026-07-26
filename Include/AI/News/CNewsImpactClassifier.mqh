//+------------------------------------------------------------------+
//|                                    CNewsImpactClassifier.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CNEWS_IMPACT_CLASSIFIER_MQH
#define GM_CNEWS_IMPACT_CLASSIFIER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "CNewsDataEngine.mqh"

/// @brief Impact classification + risk score (ANALYSIS ONLY — never blocks trades).
class CGmNewsImpactClassifier
  {
public:
   void Classify(CGmNewsDataEngine &data, SGmNewsAnalysisResult &r)
     {
      // Upgrade impact for surprise / keywords; assign confidence per event
      for(int i = 0; i < data.Count(); i++)
        {
         SGmNewsEvent e = data.At(i);
         if(!e.valid)
            continue;
         UpgradeEvent(e);
         // write-back via temporary — Analyze uses copies; re-apply to result fields
         if(r.upcoming.valid && r.upcoming.event_id == e.event_id)
            r.upcoming = e;
         if(r.next_high_impact.valid && r.next_high_impact.event_id == e.event_id)
            r.next_high_impact = e;
         if(r.last_released.valid && r.last_released.event_id == e.event_id)
            r.last_released = e;
        }

      // Current impact from nearest window (±30m live / next high / upcoming)
      r.current_impact = GM_NEWS_IMPACT_VERY_LOW;
      double risk = 5.0;

      if(r.next_high_impact.valid)
        {
         r.current_impact = r.next_high_impact.impact;
         const int sec = r.seconds_until_high;
         if(sec >= 0 && sec <= 1800)
            risk = 70.0 + (int)r.current_impact * 5.0;
         else if(sec >= 0 && sec <= 7200)
            risk = 45.0 + (int)r.current_impact * 4.0;
         else
            risk = 25.0 + (int)r.current_impact * 3.0;
        }
      else if(r.upcoming.valid)
        {
         r.current_impact = r.upcoming.impact;
         risk = 15.0 + (int)r.current_impact * 5.0;
        }

      if(r.last_released.valid &&
         (TimeCurrent() - r.last_released.event_time) <= 1800)
        {
         if((int)r.last_released.impact > (int)r.current_impact)
            r.current_impact = r.last_released.impact;
         risk = MathMax(risk, 55.0 + (int)r.last_released.impact * 5.0);
        }

      r.news_risk_score = GmNewsClamp(risk);
      r.confidence = GmNewsClamp(40.0 + r.news_risk_score * 0.35 +
                                 (r.event_count > 0 ? 10.0 : 0.0));
     }

   void UpgradeEvent(SGmNewsEvent &e)
     {
      const string n = e.name;
      string up = n;
      StringToUpper(up);

      bool surprise = false;
      if(e.forecast != 0.0 && e.actual != 0.0)
        {
         const double diff = MathAbs(e.actual - e.forecast);
         const double base = MathMax(MathAbs(e.forecast), 0.0001);
         if(diff / base >= 0.15)
            surprise = true;
        }

      if(StringFind(up, "FOMC") >= 0 || StringFind(up, "INTEREST RATE") >= 0 ||
         StringFind(up, "NFP") >= 0 || StringFind(up, "NONFARM") >= 0 ||
         StringFind(up, "NON-FARM") >= 0 || StringFind(up, "CPI") >= 0 ||
         StringFind(up, "FED") >= 0)
        {
         if((int)e.impact < (int)GM_NEWS_IMPACT_VERY_HIGH)
            e.impact = GM_NEWS_IMPACT_VERY_HIGH;
        }

      if(surprise && (int)e.impact >= (int)GM_NEWS_IMPACT_HIGH)
         e.impact = GM_NEWS_IMPACT_BLACK_SWAN;

      e.impact_confidence = GmNewsClamp(50.0 + (int)e.impact * 8.0 +
                                        (surprise ? 15.0 : 0.0));
     }
  };

#endif // GM_CNEWS_IMPACT_CLASSIFIER_MQH
//+------------------------------------------------------------------+
