//+------------------------------------------------------------------+
//|                                         SGmBackupResult.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_SGM_BACKUP_RESULT_MQH
#define GM_SGM_BACKUP_RESULT_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "BackupConstants.mqh"

struct SGmBackupResult
  {
   datetime                stamped_at;
   ENUM_GM_BDR_STATUS      backup_status;
   ENUM_GM_BDR_BACKUP_MODE last_mode;
   ENUM_GM_BDR_POLICY      policy;
   ENUM_GM_BDR_STORAGE     storage;

   string                  backup_status_text;
   datetime                last_backup_at;
   datetime                next_backup_at;
   double                  backup_health;
   double                  recovery_readiness;
   double                  business_continuity;
   double                  system_availability;
   double                  storage_usage_pct;
   int                     retention_days;
   int                     version_count;
   string                  restore_status;
   string                  retention_policy;
   string                  policy_status;
   string                  integrity_status;
   string                  restore_validation_report;
   string                  recovery_report;
   string                  availability_report;
   string                  center_status;
   string                  insight;
   bool                    may_execute;
   bool                    may_modify_risk;
   bool                    may_interrupt_trading;
   bool                    valid;

   void Reset(void)
     {
      stamped_at = 0;
      backup_status = GM_BDR_STATUS_IDLE;
      last_mode = GM_BDR_MODE_AUTOMATIC;
      policy = GM_BDR_POL_DAILY;
      storage = GM_BDR_STORE_LOCAL;
      backup_status_text = "";
      last_backup_at = next_backup_at = 0;
      backup_health = recovery_readiness = business_continuity = 0.0;
      system_availability = storage_usage_pct = 0.0;
      retention_days = GM_BDR_RETENTION_DEFAULT;
      version_count = 0;
      restore_status = retention_policy = policy_status = "";
      integrity_status = restore_validation_report = "";
      recovery_report = availability_report = "";
      center_status = insight = "";
      may_execute = false;
      may_modify_risk = false;
      may_interrupt_trading = false;
      valid = false;
     }
  };

#endif // GM_SGM_BACKUP_RESULT_MQH
//+------------------------------------------------------------------+
