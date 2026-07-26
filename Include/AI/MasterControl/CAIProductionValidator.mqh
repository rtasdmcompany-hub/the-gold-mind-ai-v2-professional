//+------------------------------------------------------------------+
//|                                      CAIProductionValidator.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CAI_PRODUCTION_VALIDATOR_MQH
#define GM_CAI_PRODUCTION_VALIDATOR_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmMasterControlResult.mqh"

class CGmAIProductionValidator
  {
public:
   void Analyze(const SGmMasterControlResult &partial,
                const bool logging_ok,
                SGmMasterControlResult &r)
     {
      double score = 50.0;
      if(partial.modules_connected >= partial.modules_expected) score += 15.0;
      else score += (double)partial.modules_connected * 1.5;
      if(partial.ai_health_score >= 85.0) score += 10.0;
      else if(partial.ai_health_score >= 70.0) score += 6.0;
      if(StringFind(partial.api_status, "Ready") >= 0) score += 5.0;
      if(StringFind(partial.database_status, "Ready") >= 0) score += 5.0;
      if(logging_ok) score += 5.0;
      if(partial.audit_pass) score += 8.0;
      if(partial.security_pass) score += 7.0;

      r.production_readiness = GmMccClamp(score);
      if(r.production_readiness >= 90.0)
         r.production_status = "READY";
      else if(r.production_readiness >= 75.0)
         r.production_status = "NEAR READY";
      else
         r.production_status = "REVIEW";

      r.production_report = StringFormat(
                               "Production Readiness Score:\r\nProduction Readiness:\r\n%.0f%%\r\n\r\nStatus:\r\n%s\r\n\r\nModules=%d/%d | Health=%.0f | Audit=%s | Security=%s\r\n%s\r\n",
                               r.production_readiness, r.production_status,
                               partial.modules_connected, partial.modules_expected,
                               partial.ai_health_score,
                               (partial.audit_pass ? "PASS" : "PENDING"),
                               (partial.security_pass ? "PASS" : "PENDING"),
                               GM_MCC_ADVISORY);
     }
  };

#endif // GM_CAI_PRODUCTION_VALIDATOR_MQH
//+------------------------------------------------------------------+
