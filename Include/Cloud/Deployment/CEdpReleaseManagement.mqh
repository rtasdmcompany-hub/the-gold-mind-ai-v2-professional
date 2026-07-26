//+------------------------------------------------------------------+
//|                                   CEdpReleaseManagement.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CEDP_RELEASE_MANAGEMENT_MQH
#define GM_CEDP_RELEASE_MANAGEMENT_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "DeploymentConstants.mqh"
#include "SGmDeploymentResult.mqh"
#include "CEdpDeploymentSecurity.mqh"
#include "../../Core/Version.mqh"

class CGmEdpReleaseManagement
  {
private:
   CGmEdpDeploymentSecurity *m_sec;
   ENUM_GM_EDP_CHANNEL       m_channel;
   int                       m_current_build;
   int                       m_latest_build;
   string                    m_current_ver;
   string                    m_latest_ver;
   string                    m_notes;
   string                    m_approval;
   bool                      m_ready;

public:
                     CGmEdpReleaseManagement(void)
                       : m_sec(NULL), m_channel(GM_EDP_CH_STABLE),
                         m_current_build(0), m_latest_build(0),
                         m_current_ver(""), m_latest_ver(""),
                         m_notes(""), m_approval(""), m_ready(false) {}

   bool Init(CGmEdpDeploymentSecurity *sec)
     {
      m_sec = sec;
      m_channel = GM_EDP_CH_STABLE;
      m_current_build = GM_VERSION_BUILD;
      m_current_ver = GM_VERSION_STRING;
      // Architecture: next build available for promotion pipeline
      m_latest_build = GM_VERSION_BUILD + 1;
      m_latest_ver = StringFormat("%d.%d.%d",
                                  GM_VERSION_MAJOR, GM_VERSION_MINOR, GM_VERSION_PATCH);
      m_notes = StringFormat("Build %d → %d | Hotfix/Patch/Major/Beta channels ready | Phase6 Sprint9",
                             m_current_build, m_latest_build);
      if(m_sec != NULL)
        {
         const string rid = StringFormat("REL-%d", m_latest_build);
         const string appr = m_sec.PackageHash("rtas-release-board");
         m_approval = m_sec.ApproveRelease(rid, appr) ? "Approved (Architecture)" : "Pending";
        }
      else
         m_approval = "Pending";
      m_ready = true;
      return true;
     }

   ENUM_GM_EDP_CHANNEL Channel(void) const { return m_channel; }
   int CurrentBuild(void) const { return m_current_build; }
   int LatestBuild(void) const { return m_latest_build; }
   string CurrentVersion(void) const { return m_current_ver; }
   string LatestVersion(void) const { return m_latest_ver; }
   string Notes(void) const { return m_notes; }
   string Approval(void) const { return m_approval; }

   bool UpdateAvailable(void) const
     {
      return (m_latest_build > m_current_build);
     }

   double ReleaseReadiness(void) const
     {
      if(!m_ready) return 0.0;
      double s = 70.0;
      if(StringFind(m_approval, "Approved") >= 0) s += 20.0;
      if(UpdateAvailable()) s += 5.0;
      if(s > 100.0) s = 100.0;
      return s;
     }

   void ApplyTo(SGmDeploymentResult &out) const
     {
      if(!m_ready) return;
      out.channel = m_channel;
      out.current_build = m_current_build;
      out.latest_build = m_latest_build;
      out.current_version = m_current_ver + "." + IntegerToString(m_current_build);
      out.latest_version = m_latest_ver + "." + IntegerToString(m_latest_build);
      out.release_notes = m_notes;
      out.approval_status = m_approval;
      out.release_readiness = ReleaseReadiness();
     }
  };

#endif // GM_CEDP_RELEASE_MANAGEMENT_MQH
//+------------------------------------------------------------------+
