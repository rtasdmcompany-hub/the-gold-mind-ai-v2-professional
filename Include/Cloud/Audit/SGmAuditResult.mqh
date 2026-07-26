//+------------------------------------------------------------------+
//|                                          SGmAuditResult.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_SGM_AUDIT_RESULT_MQH
#define GM_SGM_AUDIT_RESULT_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "AuditConstants.mqh"

struct SGmAuditResult
  {
   datetime   stamped_at;
   string     session_id;

   double     audit_health;
   double     audit_integrity;
   double     compliance_score;
   double     integrity_rating;
   double     trust_score;
   double     compliance_health;

   string     audit_status;
   string     security_status;
   string     report_status;
   string     export_status;
   string     recent_events;
   string     critical_events;
   string     audit_timeline;
   string     compliance_report;
   string     integrity_report;
   string     security_report;
   string     executive_summary;
   string     center_status;
   string     insight;
   int        event_count;
   int        critical_count;
   int        reports_generated;
   int        exports_done;
   bool       may_execute;
   bool       may_modify_risk;
   bool       may_interrupt_trading;
   bool       valid;

   void Reset(void)
     {
      stamped_at = 0;
      session_id = "";
      audit_health = audit_integrity = compliance_score = 0.0;
      integrity_rating = trust_score = compliance_health = 0.0;
      audit_status = security_status = report_status = export_status = "";
      recent_events = critical_events = audit_timeline = "";
      compliance_report = integrity_report = security_report = "";
      executive_summary = center_status = insight = "";
      event_count = critical_count = reports_generated = exports_done = 0;
      may_execute = false;
      may_modify_risk = false;
      may_interrupt_trading = false;
      valid = false;
     }
  };

#endif // GM_SGM_AUDIT_RESULT_MQH
//+------------------------------------------------------------------+
