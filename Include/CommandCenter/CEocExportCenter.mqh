//+------------------------------------------------------------------+
//|                                        CEocExportCenter.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CEOC_EXPORT_CENTER_MQH
#define GM_CEOC_EXPORT_CENTER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmCommandCenterResult.mqh"
#include "../Core/CFileManager.mqh"
#include "../Logging/CLogger.mqh"

class CGmEocExportCenter
  {
private:
   CGmLogger      *m_logger;
   CGmFileManager *m_files;
   string          m_pfx;
   string          m_status;

public:
                     CGmEocExportCenter(void)
                       : m_logger(NULL), m_files(NULL), m_pfx(""), m_status("Idle") {}

   void Init(CGmLogger *logger, CGmFileManager *files, const string prefix)
     {
      m_logger = logger;
      m_files = files;
      m_pfx = prefix;
      m_status = "Architecture Ready | TXT/CSV stubs";
     }

   string Status(void) const { return m_status; }

   void Export(const SGmCommandCenterResult &r)
     {
      if(m_files == NULL || !r.valid) return;

      m_files.WriteText(m_pfx + "ops_room.txt", r.ops_room_summary);
      m_files.WriteText(m_pfx + "performance_wall.txt", r.performance_wall);
      m_files.WriteText(m_pfx + "alert_center.txt", r.alert_center);
      m_files.WriteText(m_pfx + "executive_summary.txt", r.executive_summary);
      m_files.WriteText(m_pfx + "availability_report.txt", r.availability_report);

      m_files.WriteText(m_pfx + "eoc_export.csv",
                        "Metric,Value\r\n" +
                        StringFormat("EnterpriseHealth,%.1f\r\nPerformance,%.1f\r\n"
                                     "Availability,%.1f\r\nInfra,%.1f\r\nAlerts,%d\r\n",
                                     r.enterprise_health, r.overall_performance,
                                     r.system_availability, r.infrastructure_health,
                                     r.alert_count));

      m_status = "TXT/CSV Exported";
     }
  };

#endif // GM_CEOC_EXPORT_CENTER_MQH
//+------------------------------------------------------------------+
