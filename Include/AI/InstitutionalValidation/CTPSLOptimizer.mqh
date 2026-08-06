//+------------------------------------------------------------------+
//|                                           CTPSLOptimizer.mqh |
//|  MODULE 4 — verify only; small SL/TP optimization (<=20% ATR) |
//+------------------------------------------------------------------+
#ifndef GM_CTPSL_OPTIMIZER_MQH
#define GM_CTPSL_OPTIMIZER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "Phase14Constants.mqh"

class CTPSLOptimizer
  {
private:
   int m_atr_handle;

   double ReadAtr(void) const
     {
      if(m_atr_handle == INVALID_HANDLE)
         return 0.0;
      double buf[];
      ArraySetAsSeries(buf, true);
      if(CopyBuffer(m_atr_handle, 0, 0, 1, buf) != 1)
         return 0.0;
      return buf[0];
     }

   double NearestLiquidityTarget(const bool isBuy, const double entry, const double currentTp) const
     {
      // Prefer nearest swing high (buy TP) / swing low (sell TP) within ~1.5 ATR of entry
      const double atr = ReadAtr();
      const double maxDist = (atr > 0.0) ? atr * 1.5 : MathAbs(currentTp - entry);
      double best = currentTp;
      double bestDist = MathAbs(currentTp - entry);

      for(int i = 1; i <= 30; i++)
        {
         const double h = iHigh(_Symbol, PERIOD_H4, i);
         const double l = iLow(_Symbol, PERIOD_H4, i);
         if(isBuy)
           {
            if(h > entry && (h - entry) <= maxDist)
              {
               const double d = h - entry;
               if(d < bestDist || best == currentTp)
                 {
                  best = h;
                  bestDist = d;
                 }
              }
           }
         else
           {
            if(l < entry && (entry - l) <= maxDist)
              {
               const double d = entry - l;
               if(d < bestDist || best == currentTp)
                 {
                  best = l;
                  bestDist = d;
                 }
              }
           }
        }
      return best;
     }

public:
                     CTPSLOptimizer(void) : m_atr_handle(INVALID_HANDLE) {}
   void SetAtrHandle(const int handle) { m_atr_handle = handle; }

   // Returns true always; writes possibly adjusted SL/TP. Does NOT redesign strategy.
   void Optimize(const bool isBuy,
                 const double entry,
                 const double slIn,
                 const double tpIn,
                 double &slOut,
                 double &tpOut,
                 bool &slAdjusted,
                 bool &tpAdjusted)
     {
      const int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
      slOut = slIn;
      tpOut = tpIn;
      slAdjusted = false;
      tpAdjusted = false;

      const double atr = ReadAtr();
      const double maxAdj = (atr > 0.0) ? atr * GM_P14_SL_ATR_ADJUST_MAX : 0.0;

      // --- SL verify ---
      bool slValid = false;
      if(slIn > 0.0)
        {
         if(isBuy)
            slValid = (slIn < entry);
         else
            slValid = (slIn > entry);
        }

      if(!slValid && entry > 0.0 && atr > 0.0)
        {
         // Minimal heal only: place SL at 1x ATR (within redesign ban — only if invalid)
         slOut = isBuy ? NormalizeDouble(entry - atr, digits)
                       : NormalizeDouble(entry + atr, digits);
         slAdjusted = true;
        }
      else if(slValid && maxAdj > 0.0)
        {
         // Optional slight widen if SL is extremely tight (< 0.35 ATR)
         const double dist = MathAbs(entry - slIn);
         if(atr > 0.0 && dist < atr * 0.35)
           {
            const double target = atr * 0.50;
            double desired = isBuy ? (entry - target) : (entry + target);
            const double delta = desired - slIn;
            if(MathAbs(delta) <= maxAdj)
              {
               slOut = NormalizeDouble(desired, digits);
               slAdjusted = (MathAbs(slOut - slIn) > 0.0);
              }
           }
         // else keep original (already valid)
        }

      // --- TP verify ---
      bool tpValid = false;
      if(tpIn > 0.0)
        {
         if(isBuy)
            tpValid = (tpIn > entry);
         else
            tpValid = (tpIn < entry);
        }

      if(!tpValid)
        {
         const double liq = NearestLiquidityTarget(isBuy, entry, tpIn);
         if(isBuy && liq > entry)
           {
            tpOut = NormalizeDouble(liq, digits);
            tpAdjusted = true;
           }
         else if(!isBuy && liq < entry)
           {
            tpOut = NormalizeDouble(liq, digits);
            tpAdjusted = true;
           }
         else if(atr > 0.0)
           {
            tpOut = isBuy ? NormalizeDouble(entry + atr, digits)
                          : NormalizeDouble(entry - atr, digits);
            tpAdjusted = true;
           }
        }
      else
        {
         // Already valid — keep original. Optional: snap to nearer liquidity only if closer
         // and within tiny band (not a redesign).
         const double liq = NearestLiquidityTarget(isBuy, entry, tpIn);
         if(isBuy && liq > entry && liq < tpIn && (tpIn - liq) <= maxAdj)
           {
            tpOut = NormalizeDouble(liq, digits);
            tpAdjusted = (tpOut != tpIn);
           }
         else if(!isBuy && liq < entry && liq > tpIn && (liq - tpIn) <= maxAdj)
           {
            tpOut = NormalizeDouble(liq, digits);
            tpAdjusted = (tpOut != tpIn);
           }
        }
     }
  };

#endif // GM_CTPSL_OPTIMIZER_MQH
//+------------------------------------------------------------------+
