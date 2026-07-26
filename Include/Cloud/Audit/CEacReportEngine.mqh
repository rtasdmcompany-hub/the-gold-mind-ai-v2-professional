//+------------------------------------------------------------------+
//|                                           CEacReportEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CEAC_REPORT_ENGINE_MQH
#define GM_CEAC_REPORT_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "AuditConstants.mqh"
#include "SGmAuditResult.mqh"
#include "CEacAuditSecurity.mqh"
#include "CEacForensicLogging.mqh"
#include "../../Core/CFileManager.mqh"
#include "../../Core/Version.mqh"

class CGmEacReportEngine
  {
private:
   CGmEacAuditSecurity   *m_sec;
   CGmFileManager        *m_files;
   string                 m_pfx;
   int                    m_generated;
   int                    m_exported;
   string                 m_last_export;
   bool                   m_ready;

   string BuildReport(const ENUM_GM_EAC_REPORT type, const SGmAuditResult &r) const
     {
      string body = "=== " + GmEacReportName(type) + " ===\r\n";
      body += "Product: " + GM_PRODUCT_NAME + "\r\n";
      body += "Build: " + IntegerToString(GM_VERSION_BUILD) + "\r\n";
      body += "Generated: " + TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS) + "\r\n";
      body += "Session: " + r.session_id + "\r\n";
      body += "Audit Health: " + DoubleToString(r.audit_health, 1) + "\r\n";
      body += "Compliance Score: " + DoubleToString(r.compliance_score, 1) + "\r\n";
      body += "Integrity Rating: " + DoubleToString(r.integrity_rating, 1) + "\r\n";
      body += "Trust Score: " + DoubleToString(r.trust_score, 1) + "\r\n";
      body += "Critical Events: " + r.critical_events + "\r\n";
      body += "Timeline: " + r.audit_timeline + "\r\n";
      if(type == GM_EAC_RPT_COMPLIANCE || type == GM_EAC_RPT_EXECUTIVE)
         body += r.compliance_report + "\r\n";
      if(type == GM_EAC_RPT_INTEGRITY || type == GM_EAC_RPT_EXECUTIVE)
         body += r.integrity_report + "\r\n";
      if(type == GM_EAC_RPT_SECURITY || type == GM_EAC_RPT_EXECUTIVE)
         body += "Security: " + r.security_status + "\r\n";
      if(type == GM_EAC_RPT_PERFORMANCE)
         body += "Performance: background audit only — trading uninterrupted\r\n";
      body += "POLICY: " + GM_EAC_POLICY + "\r\n";
      return body;
     }

public:
                     CGmEacReportEngine(void)
                       : m_sec(NULL), m_files(NULL), m_pfx(""),
                         m_generated(0), m_exported(0), m_last_export(""),
                         m_ready(false) {}

   bool Init(CGmEacAuditSecurity *sec, CGmFileManager *files, const string pfx)
     {
      m_sec = sec;
      m_files = files;
      m_pfx = pfx;
      m_ready = true;
      return true;
     }

   int Generated(void) const { return m_generated; }
   int Exported(void) const { return m_exported; }

   bool GenerateAndExport(const ENUM_GM_EAC_REPORT type,
                          SGmAuditResult &r,
                          CGmEacForensicLogging &forensic)
     {
      if(!m_ready) return false;
      if(m_sec != NULL && !m_sec.CanExport())
        {
         r.export_status = "Denied by RBAC";
         return false;
        }

      string body = BuildReport(type, r);
      body += forensic.ExportBody();
      m_generated++;

      string sig = "";
      string enc = body;
      if(m_sec != NULL)
        {
         sig = m_sec.SignEntry(body);
         enc = m_sec.EncryptAudit(body);
         if(StringLen(sig) < 8)
           {
            r.export_status = "Export validation failed";
            return false;
           }
        }

      if(m_files != NULL)
        {
         const string name = StringFormat("%sreport_%s_%I64d.txt",
                                          m_pfx,
                                          IntegerToString((int)type),
                                          (long)TimeCurrent());
         m_files.WriteText(name,
                           "=== export_ready ===\r\n" +
                           "sig=" + sig + "\r\n" +
                           "payload=\r\n" + (StringLen(enc) > 0 ? enc : body) + "\r\n");
         m_last_export = name;
         m_exported++;
        }

      r.report_status = GmEacReportName(type) + " Generated";
      r.export_status = "Exported: " + m_last_export;
      r.reports_generated = m_generated;
      r.exports_done = m_exported;
      r.security_report = "Security Validation Completed | " + r.security_status;
      r.executive_summary = StringFormat(
         "Executive: Trust=%.0f Compliance=%.0f Integrity=%.0f Audit=%.0f | Critical=%d",
         r.trust_score, r.compliance_score, r.integrity_rating, r.audit_health, r.critical_count);
      return true;
     }
  };

#endif // GM_CEAC_REPORT_ENGINE_MQH
//+------------------------------------------------------------------+
