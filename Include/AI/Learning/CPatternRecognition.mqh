//+------------------------------------------------------------------+
//|                                      CPatternRecognition.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CPATTERN_RECOGNITION_MQH
#define GM_CPATTERN_RECOGNITION_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmLearningAnalysisResult.mqh"
#include "../Trend/SGmTrendAnalysisResult.mqh"
#include "../Volatility/SGmVolatilityAnalysisResult.mqh"
#include "../News/SGmNewsAnalysisResult.mqh"
#include "../Confidence/SGmConfidenceAnalysisResult.mqh"

struct SGmDetectedPattern
  {
   ENUM_GM_LEARN_PATTERN type;
   double                strength;
   string                note;
   bool                  valid;

   void Reset(void)
     {
      type = GM_LEARN_PAT_NONE;
      strength = 0.0;
      note = "";
      valid = false;
     }
  };

class CGmPatternRecognitionEngine
  {
private:
   SGmDetectedPattern m_pats[GM_LEARN_PATTERN_MAX];
   int                m_n;

   void Add(const ENUM_GM_LEARN_PATTERN t, const double strength, const string note)
     {
      if(m_n >= GM_LEARN_PATTERN_MAX)
         return;
      m_pats[m_n].Reset();
      m_pats[m_n].type = t;
      m_pats[m_n].strength = GmLearnClamp(strength);
      m_pats[m_n].note = note;
      m_pats[m_n].valid = true;
      m_n++;
     }

public:
                     CGmPatternRecognitionEngine(void) : m_n(0) {}

   int Count(void) const { return m_n; }
   SGmDetectedPattern At(const int i) const
     {
      SGmDetectedPattern p;
      p.Reset();
      if(i >= 0 && i < m_n)
         return m_pats[i];
      return p;
     }

   int Detect(const SGmTrendAnalysisResult &trend,
              const SGmVolatilityAnalysisResult &vol,
              const SGmNewsAnalysisResult &news,
              const SGmConfidenceAnalysisResult &conf,
              const int wins, const int losses,
              const int recovery_proxy, const int second_proxy)
     {
      m_n = 0;

      if(wins > losses && wins >= 2)
         Add(GM_LEARN_PAT_WIN_H4, 50.0 + wins * 5.0, "Historical H4 win dominance");
      if(losses > wins && losses >= 2)
         Add(GM_LEARN_PAT_LOSE_H4, 50.0 + losses * 5.0, "Historical H4 loss dominance");

      if(trend.valid)
        {
         if(trend.strength_score >= 70.0 && trend.trend_stability >= 60.0)
            Add(GM_LEARN_PAT_STRONG_TREND, trend.strength_score, GmTrendDirName(trend.primary));
         if(trend.strength_score < 40.0 || trend.trend_exhaustion >= 50.0)
            Add(GM_LEARN_PAT_WEAK_TREND, 100.0 - trend.strength_score, "Weak/exhausted trend");
         if(trend.bos_up || trend.bos_down)
            Add(GM_LEARN_PAT_BREAKOUT, 65.0, trend.bos_up ? "BOS Up" : "BOS Down");
         if(trend.choch_up || trend.choch_down)
            Add(GM_LEARN_PAT_REVERSAL, 60.0, trend.choch_up ? "CHOCH Up" : "CHOCH Down");
         if(trend.primary == GM_TREND_DIR_FLAT || trend.phase == GM_TREND_PHASE_SIDEWAYS)
            Add(GM_LEARN_PAT_CONSOLIDATION, 55.0, "Sideways / flat structure");
        }

      if(vol.valid)
        {
         if(vol.atr_expansion)
            Add(GM_LEARN_PAT_VOL_EXPAND, vol.energy_score, "ATR expansion");
         if(vol.atr_compression)
            Add(GM_LEARN_PAT_VOL_COMPRESS, 100.0 - vol.energy_score, "ATR compression");
         Add(GM_LEARN_PAT_ATR_BEHAVIOUR,
             GmLearnClamp(vol.atr_strength),
             StringFormat("ATR=%.5f %s", vol.atr14, GmAtrTrendName(vol.atr_trend)));
        }

      if(news.valid && news.news_risk_score >= 55.0)
         Add(GM_LEARN_PAT_NEWS_REACTION, news.news_risk_score,
             GmNewsImpactName(news.current_impact));

      if(recovery_proxy > 0)
         Add(GM_LEARN_PAT_RECOVERY_SUCCESS, GmLearnClamp(40.0 + recovery_proxy * 10.0),
             "Post-SL recovery proxy");
      if(second_proxy > 0)
         Add(GM_LEARN_PAT_SECOND_ATTEMPT, GmLearnClamp(40.0 + second_proxy * 12.0),
             "Second-attempt outcome proxy");

      if(conf.valid && conf.overall_confidence >= 75.0 && conf.trade_quality >= 70.0)
         Add(GM_LEARN_PAT_WIN_H4, conf.overall_confidence, "High-confidence H4 environment");

      return m_n;
     }
  };

#endif // GM_CPATTERN_RECOGNITION_MQH
//+------------------------------------------------------------------+
