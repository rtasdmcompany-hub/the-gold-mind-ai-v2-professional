//+------------------------------------------------------------------+
//|                                           AuditConstants.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Phase 6 Sprint 7 — Audit / Compliance / Forensic Analytics  |
//|     MONITOR & REPORT ONLY — NEVER interrupts trading            |
//+------------------------------------------------------------------+
#ifndef GM_AUDIT_CONSTANTS_MQH
#define GM_AUDIT_CONSTANTS_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#define GM_EAC_VERSION              "1.0.0-enterprise-audit"
#define GM_EAC_DB_PREFIX            "GM_CLOUD_EAC_"
#define GM_EAC_THROTTLE_MS          18000
#define GM_EAC_EVENT_MAX            64
#define GM_EAC_HIST_MAX             48
#define GM_EAC_POLICY               "AUDIT & COMPLIANCE ONLY — NO TRADING AUTHORITY"
#define GM_EAC_SAFE                 "ASYNC FORENSIC — TRADING NEVER INTERRUPTED"

enum ENUM_GM_EAC_EVENT
  {
   GM_EAC_EVT_USER_LOGIN = 0,
   GM_EAC_EVT_USER_LOGOUT,
   GM_EAC_EVT_CONFIG_CHANGE,
   GM_EAC_EVT_LICENSE_CHANGE,
   GM_EAC_EVT_CLOUD_CONNECT,
   GM_EAC_EVT_CLOUD_DISCONNECT,
   GM_EAC_EVT_AI_ANALYSIS,
   GM_EAC_EVT_TRADE_LIFECYCLE,
   GM_EAC_EVT_RECOVERY,
   GM_EAC_EVT_SYSTEM_ERROR,
   GM_EAC_EVT_CRITICAL,
   GM_EAC_EVT_SYNC,
   GM_EAC_EVT_BACKUP,
   GM_EAC_EVT_NOTIFICATION,
   GM_EAC_EVT_SECURITY,
   GM_EAC_EVT_DASHBOARD,
   GM_EAC_EVT_SESSION
  };

enum ENUM_GM_EAC_SEVERITY
  {
   GM_EAC_SEV_INFO = 0,
   GM_EAC_SEV_WARN,
   GM_EAC_SEV_CRITICAL
  };

enum ENUM_GM_EAC_REPORT
  {
   GM_EAC_RPT_DAILY = 0,
   GM_EAC_RPT_WEEKLY,
   GM_EAC_RPT_MONTHLY,
   GM_EAC_RPT_SECURITY,
   GM_EAC_RPT_COMPLIANCE,
   GM_EAC_RPT_INTEGRITY,
   GM_EAC_RPT_PERFORMANCE,
   GM_EAC_RPT_EXECUTIVE
  };

enum ENUM_GM_EAC_ROLE
  {
   GM_EAC_ROLE_VIEWER = 0,
   GM_EAC_ROLE_AUDITOR,
   GM_EAC_ROLE_COMPLIANCE,
   GM_EAC_ROLE_ADMIN
  };

string GmEacEventName(const ENUM_GM_EAC_EVENT e)
  {
   switch(e)
     {
      case GM_EAC_EVT_USER_LOGIN:       return "User Login";
      case GM_EAC_EVT_USER_LOGOUT:      return "User Logout";
      case GM_EAC_EVT_CONFIG_CHANGE:    return "Configuration Change";
      case GM_EAC_EVT_LICENSE_CHANGE:   return "License Change";
      case GM_EAC_EVT_CLOUD_CONNECT:    return "Cloud Connection";
      case GM_EAC_EVT_CLOUD_DISCONNECT: return "Cloud Disconnection";
      case GM_EAC_EVT_AI_ANALYSIS:      return "AI Analysis Event";
      case GM_EAC_EVT_TRADE_LIFECYCLE:  return "Trade Lifecycle Event";
      case GM_EAC_EVT_RECOVERY:         return "Recovery Event";
      case GM_EAC_EVT_SYSTEM_ERROR:     return "System Error";
      case GM_EAC_EVT_CRITICAL:         return "Critical Event";
      case GM_EAC_EVT_SYNC:             return "Synchronization Event";
      case GM_EAC_EVT_BACKUP:           return "Backup Event";
      case GM_EAC_EVT_NOTIFICATION:     return "Notification Event";
      case GM_EAC_EVT_SECURITY:         return "Security Event";
      case GM_EAC_EVT_DASHBOARD:        return "Dashboard Activity";
      case GM_EAC_EVT_SESSION:          return "User Session";
     }
   return "Event";
  }

string GmEacSeverityName(const ENUM_GM_EAC_SEVERITY s)
  {
   switch(s)
     {
      case GM_EAC_SEV_WARN:     return "Warning";
      case GM_EAC_SEV_CRITICAL: return "Critical";
     }
   return "Info";
  }

string GmEacReportName(const ENUM_GM_EAC_REPORT r)
  {
   switch(r)
     {
      case GM_EAC_RPT_DAILY:       return "Daily Audit Report";
      case GM_EAC_RPT_WEEKLY:      return "Weekly Audit Report";
      case GM_EAC_RPT_MONTHLY:     return "Monthly Audit Report";
      case GM_EAC_RPT_SECURITY:    return "Security Report";
      case GM_EAC_RPT_COMPLIANCE:  return "Compliance Report";
      case GM_EAC_RPT_INTEGRITY:   return "Integrity Report";
      case GM_EAC_RPT_PERFORMANCE: return "Performance Audit";
      case GM_EAC_RPT_EXECUTIVE:   return "Executive Summary";
     }
   return "Audit Report";
  }

string GmEacRoleName(const ENUM_GM_EAC_ROLE r)
  {
   switch(r)
     {
      case GM_EAC_ROLE_AUDITOR:    return "Auditor";
      case GM_EAC_ROLE_COMPLIANCE: return "Compliance";
      case GM_EAC_ROLE_ADMIN:      return "Admin";
     }
   return "Viewer";
  }

#endif // GM_AUDIT_CONSTANTS_MQH
//+------------------------------------------------------------------+
