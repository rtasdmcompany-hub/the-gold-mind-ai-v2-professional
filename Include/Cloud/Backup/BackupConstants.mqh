//+------------------------------------------------------------------+
//|                                          BackupConstants.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Phase 6 Sprint 6 — Backup / DR / Business Continuity        |
//|     DATA PROTECTION ONLY — NEVER interrupts trading             |
//+------------------------------------------------------------------+
#ifndef GM_BACKUP_CONSTANTS_MQH
#define GM_BACKUP_CONSTANTS_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#define GM_BDR_VERSION              "1.0.0-backup-continuity"
#define GM_BDR_DB_PREFIX            "GM_CLOUD_BDR_"
#define GM_BDR_THROTTLE_MS          20000
#define GM_BDR_HIST_MAX             48
#define GM_BDR_RETENTION_DEFAULT    14
#define GM_BDR_POLICY               "BACKUP & CONTINUITY ONLY — NO TRADING AUTHORITY"
#define GM_BDR_SAFE                 "LOW PRIORITY ASYNC — TRADING ALWAYS HIGHEST PRIORITY"

enum ENUM_GM_BDR_BACKUP_MODE
  {
   GM_BDR_MODE_AUTOMATIC = 0,
   GM_BDR_MODE_MANUAL,
   GM_BDR_MODE_SCHEDULED,
   GM_BDR_MODE_INCREMENTAL,
   GM_BDR_MODE_FULL
  };

enum ENUM_GM_BDR_POLICY
  {
   GM_BDR_POL_DAILY = 0,
   GM_BDR_POL_WEEKLY,
   GM_BDR_POL_MONTHLY,
   GM_BDR_POL_ON_DEMAND,
   GM_BDR_POL_HYBRID
  };

enum ENUM_GM_BDR_STORAGE
  {
   GM_BDR_STORE_LOCAL = 0,
   GM_BDR_STORE_CLOUD_READY,
   GM_BDR_STORE_HYBRID
  };

enum ENUM_GM_BDR_STATUS
  {
   GM_BDR_STATUS_IDLE = 0,
   GM_BDR_STATUS_RUNNING,
   GM_BDR_STATUS_OK,
   GM_BDR_STATUS_FAILED,
   GM_BDR_STATUS_VERIFYING,
   GM_BDR_STATUS_RESTORING
  };

string GmBdrBackupModeName(const ENUM_GM_BDR_BACKUP_MODE m)
  {
   switch(m)
     {
      case GM_BDR_MODE_AUTOMATIC:   return "Automatic";
      case GM_BDR_MODE_MANUAL:      return "Manual";
      case GM_BDR_MODE_SCHEDULED:   return "Scheduled";
      case GM_BDR_MODE_INCREMENTAL: return "Incremental";
      case GM_BDR_MODE_FULL:        return "Full";
     }
   return "Automatic";
  }

string GmBdrPolicyName(const ENUM_GM_BDR_POLICY p)
  {
   switch(p)
     {
      case GM_BDR_POL_DAILY:     return "Daily";
      case GM_BDR_POL_WEEKLY:    return "Weekly";
      case GM_BDR_POL_MONTHLY:   return "Monthly";
      case GM_BDR_POL_ON_DEMAND: return "On-Demand";
      case GM_BDR_POL_HYBRID:    return "Hybrid";
     }
   return "Daily";
  }

string GmBdrStorageName(const ENUM_GM_BDR_STORAGE s)
  {
   switch(s)
     {
      case GM_BDR_STORE_LOCAL:       return "Local";
      case GM_BDR_STORE_CLOUD_READY: return "Cloud Ready";
      case GM_BDR_STORE_HYBRID:      return "Hybrid";
     }
   return "Local";
  }

string GmBdrStatusName(const ENUM_GM_BDR_STATUS s)
  {
   switch(s)
     {
      case GM_BDR_STATUS_RUNNING:   return "Running";
      case GM_BDR_STATUS_OK:        return "OK";
      case GM_BDR_STATUS_FAILED:    return "Failed";
      case GM_BDR_STATUS_VERIFYING: return "Verifying";
      case GM_BDR_STATUS_RESTORING: return "Restoring";
     }
   return "Idle";
  }

#endif // GM_BACKUP_CONSTANTS_MQH
//+------------------------------------------------------------------+
