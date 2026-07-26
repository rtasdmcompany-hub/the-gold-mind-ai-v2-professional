//+------------------------------------------------------------------+
//|                                  CAINewsIntelligenceCore.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CAI_NEWS_INTELLIGENCE_CORE_MQH
#define GM_CAI_NEWS_INTELLIGENCE_CORE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmNewsIntelligenceResult.mqh"
#include "../News/SGmNewsAnalysisResult.mqh"
#include "../News/NewsAIConstants.mqh"

class CGmAINewsIntelligenceCore
  {
private:
   ENUM_GM_NI_EVENT_CLASS ClassifyName(const string name) const
     {
      string u = name;
      StringToUpper(u);
      if(StringFind(u, "FOMC") >= 0 || StringFind(u, "FEDERAL FUNDS") >= 0)
         return GM_NI_EVT_FOMC;
      if(StringFind(u, "CPI") >= 0 || StringFind(u, "CONSUMER PRICE") >= 0)
         return GM_NI_EVT_CPI;
      if(StringFind(u, "PPI") >= 0 || StringFind(u, "PRODUCER PRICE") >= 0)
         return GM_NI_EVT_PPI;
      if(StringFind(u, "NFP") >= 0 || StringFind(u, "NONFARM") >= 0 ||
         StringFind(u, "NON-FARM") >= 0)
         return GM_NI_EVT_NFP;
      if(StringFind(u, "GDP") >= 0)
         return GM_NI_EVT_GDP;
      if(StringFind(u, "ECB") >= 0)
         return GM_NI_EVT_ECB;
      if(StringFind(u, "BOE") >= 0 || StringFind(u, "BANK OF ENGLAND") >= 0)
         return GM_NI_EVT_BOE;
      if(StringFind(u, "BOJ") >= 0 || StringFind(u, "BANK OF JAPAN") >= 0)
         return GM_NI_EVT_BOJ;
      if(StringFind(u, "INTEREST RATE") >= 0 || StringFind(u, "RATE DECISION") >= 0)
         return GM_NI_EVT_RATE;
      if(StringFind(u, "INFLATION") >= 0)
         return GM_NI_EVT_INFLATION;
      if(StringFind(u, "EMPLOYMENT") >= 0 || StringFind(u, "UNEMPLOYMENT") >= 0 ||
         StringFind(u, "JOBLESS") >= 0)
         return GM_NI_EVT_EMPLOYMENT;
      if(StringFind(u, "WAR") >= 0 || StringFind(u, "SANCTION") >= 0 ||
         StringFind(u, "GEOPOLIT") >= 0)
         return GM_NI_EVT_GEOPOLITICAL;
      if(StringLen(name) > 0)
         return GM_NI_EVT_OTHER;
      return GM_NI_EVT_UNKNOWN;
     }

public:
   void Analyze(const SGmNewsAnalysisResult &news,
                SGmNewsIntelligenceResult &r)
     {
      if(!news.valid)
        {
         r.upcoming_news = "No calendar data";
         r.calendar_summary = "Economic calendar unavailable";
         r.impact_class = GM_NI_IMPACT_NONE;
         r.news_impact_score = 15.0;
         r.news_confidence = 35.0;
         r.expected_volatility = 40.0;
         r.expected_direction_bias = 0.0;
         r.seconds_until_event = 0;
         r.countdown_text = "—";
         r.event_count = 0;
         r.event_class = GM_NI_EVT_UNKNOWN;
        }
      else
        {
         SGmNewsEvent ev = news.upcoming;
         if(news.next_high_impact.valid)
            ev = news.next_high_impact;
         else if(!ev.valid && news.last_released.valid)
            ev = news.last_released;

         r.event_count = news.event_count;
         r.event_class = ClassifyName(ev.name);
         r.upcoming_news = (StringLen(ev.name) > 0) ? ev.name : "No Scheduled Event";
         r.seconds_until_event = (news.next_high_impact.valid)
                                 ? news.seconds_until_high
                                 : news.seconds_until_next;
         r.countdown_text = GmNiFormatCountdown(r.seconds_until_event);

         // Map Phase 3 impact → Sprint 3 impact class
         if(!ev.valid && news.event_count <= 0)
            r.impact_class = GM_NI_IMPACT_NONE;
         else if(news.current_impact >= GM_NEWS_IMPACT_BLACK_SWAN ||
                 news.current_impact >= GM_NEWS_IMPACT_VERY_HIGH)
            r.impact_class = GM_NI_IMPACT_EXTREME;
         else if(news.current_impact >= GM_NEWS_IMPACT_HIGH)
            r.impact_class = GM_NI_IMPACT_HIGH;
         else if(news.current_impact >= GM_NEWS_IMPACT_MEDIUM)
            r.impact_class = GM_NI_IMPACT_MEDIUM;
         else if(news.current_impact >= GM_NEWS_IMPACT_LOW)
            r.impact_class = GM_NI_IMPACT_LOW;
         else
            r.impact_class = GM_NI_IMPACT_NONE;

         r.news_impact_score = GmNiClamp(news.news_risk_score);
         if(r.news_impact_score < 5.0 && r.impact_class != GM_NI_IMPACT_NONE)
            r.news_impact_score = 20.0 + (double)r.impact_class * 18.0;

         r.news_confidence = GmNiClamp(news.confidence);
         r.expected_volatility = GmNiClamp(
                                    35.0 + r.news_impact_score * 0.45 +
                                    (news.reaction.vol_spike ? 12.0 : 0.0));

         // Soft direction bias from surprise (actual vs forecast) when available
         double bias = 0.0;
         if(ev.valid && ev.forecast != 0.0)
            bias = MathMax(-40.0, MathMin(40.0, (ev.actual - ev.forecast) * 2.0));
         r.expected_direction_bias = bias;

         r.calendar_summary = StringFormat("%s | %s | Events=%d | %s",
                                           r.upcoming_news,
                                           GmNiImpactName(r.impact_class),
                                           r.event_count,
                                           GmNiEventClassName(r.event_class));
        }

      r.news_intel_report = StringFormat(
                               "AI News Intelligence:\r\nUpcoming=%s | Countdown=%s\r\nImpactScore=%.0f | Class=%s | Conf=%.0f\r\nExpVol=%.0f | DirBias=%.0f | Class=%s\r\n%s | %s\r\n",
                               r.upcoming_news, r.countdown_text,
                               r.news_impact_score, GmNiImpactName(r.impact_class),
                               r.news_confidence, r.expected_volatility,
                               r.expected_direction_bias,
                               GmNiEventClassName(r.event_class),
                               GM_NI_ANALYSIS_ONLY, GM_NI_OPPORTUNITY);
     }
  };

#endif // GM_CAI_NEWS_INTELLIGENCE_CORE_MQH
//+------------------------------------------------------------------+
