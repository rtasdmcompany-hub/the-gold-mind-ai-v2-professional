//+------------------------------------------------------------------+
//|                                    CConfidenceCalculator.mqh |
//+------------------------------------------------------------------+
#ifndef GM_CCONFIDENCE_CALCULATOR_MQH
#define GM_CCONFIDENCE_CALCULATOR_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "Phase14Constants.mqh"

class CConfidenceCalculator
  {
public:
   double FinalConfidence(const double h4,
                          const double structure,
                          const double institutional,
                          const double market) const
     {
      double f = GM_P14_W_H4 * h4
               + GM_P14_W_STRUCTURE * structure
               + GM_P14_W_INSTITUTIONAL * institutional
               + GM_P14_W_MARKET * market;
      if(f > 100.0) f = 100.0;
      if(f < 0.0) f = 0.0;
      return f;
     }

   ENUM_GM_P14_VERDICT Verdict(const double finalConfidence) const
     {
      if(finalConfidence >= GM_P14_CONF_EXECUTE)
         return GM_P14_EXECUTE;
      if(finalConfidence >= GM_P14_CONF_OPTIONAL)
         return GM_P14_OPTIONAL;
      return GM_P14_REJECT;
     }
  };

#endif // GM_CCONFIDENCE_CALCULATOR_MQH
//+------------------------------------------------------------------+
