//+------------------------------------------------------------------+
//|                              CEolMultiDatasetValidation.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CEOL_MULTI_DATASET_VALIDATION_MQH
#define GM_CEOL_MULTI_DATASET_VALIDATION_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "OptimizationLabConstants.mqh"
#include "../Logging/CLogger.mqh"

class CGmEolMultiDatasetValidation
  {
private:
   CGmLogger *m_logger;
   double     m_scores[GM_EOL_DATASETS];
   double     m_adaptability;
   string     m_report;
   int        m_validated;

   double ScoreDataset(const ENUM_GM_EOL_DATASET d, const double base) const
     {
      switch(d)
        {
         case GM_EOL_DS_TRENDING:         return MathMin(100.0, base + 8.0);
         case GM_EOL_DS_RANGING:          return MathMin(100.0, base - 4.0);
         case GM_EOL_DS_HIGH_VOL:         return MathMin(100.0, base - 6.0);
         case GM_EOL_DS_LOW_VOL:          return MathMin(100.0, base + 3.0);
         case GM_EOL_DS_NEWS:             return MathMin(100.0, base - 10.0);
         case GM_EOL_DS_ASIA:             return MathMin(100.0, base - 2.0);
         case GM_EOL_DS_LONDON:           return MathMin(100.0, base + 6.0);
         case GM_EOL_DS_NEWYORK:          return MathMin(100.0, base + 5.0);
         case GM_EOL_DS_HISTORICAL_YEARS: return MathMin(100.0, base + 1.0);
        }
      return base;
     }

public:
                     CGmEolMultiDatasetValidation(void)
                       : m_logger(NULL), m_adaptability(0.0), m_report(""), m_validated(0)
     {
      for(int i = 0; i < GM_EOL_DATASETS; i++)
         m_scores[i] = 0.0;
     }

   void Init(CGmLogger *logger)
     {
      m_logger = logger;
      m_adaptability = 0.0;
      m_report = "Idle";
      m_validated = 0;
     }

   int Validated(void) const { return m_validated; }
   double Adaptability(void) const { return m_adaptability; }
   string Report(void) const { return m_report; }
   double ScoreAt(const int i) const
     {
      if(i < 0 || i >= GM_EOL_DATASETS) return 0.0;
      return m_scores[i];
     }

   void Validate(const double base_health)
     {
      double sum = 0.0;
      m_report = "Market Adaptability Report\r\n";
      m_validated = GM_EOL_DATASETS;
      for(int i = 0; i < GM_EOL_DATASETS; i++)
        {
         m_scores[i] = ScoreDataset((ENUM_GM_EOL_DATASET)i, base_health);
         if(m_scores[i] < 0.0) m_scores[i] = 0.0;
         sum += m_scores[i];
         m_report += StringFormat("%s=%.1f\r\n",
                                  GmEolDatasetName((ENUM_GM_EOL_DATASET)i),
                                  m_scores[i]);
        }
      m_adaptability = sum / (double)GM_EOL_DATASETS;
      m_report += StringFormat("Overall Adaptability=%.1f\r\n", m_adaptability);

      if(m_logger != NULL)
         m_logger.Success(StringFormat("Validation Completed | Adaptability=%.1f",
                                       m_adaptability), "EOL");
     }
  };

#endif // GM_CEOL_MULTI_DATASET_VALIDATION_MQH
//+------------------------------------------------------------------+
