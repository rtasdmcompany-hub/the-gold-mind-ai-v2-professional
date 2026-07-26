//+------------------------------------------------------------------+
//|                                         CNewsDecisionApi.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CNEWS_DECISION_API_MQH
#define GM_CNEWS_DECISION_API_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmNewsAnalysisResult.mqh"

/// @brief Future AI Decision Support interface — READ-ONLY intelligence export.
/// @warning NEVER exposes trade-block / skip / cancel flags as actionable.
struct SGmNewsDecisionExport
  {
   double              news_risk_score;
   ENUM_GM_NEWS_IMPACT impact;
   string              impact_name;
   string              reaction_summary;
   ENUM_GM_NEWS_REACTION reaction;
   double              event_confidence;
   double              confidence;
   int                 event_count;
   int                 gold_event_count;
   int                 seconds_until_high;
   string              upcoming_name;
   string              next_high_name;
   bool                allows_trade_block; // ALWAYS false
   string              policy_note;
   bool                valid;

   void Reset(void)
     {
      news_risk_score = 0.0;
      impact = GM_NEWS_IMPACT_VERY_LOW;
      impact_name = reaction_summary = "";
      reaction = GM_NEWS_REACT_NONE;
      event_confidence = confidence = 0.0;
      event_count = gold_event_count = 0;
      seconds_until_high = 0;
      upcoming_name = next_high_name = "";
      allows_trade_block = false;
      policy_note = "Gold Mind may trade during news — AI never blocks execution";
      valid = false;
     }
  };

class CGmNewsDecisionApi
  {
public:
   SGmNewsDecisionExport Export(const SGmNewsAnalysisResult &r) const
     {
      SGmNewsDecisionExport x;
      x.Reset();
      if(!r.valid)
         return x;
      x.news_risk_score = r.news_risk_score;
      x.impact = r.current_impact;
      x.impact_name = GmNewsImpactName(r.current_impact);
      x.reaction = r.reaction_status;
      x.reaction_summary = r.reaction.summary;
      x.event_confidence = r.upcoming.valid ? r.upcoming.impact_confidence : r.confidence;
      x.confidence = r.confidence;
      x.event_count = r.event_count;
      x.gold_event_count = r.gold_event_count;
      x.seconds_until_high = r.seconds_until_high;
      x.upcoming_name = r.upcoming.valid ? r.upcoming.name : "—";
      x.next_high_name = r.next_high_impact.valid ? r.next_high_impact.name : "—";
      x.allows_trade_block = false; // HARD POLICY
      x.valid = true;
      return x;
     }

   double NewsRiskScore(const SGmNewsAnalysisResult &r) const
     { return r.valid ? r.news_risk_score : 0.0; }

   ENUM_GM_NEWS_IMPACT ImpactClassification(const SGmNewsAnalysisResult &r) const
     { return r.valid ? r.current_impact : GM_NEWS_IMPACT_VERY_LOW; }

   string MarketReactionAnalysis(const SGmNewsAnalysisResult &r) const
     { return r.valid ? r.reaction.summary : ""; }

   double EventConfidence(const SGmNewsAnalysisResult &r) const
     { return r.valid ? r.confidence : 0.0; }

   /// @brief Explicit: AI must never request trade skip/block/cancel.
   bool MayBlockTrades(void) const { return false; }
  };

#endif // GM_CNEWS_DECISION_API_MQH
//+------------------------------------------------------------------+
