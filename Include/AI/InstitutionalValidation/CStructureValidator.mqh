//+------------------------------------------------------------------+
//|                                      CStructureValidator.mqh |
//|  MODULE 1 — Trend / HH-HL / LH-LL / BOS / pullback / fake break |
//+------------------------------------------------------------------+
#ifndef GM_CSTRUCTURE_VALIDATOR_MQH
#define GM_CSTRUCTURE_VALIDATOR_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmP14Validation.mqh"

class CStructureValidator
  {
private:
   bool FindSwingHigh(const int start, const int strength, double &price, int &bar)
     {
      price = 0.0;
      bar = -1;
      const int total = iBars(_Symbol, PERIOD_H4);
      if(total < start + strength * 2 + 3)
         return false;
      for(int i = start + strength; i < start + GM_P14_SWING_LOOKBACK && i + strength < total; i++)
        {
         const double h = iHigh(_Symbol, PERIOD_H4, i);
         bool isSwing = true;
         for(int k = 1; k <= strength; k++)
           {
            if(iHigh(_Symbol, PERIOD_H4, i - k) >= h || iHigh(_Symbol, PERIOD_H4, i + k) >= h)
              {
               isSwing = false;
               break;
              }
           }
         if(isSwing)
           {
            price = h;
            bar = i;
            return true;
           }
        }
      return false;
     }

   bool FindSwingLow(const int start, const int strength, double &price, int &bar)
     {
      price = 0.0;
      bar = -1;
      const int total = iBars(_Symbol, PERIOD_H4);
      if(total < start + strength * 2 + 3)
         return false;
      for(int i = start + strength; i < start + GM_P14_SWING_LOOKBACK && i + strength < total; i++)
        {
         const double l = iLow(_Symbol, PERIOD_H4, i);
         bool isSwing = true;
         for(int k = 1; k <= strength; k++)
           {
            if(iLow(_Symbol, PERIOD_H4, i - k) <= l || iLow(_Symbol, PERIOD_H4, i + k) <= l)
              {
               isSwing = false;
               break;
              }
           }
         if(isSwing)
           {
            price = l;
            bar = i;
            return true;
           }
        }
      return false;
     }

public:
   SGmP14ModuleResult Validate(const bool isBuy, const double entry)
     {
      SGmP14ModuleResult r;
      r.Reset();

      double sh1 = 0, sh2 = 0, sl1 = 0, sl2 = 0;
      int bh1 = -1, bh2 = -1, bl1 = -1, bl2 = -1;
      if(!FindSwingHigh(1, GM_P14_SWING_STRENGTH, sh1, bh1) ||
         !FindSwingLow(1, GM_P14_SWING_STRENGTH, sl1, bl1))
        {
         r.pass = true;
         r.confidence = 70.0;
         r.reason = "Structure: insufficient swings — neutral PASS";
         return r;
        }

      FindSwingHigh(bh1 + 1, GM_P14_SWING_STRENGTH, sh2, bh2);
      FindSwingLow(bl1 + 1, GM_P14_SWING_STRENGTH, sl2, bl2);

      const bool hh = (sh2 > 0.0 && sh1 > sh2);
      const bool hl = (sl2 > 0.0 && sl1 > sl2);
      const bool lh = (sh2 > 0.0 && sh1 < sh2);
      const bool ll = (sl2 > 0.0 && sl1 < sl2);
      const bool bullStruct = (hh && hl);
      const bool bearStruct = (lh && ll);

      const double close1 = iClose(_Symbol, PERIOD_H4, 1);
      const double close0 = iClose(_Symbol, PERIOD_H4, 0);
      const bool bullBreak = (sh1 > 0.0 && close1 > sh1);
      const bool bearBreak = (sl1 > 0.0 && close1 < sl1);
      const bool fakeBull = (bullBreak && close0 < sh1);
      const bool fakeBear = (bearBreak && close0 > sl1);

      const double mid = (sh1 + sl1) * 0.5;
      const bool pullbackBuy = (isBuy && entry <= mid && entry >= sl1);
      const bool pullbackSell = (!isBuy && entry >= mid && entry <= sh1);
      const bool retestBuy = (isBuy && MathAbs(entry - sl1) <= (sh1 - sl1) * 0.15);
      const bool retestSell = (!isBuy && MathAbs(entry - sh1) <= (sh1 - sl1) * 0.15);
      const bool continuationBuy = (isBuy && bullStruct && !fakeBull);
      const bool continuationSell = (!isBuy && bearStruct && !fakeBear);

      double score = 55.0;
      string why = "Structure:";

      if(isBuy)
        {
         if(bullStruct) { score += 18.0; why += " HH/HL"; }
         else if(bearStruct) { score -= 25.0; why += " against LH/LL"; }
         if(continuationBuy) { score += 10.0; why += " continuation"; }
         if(pullbackBuy || retestBuy) { score += 8.0; why += " pullback/retest"; }
         if(bullBreak && !fakeBull) { score += 6.0; why += " structure-break"; }
         if(fakeBull) { score -= 20.0; why += " FAKE-BREAK"; }
        }
      else
        {
         if(bearStruct) { score += 18.0; why += " LH/LL"; }
         else if(bullStruct) { score -= 25.0; why += " against HH/HL"; }
         if(continuationSell) { score += 10.0; why += " continuation"; }
         if(pullbackSell || retestSell) { score += 8.0; why += " pullback/retest"; }
         if(bearBreak && !fakeBear) { score += 6.0; why += " structure-break"; }
         if(fakeBear) { score -= 20.0; why += " FAKE-BREAK"; }
        }

      if(score > 100.0) score = 100.0;
      if(score < 0.0) score = 0.0;
      r.confidence = score;
      r.pass = (score >= 50.0);
      r.reason = why + StringFormat(" conf=%.0f", score);
      return r;
     }
  };

#endif // GM_CSTRUCTURE_VALIDATOR_MQH
//+------------------------------------------------------------------+
