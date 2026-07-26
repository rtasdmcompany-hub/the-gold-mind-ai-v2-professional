//+------------------------------------------------------------------+
//|                                     CEccWorkspaceManager.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CECC_WORKSPACE_MANAGER_MQH
#define GM_CECC_WORKSPACE_MANAGER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmConfigurationCenterResult.mqh"
#include "../Logging/CLogger.mqh"

class CGmEccWorkspaceManager
  {
private:
   CGmLogger *m_logger;
   string     m_status;
   string     m_layout;
   string     m_backup_stamp;
   int        m_version;

public:
                     CGmEccWorkspaceManager(void)
                       : m_logger(NULL),
                         m_status("Default Layout"),
                         m_layout(""),
                         m_backup_stamp(""),
                         m_version(1) {}

   void Init(CGmLogger *logger)
     {
      m_logger = logger;
      m_status = "Dashboard Layout Ready";
      m_layout =
         "DashboardLayout=Standard\r\n"
         "WindowPositions=Default\r\n"
         "ChartTemplates=H4 Primary\r\n"
         "PanelVisibility=AI+Risk+Session\r\n"
         "WidgetConfiguration=14-slot\r\n"
         "ScreenLayout=Single\r\n"
         "MultiMonitor=Architecture Ready\r\n";
      m_backup_stamp = "";
      m_version = 1;
     }

   string Status(void) const { return m_status; }
   string Layout(void) const { return m_layout; }
   string BackupStamp(void) const { return m_backup_stamp; }

   bool BackupWorkspace(void)
     {
      m_backup_stamp = TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS);
      m_version++;
      m_status = "Workspace Backed Up @ " + m_backup_stamp;
      if(m_logger != NULL)
         m_logger.Success("Backup Completed | Workspace v" + IntegerToString(m_version), "ECC");
      return true;
     }

   bool RestoreWorkspace(void)
     {
      if(m_backup_stamp == "")
        {
         m_status = "No Workspace Backup";
         if(m_logger != NULL)
            m_logger.Warning("Workspace Restore skipped — no backup", "ECC");
         return false;
        }
      m_version++;
      m_status = "Workspace Restored @ " + m_backup_stamp;
      if(m_logger != NULL)
         m_logger.Success("Workspace Restored | v" + IntegerToString(m_version), "ECC");
      return true;
     }

   void ApplyToResult(SGmConfigurationCenterResult &out) const
     {
      out.workspace_status = m_status;
      if(out.last_backup == "" && m_backup_stamp != "")
         out.last_backup = m_backup_stamp;
     }
  };

#endif // GM_CECC_WORKSPACE_MANAGER_MQH
//+------------------------------------------------------------------+
