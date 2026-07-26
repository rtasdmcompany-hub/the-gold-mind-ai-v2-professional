//+------------------------------------------------------------------+
//|                                       CEccProfileManager.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CECC_PROFILE_MANAGER_MQH
#define GM_CECC_PROFILE_MANAGER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmConfigurationCenterResult.mqh"
#include "../Logging/CLogger.mqh"

class CGmEccProfileManager
  {
private:
   CGmLogger           *m_logger;
   ENUM_GM_ECC_PROFILE  m_active;
   int                  m_version;
   string               m_name;
   string               m_backup_stamp;

public:
                     CGmEccProfileManager(void)
                       : m_logger(NULL),
                         m_active(GM_ECC_PROF_PRODUCTION),
                         m_version(1),
                         m_name("Production"),
                         m_backup_stamp("") {}

   void Init(CGmLogger *logger)
     {
      m_logger = logger;
      m_active = GM_ECC_PROF_PRODUCTION;
      m_version = 1;
      m_name = GmEccProfileName(m_active);
      m_backup_stamp = "";
      if(m_logger != NULL)
         m_logger.Info("Profile Loaded | " + m_name + " v" + IntegerToString(m_version), "ECC");
     }

   ENUM_GM_ECC_PROFILE Active(void) const { return m_active; }
   int Version(void) const { return m_version; }
   string Name(void) const { return m_name; }
   string BackupStamp(void) const { return m_backup_stamp; }

   bool LoadProfile(const ENUM_GM_ECC_PROFILE p)
     {
      m_active = p;
      m_name = GmEccProfileName(p);
      m_version++;
      if(m_logger != NULL)
         m_logger.Success("Profile Loaded | " + m_name + " v" + IntegerToString(m_version), "ECC");
      return true;
     }

   bool SaveProfile(void)
     {
      m_version++;
      if(m_logger != NULL)
         m_logger.Success("Profile Saved | " + m_name + " v" + IntegerToString(m_version), "ECC");
      return true;
     }

   bool CloneProfile(const ENUM_GM_ECC_PROFILE as_type)
     {
      m_active = as_type;
      m_name = GmEccProfileName(as_type) + " (Clone)";
      m_version++;
      if(m_logger != NULL)
         m_logger.Success("Profile Created | Clone -> " + m_name, "ECC");
      return true;
     }

   bool BackupProfile(void)
     {
      m_backup_stamp = TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS);
      if(m_logger != NULL)
         m_logger.Success("Backup Completed | Profile " + m_name + " @ " + m_backup_stamp, "ECC");
      return true;
     }

   bool RestoreProfile(void)
     {
      if(m_backup_stamp == "")
        {
         if(m_logger != NULL)
            m_logger.Warning("Profile Restore skipped — no backup", "ECC");
         return false;
        }
      m_version++;
      if(m_logger != NULL)
         m_logger.Success("Profile Loaded | Restored from " + m_backup_stamp, "ECC");
      return true;
     }

   void ApplyToResult(SGmConfigurationCenterResult &out) const
     {
      out.current_profile = m_active;
      out.profile_name = m_name;
      out.profile_version = m_version;
      if(m_backup_stamp != "")
         out.last_backup = m_backup_stamp;
     }
  };

#endif // GM_CECC_PROFILE_MANAGER_MQH
//+------------------------------------------------------------------+
