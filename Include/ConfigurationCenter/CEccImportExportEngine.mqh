//+------------------------------------------------------------------+
//|                                    CEccImportExportEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CECC_IMPORT_EXPORT_ENGINE_MQH
#define GM_CECC_IMPORT_EXPORT_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmConfigurationCenterResult.mqh"
#include "../Core/CFileManager.mqh"
#include "../Logging/CLogger.mqh"

class CGmEccImportExportEngine
  {
private:
   CGmLogger      *m_logger;
   CGmFileManager *m_files;
   string          m_pfx;
   string          m_import_status;
   string          m_export_status;

public:
                     CGmEccImportExportEngine(void)
                       : m_logger(NULL), m_files(NULL), m_pfx(""),
                         m_import_status("Idle"), m_export_status("Idle") {}

   void Init(CGmLogger *logger, CGmFileManager *files, const string prefix)
     {
      m_logger = logger;
      m_files = files;
      m_pfx = prefix;
      m_import_status = "Ready";
      m_export_status = "Architecture Ready | Config/Profile/Template/Workspace";
     }

   string ImportStatus(void) const { return m_import_status; }
   string ExportStatus(void) const { return m_export_status; }

   void ExportAll(const SGmConfigurationCenterResult &r)
     {
      if(m_files == NULL || !r.valid) return;

      m_files.WriteText(m_pfx + "configuration_export.txt", r.config_summary);
      m_files.WriteText(m_pfx + "profile_export.txt",
                        StringFormat("Profile=%s\r\nVersion=%d\r\n", r.profile_name, r.profile_version));
      m_files.WriteText(m_pfx + "template_export.txt",
                        StringFormat("Template=%s\r\nVersion=%d\r\nLocked=%s\r\n",
                                     r.template_name, r.template_version,
                                     r.template_locked ? "YES" : "NO"));
      m_files.WriteText(m_pfx + "workspace_export.txt", r.workspace_status + "\r\n");
      m_files.WriteText(m_pfx + "encrypted_backup_package.arch.txt",
                        "Encrypted Backup Package — architecture reserved\r\n");

      m_export_status = "Config/Profile/Template/Workspace Exported | Encrypted Package ARCH";
      if(m_logger != NULL)
         m_logger.Info("Template Exported | " + m_export_status, "ECC");
     }

   void MarkImportVerified(void)
     {
      m_import_status = "Import Verified";
      if(m_logger != NULL)
         m_logger.Info("Template Imported | verification OK", "ECC");
     }

   void ApplyToResult(SGmConfigurationCenterResult &out) const
     {
      out.import_status = m_import_status;
      out.export_status = m_export_status;
     }
  };

#endif // GM_CECC_IMPORT_EXPORT_ENGINE_MQH
//+------------------------------------------------------------------+
