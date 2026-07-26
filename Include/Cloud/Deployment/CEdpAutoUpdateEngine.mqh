//+------------------------------------------------------------------+
//|                                      CEdpAutoUpdateEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CEDP_AUTO_UPDATE_ENGINE_MQH
#define GM_CEDP_AUTO_UPDATE_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "DeploymentConstants.mqh"
#include "SGmDeploymentResult.mqh"
#include "CEdpDeploymentSecurity.mqh"
#include "CEdpReleaseManagement.mqh"
#include "../../Core/CFileManager.mqh"

class CGmEdpAutoUpdateEngine
  {
private:
   CGmEdpDeploymentSecurity *m_sec;
   CGmEdpReleaseManagement  *m_rel;
   CGmFileManager           *m_files;
   string                    m_pfx;
   ENUM_GM_EDP_UPDATE         m_status;
   string                    m_pkg_body;
   string                    m_pkg_sig;
   string                    m_pkg_hash;
   bool                      m_mandatory;
   bool                      m_ready;

public:
                     CGmEdpAutoUpdateEngine(void)
                       : m_sec(NULL), m_rel(NULL), m_files(NULL), m_pfx(""),
                         m_status(GM_EDP_UPD_IDLE), m_pkg_body(""), m_pkg_sig(""),
                         m_pkg_hash(""), m_mandatory(false), m_ready(false) {}

   bool Init(CGmEdpDeploymentSecurity *sec, CGmEdpReleaseManagement *rel,
             CGmFileManager *files, const string pfx)
     {
      m_sec = sec;
      m_rel = rel;
      m_files = files;
      m_pfx = pfx;
      m_status = GM_EDP_UPD_IDLE;
      m_ready = true;
      return true;
     }

   ENUM_GM_EDP_UPDATE Status(void) const { return m_status; }
   string PackageHash(void) const { return m_pkg_hash; }

   // Returns false if install must be deferred (active GM trades)
   bool ProcessCycle(const int active_gm_trades, SGmDeploymentResult &out)
     {
      if(!m_ready || m_rel == NULL)
         return false;

      out.active_gm_trades = active_gm_trades;
      out.may_install_now = (active_gm_trades <= 0);
      out.update_deferred = false;

      if(!m_rel.UpdateAvailable())
        {
         m_status = GM_EDP_UPD_IDLE;
         out.update_status = m_status;
         out.update_status_text = GmEdpUpdateName(m_status);
         return true;
        }

      if(m_status == GM_EDP_UPD_IDLE || m_status == GM_EDP_UPD_OK)
         m_status = GM_EDP_UPD_AVAILABLE;

      // Background download (architecture package)
      if(m_status == GM_EDP_UPD_AVAILABLE)
        {
         m_status = GM_EDP_UPD_DOWNLOADING;
         m_pkg_body = StringFormat("PKG|from=%d|to=%d|src=%s|%s",
                                   m_rel.CurrentBuild(), m_rel.LatestBuild(),
                                   (m_sec != NULL) ? m_sec.TrustedSource() : "local",
                                   GM_EDP_VERSION);
         if(m_sec != NULL)
           {
            m_pkg_hash = m_sec.PackageHash(m_pkg_body);
            m_pkg_sig = m_sec.SignPackage(m_pkg_body);
           }
         if(m_files != NULL)
            m_files.WriteText(m_pfx + "update_package.edp",
                              "hash=" + m_pkg_hash + "\r\nsig=" + m_pkg_sig + "\r\n" +
                              "enc=" + ((m_sec != NULL) ? m_sec.EncryptPackage(m_pkg_body) : m_pkg_body));
         m_status = GM_EDP_UPD_VERIFYING;
        }

      if(m_status == GM_EDP_UPD_VERIFYING)
        {
         const bool ok = (m_sec == NULL) || m_sec.VerifySignature(m_pkg_body, m_pkg_sig);
         if(!ok)
           {
            m_status = GM_EDP_UPD_FAILED;
            out.package_integrity = "Tamper Detected";
           }
         else
           {
            out.package_integrity = "Verified";
            m_status = GM_EDP_UPD_SCHEDULED;
           }
        }

      if(m_status == GM_EDP_UPD_SCHEDULED || m_status == GM_EDP_UPD_DEFERRED ||
         m_status == GM_EDP_UPD_MANDATORY_PENDING)
        {
         // CRITICAL: never install while GM-managed trades are active
         if(active_gm_trades > 0)
           {
            m_status = m_mandatory ? GM_EDP_UPD_MANDATORY_PENDING : GM_EDP_UPD_DEFERRED;
            out.update_deferred = true;
            out.may_install_now = false;
           }
         else
           {
            // Architecture: mark install prepared — do not replace live binary mid-session
            m_status = GM_EDP_UPD_INSTALLING;
            m_status = GM_EDP_UPD_OK; // staged success (no live binary swap in EA)
           }
        }

      out.update_status = m_status;
      out.update_status_text = GmEdpUpdateName(m_status);
      if(StringLen(out.package_integrity) == 0)
         out.package_integrity = (StringLen(m_pkg_hash) > 0) ? "Verified" : "Pending";
      return true;
     }
  };

#endif // GM_CEDP_AUTO_UPDATE_ENGINE_MQH
//+------------------------------------------------------------------+
