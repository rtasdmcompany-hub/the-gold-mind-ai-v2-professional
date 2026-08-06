//+------------------------------------------------------------------+
//|                                  CInstitutionalValidator.mqh |
//|  MODULE 2 — BOS / CHoCH / Liquidity / OB / FVG / Prem-Disc   |
//+------------------------------------------------------------------+
#ifndef GM_CINSTITUTIONAL_VALIDATOR_MQH
#define GM_CINSTITUTIONAL_VALIDATOR_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmP14Validation.mqh"

class CInstitutionalValidator
  {
private:
   int SessionBiasScore(const bool isBuy) const
     {
      MqlDateTime dt;
      TimeToStruct(TimeCurrent(), dt);
      const int h = dt.hour;

      // Recent H4 momentum for directional session preference
      const double c1 = iClose(_Symbol, PERIOD_H4, 1);
      const double c5 = iClose(_Symbol, PERIOD_H4, 5);
      int mom = 0;
      if(c1 > c5) mom = 1;
      else if(c1 < c5) mom = -1;

      // UTC approx: Asia 0-7 (quieter), London 7-12, NY 12-21
      const bool activeSession = (h >= 7 && h < 21);
      const bool asiaSession   = (h >= 0 && h < 7);

      if(asiaSession)
         return 4; // quieter session — mild neutral

      if(!activeSession)
         return 5;

      // London / NY: reward trades aligned with H4 momentum, penalize against
      if(mom == 0)
         return 6;
      if(isBuy && mom > 0)
         return 10;
      if(!isBuy && mom < 0)
         return 10;
      if(isBuy && mom < 0)
         return 2;
      if(!isBuy && mom > 0)
         return 2;
      return 5;
     }

   bool DetectFVG(const bool isBuy, double &gapMid) const
     {
      gapMid = 0.0;
      // 3-candle FVG on H4: bullish if low[1] > high[3]
      const double high3 = iHigh(_Symbol, PERIOD_H4, 3);
      const double low3  = iLow(_Symbol, PERIOD_H4, 3);
      const double high1 = iHigh(_Symbol, PERIOD_H4, 1);
      const double low1  = iLow(_Symbol, PERIOD_H4, 1);
      if(isBuy && low1 > high3)
        {
         gapMid = (low1 + high3) * 0.5;
         return true;
        }
      if(!isBuy && high1 < low3)
        {
         gapMid = (high1 + low3) * 0.5;
         return true;
        }
      return false;
     }

   bool DetectOrderBlock(const bool isBuy, double &obLevel) const
     {
      obLevel = 0.0;
      // Last opposing candle before impulse (bars 2..6)
      for(int i = 2; i <= 6; i++)
        {
         const double o = iOpen(_Symbol, PERIOD_H4, i);
         const double c = iClose(_Symbol, PERIOD_H4, i);
         const double h = iHigh(_Symbol, PERIOD_H4, i);
         const double l = iLow(_Symbol, PERIOD_H4, i);
         if(isBuy && c < o) // bearish OB before up move
           {
            const double nextC = iClose(_Symbol, PERIOD_H4, i - 1);
            if(nextC > h)
              {
               obLevel = (h + l) * 0.5;
               return true;
              }
           }
         if(!isBuy && c > o) // bullish OB before down move
           {
            const double nextC = iClose(_Symbol, PERIOD_H4, i - 1);
            if(nextC < l)
              {
               obLevel = (h + l) * 0.5;
               return true;
              }
           }
        }
      return false;
     }

public:
   SGmP14ModuleResult Validate(const bool isBuy, const double entry)
     {
      SGmP14ModuleResult r;
      r.Reset();

      const double highN = iHigh(_Symbol, PERIOD_H4, iHighest(_Symbol, PERIOD_H4, MODE_HIGH, 20, 1));
      const double lowN  = iLow(_Symbol, PERIOD_H4, iLowest(_Symbol, PERIOD_H4, MODE_LOW, 20, 1));
      const double close1 = iClose(_Symbol, PERIOD_H4, 1);
      const double range = highN - lowN;
      if(range <= 0.0)
        {
         r.confidence = 65.0;
         r.reason = "Institutional: flat range — neutral";
         return r;
        }

      const double eqTol = range * 0.05;
      // Liquidity: near equal highs / lows
      const double h1 = iHigh(_Symbol, PERIOD_H4, 1);
      const double h2 = iHigh(_Symbol, PERIOD_H4, 2);
      const double l1 = iLow(_Symbol, PERIOD_H4, 1);
      const double l2 = iLow(_Symbol, PERIOD_H4, 2);
      const bool eqHighs = (MathAbs(h1 - h2) <= eqTol);
      const bool eqLows  = (MathAbs(l1 - l2) <= eqTol);

      // BOS / CHoCH (lightweight)
      const double swingHigh = highN;
      const double swingLow  = lowN;
      const bool bosBuy  = (close1 > swingHigh * 0.998); // near/through
      const bool bosSell = (close1 < swingLow * 1.002);
      const bool chochBuy  = (!isBuy && close1 > iHigh(_Symbol, PERIOD_H4, 3));
      const bool chochSell = (isBuy && close1 < iLow(_Symbol, PERIOD_H4, 3));

      const double mid = lowN + range * 0.5;
      const bool discount = (entry < mid); // buy zone
      const bool premium  = (entry > mid); // sell zone

      double fvgMid = 0.0, obLvl = 0.0;
      const bool fvg = DetectFVG(isBuy, fvgMid);
      const bool ob  = DetectOrderBlock(isBuy, obLvl);

      double score = 50.0;
      string why = "Institutional:";

      if(isBuy)
        {
         if(discount) { score += 12.0; why += " discount"; }
         else { score -= 8.0; why += " premium-risk"; }
         if(eqLows) { score += 8.0; why += " buy-side-liq"; }
         if(bosBuy) { score += 10.0; why += " BOS"; }
         if(chochBuy) { score -= 12.0; why += " CHoCH-against"; }
         if(fvg) { score += 8.0; why += " FVG"; }
         if(ob) { score += 8.0; why += " OB"; }
        }
      else
        {
         if(premium) { score += 12.0; why += " premium"; }
         else { score -= 8.0; why += " discount-risk"; }
         if(eqHighs) { score += 8.0; why += " sell-side-liq"; }
         if(bosSell) { score += 10.0; why += " BOS"; }
         if(chochSell) { score -= 12.0; why += " CHoCH-against"; }
         if(fvg) { score += 8.0; why += " FVG"; }
         if(ob) { score += 8.0; why += " OB"; }
        }

      score += (double)SessionBiasScore(isBuy);
      why += " session";

      if(score > 100.0) score = 100.0;
      if(score < 0.0) score = 0.0;
      r.confidence = score;
      r.pass = (score >= 45.0);
      r.reason = why + StringFormat(" conf=%.0f", score);
      return r;
     }
  };

#endif // GM_CINSTITUTIONAL_VALIDATOR_MQH
//+------------------------------------------------------------------+
