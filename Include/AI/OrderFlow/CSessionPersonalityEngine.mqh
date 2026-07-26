//+------------------------------------------------------------------+
//|                                 CSessionPersonalityEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CSESSION_PERSONALITY_ENGINE_MQH
#define GM_CSESSION_PERSONALITY_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmOrderFlowResult.mqh"
#include "../News/SGmNewsAnalysisResult.mqh"
#include "../Assistant/SGmAssistantResult.mqh"
#include "../MarketIntelligence/SGmMarketIntelligenceResult.mqh"

class CGmSessionPersonalityEngine
  {
public:
   void Analyze(const SGmOrderFlowResult &partial,
                const SGmNewsAnalysisResult &news,
                const SGmAssistantResult &sup,
                const SGmMarketIntelligenceResult &mi,
                SGmOrderFlowResult &r)
     {
      if(sup.valid && (sup.recovery_active || StringFind(sup.recovery_status, "Recovery") >= 0))
         r.session_personality = GM_OF_PERS_RECOVERY;
      else if(news.valid && news.confidence >= 70.0)
         r.session_personality = GM_OF_PERS_NEWS;
      else if(partial.session_volatility >= 75.0 || (mi.valid && mi.atr_expansion_score >= 70.0))
         r.session_personality = GM_OF_PERS_HIGH_VOL;
      else if(partial.session_volatility <= 40.0 || (mi.valid && mi.compression_score >= 65.0))
         r.session_personality = GM_OF_PERS_LOW_VOL;
      else if(mi.valid && mi.trend_continuation && mi.momentum_index >= 60.0)
         r.session_personality = GM_OF_PERS_TRENDING;
      else if(mi.valid && (mi.range_formation || mi.structure_type == GM_MI_STRUCT_RANGE))
         r.session_personality = GM_OF_PERS_RANGING;
      else if(partial.session_momentum >= 62.0 && partial.session_strength >= 60.0)
         r.session_personality = GM_OF_PERS_TRENDING;
      else
         r.session_personality = GM_OF_PERS_RANGING;

      // Best/worst Gold Mind session flags (advisory heuristics)
      r.best_goldmind_session =
         (partial.active_session == GM_OF_SESSION_OVERLAP_LONDON_NY ||
          partial.active_session == GM_OF_SESSION_LONDON) &&
         r.session_personality != GM_OF_PERS_NEWS &&
         partial.historical_session_success >= 68.0;

      r.worst_goldmind_session =
         (partial.active_session == GM_OF_SESSION_SYDNEY ||
          r.session_personality == GM_OF_PERS_NEWS ||
          r.session_personality == GM_OF_PERS_HIGH_VOL) &&
         partial.historical_session_success < 58.0;

      r.personality_report = StringFormat(
                                "Session Personality Report:\r\nPersonality=%s\r\nBestGoldMindSession=%s WorstGoldMindSession=%s\r\nActive=%s HistSuccess=%.0f\r\n%s\r\n",
                                GmOfPersonalityName(r.session_personality),
                                (r.best_goldmind_session ? "Y" : "N"),
                                (r.worst_goldmind_session ? "Y" : "N"),
                                GmOfSessionName(partial.active_session),
                                partial.historical_session_success,
                                GM_OF_ADVISORY);
     }
  };

#endif // GM_CSESSION_PERSONALITY_ENGINE_MQH
//+------------------------------------------------------------------+
