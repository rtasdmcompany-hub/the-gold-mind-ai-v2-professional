//+------------------------------------------------------------------+
//|                           CInstitutionalValidationEngine.mqh |
//|  PHASE 14 orchestrator — enhancement layer before OrderSend  |
//+------------------------------------------------------------------+
#ifndef GM_CINSTITUTIONAL_VALIDATION_ENGINE_MQH
#define GM_CINSTITUTIONAL_VALIDATION_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "CStructureValidator.mqh"
#include "CInstitutionalValidator.mqh"
#include "CMarketValidator.mqh"
#include "CTPSLOptimizer.mqh"
#include "CConfidenceCalculator.mqh"

class CInstitutionalValidationEngine
  {
private:
   bool                       m_enabled;
   bool                       m_allow_optional;
   int                        m_atr_handle;
   CStructureValidator        m_structure;
   CInstitutionalValidator    m_institutional;
   CMarketValidator           m_market;
   CTPSLOptimizer             m_tpsl;
   CConfidenceCalculator      m_confidence;
   SGmP14ValidationResult     m_last;

public:
                     CInstitutionalValidationEngine(void)
     {
      m_enabled = false;
      m_allow_optional = true;
      m_atr_handle = INVALID_HANDLE;
      m_last.Reset();
     }

   void Configure(const bool enabled, const bool allowOptional, const int atrHandle)
     {
      m_enabled = enabled;
      m_allow_optional = allowOptional;
      m_atr_handle = atrHandle;
      m_market.SetAtrHandle(atrHandle);
      m_tpsl.SetAtrHandle(atrHandle);
      if(m_enabled)
         PrintFormat("TGM [P14]: Institutional AI Validation ACTIVE | %s | optional=%s",
                     GM_P14_VERSION, (m_allow_optional ? "ON" : "OFF"));
      else
         PrintFormat("TGM [P14]: Institutional AI Validation OFF (pass-through) | %s", GM_P14_VERSION);
     }

   bool IsEnabled(void) const { return m_enabled; }
   SGmP14ValidationResult LastResult(void) const { return m_last; }

   // Returns true = allow OrderSend. May adjust sl/tp slightly (TPSLOptimizer).
   // When disabled: always true, sl/tp unchanged — zero breaking change.
   bool ValidateBeforeOrderSend(const bool isBuy,
                                const double entry,
                                double &sl,
                                double &tp,
                                const string comment,
                                const int levelIndex)
     {
      m_last.Reset();
      m_last.sl_out = sl;
      m_last.tp_out = tp;

      if(!m_enabled)
        {
         m_last.enabled = false;
         m_last.approved = true;
         m_last.verdict = GM_P14_EXECUTE;
         m_last.final_confidence = 100.0;
         m_last.why = "P14 disabled — pass-through";
         return true;
        }

      m_last.enabled = true;

      // H4 Strategy already decided to place → full H4 confidence weight
      m_last.h4_confidence = 100.0;

      const SGmP14ModuleResult s = m_structure.Validate(isBuy, entry);
      const SGmP14ModuleResult i = m_institutional.Validate(isBuy, entry);
      const SGmP14ModuleResult m = m_market.Validate(isBuy);

      m_last.structure_pass = s.pass;
      m_last.institutional_pass = i.pass;
      m_last.market_pass = m.pass;
      m_last.structure_confidence = s.confidence;
      m_last.institutional_confidence = i.confidence;
      m_last.market_confidence = m.confidence;

      m_last.final_confidence = m_confidence.FinalConfidence(
         m_last.h4_confidence,
         m_last.structure_confidence,
         m_last.institutional_confidence,
         m_last.market_confidence);

      m_last.verdict = m_confidence.Verdict(m_last.final_confidence);

      // Soft module fail reduces confidence already; hard reject only on final score
      bool allow = false;
      if(m_last.verdict == GM_P14_EXECUTE)
         allow = true;
      else if(m_last.verdict == GM_P14_OPTIONAL)
         allow = m_allow_optional;
      else
         allow = false;

      double slOut = sl;
      double tpOut = tp;
      bool slAdj = false, tpAdj = false;
      if(allow)
         m_tpsl.Optimize(isBuy, entry, sl, tp, slOut, tpOut, slAdj, tpAdj);

      m_last.sl_out = slOut;
      m_last.tp_out = tpOut;
      m_last.sl_adjusted = slAdj;
      m_last.tp_adjusted = tpAdj;
      m_last.approved = allow;
      m_last.why = StringFormat("P14 %s final=%.1f | %s | %s | %s | %s L%d",
                                GmP14VerdictName(m_last.verdict),
                                m_last.final_confidence,
                                s.reason, i.reason, m.reason,
                                comment, levelIndex);

      if(allow)
        {
         sl = slOut;
         tp = tpOut;
         PrintFormat("TGM [P14]: ALLOW %s conf=%.1f slAdj=%s tpAdj=%s | %s",
                     comment, m_last.final_confidence,
                     (slAdj ? "Y" : "N"), (tpAdj ? "Y" : "N"),
                     GmP14VerdictName(m_last.verdict));
        }
      else
        {
         PrintFormat("TGM [P14]: REJECT %s conf=%.1f | %s",
                     comment, m_last.final_confidence, m_last.why);
        }

      return allow;
     }
  };

#endif // GM_CINSTITUTIONAL_VALIDATION_ENGINE_MQH
//+------------------------------------------------------------------+
