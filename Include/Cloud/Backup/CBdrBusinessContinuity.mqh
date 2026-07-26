//+------------------------------------------------------------------+
//|                                 CBdrBusinessContinuity.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CBDR_BUSINESS_CONTINUITY_MQH
#define GM_CBDR_BUSINESS_CONTINUITY_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "BackupConstants.mqh"
#include "SGmBackupResult.mqh"
#include "../SGmCloudStatus.mqh"
#include "../RemoteMonitor/SGmRemoteMonitorResult.mqh"
#include "../Notifications/SGmNotificationCenterResult.mqh"
#include "../Identity/SGmIdentityResult.mqh"

class CGmBdrBusinessContinuity
  {
private:
   bool m_ready;

   double ScoreAvail(const bool ok, const double soft) const
     {
      return ok ? soft : MathMax(40.0, soft * 0.5);
     }

public:
                     CGmBdrBusinessContinuity(void) : m_ready(false) {}

   bool Init(void)
     {
      m_ready = true;
      return true;
     }

   void Measure(const SGmCloudStatus &cloud,
                const SGmRemoteMonitorResult &rm,
                const SGmNotificationCenterResult &ntf,
                const SGmIdentityResult &id,
                const double backup_health,
                const double recovery_readiness,
                SGmBackupResult &out) const
     {
      if(!m_ready) return;

      const bool cloud_ok = (cloud.valid && cloud.cloud_status == GM_CLOUD_STATUS_ONLINE);
      const bool db_ok = rm.valid ? (rm.database_health >= 50.0) : true;
      const bool ai_ok = rm.valid ? (StringFind(rm.ai_status, "—") < 0) : true;
      const bool sync_ok = cloud.valid ? (cloud.sync_queue_depth < 20) : true;
      const bool ntf_ok = ntf.valid ? (ntf.failed_count <= ntf.delivered_count + 5) : true;
      const bool lic_ok = id.valid ? (id.trading_allowed_by_grace || id.license_health >= 40.0) : true;
      const bool recovery_ok = (recovery_readiness >= 50.0);

      const double s_sys = 95.0; // local EA always available for continuity scoring
      const double s_cloud = ScoreAvail(cloud_ok, cloud_ok ? 95.0 : 55.0);
      const double s_db = ScoreAvail(db_ok, rm.valid ? rm.database_health : 80.0);
      const double s_ai = ScoreAvail(ai_ok, 85.0);
      const double s_sync = ScoreAvail(sync_ok, 80.0);
      const double s_ntf = ScoreAvail(ntf_ok, 80.0);
      const double s_lic = ScoreAvail(lic_ok, id.valid ? id.license_health : 75.0);
      const double s_rec = ScoreAvail(recovery_ok, recovery_readiness);

      out.system_availability = (s_sys + s_cloud + s_db + s_ai) * 0.25;
      out.business_continuity = (out.system_availability + backup_health + s_rec +
                                 s_sync + s_ntf + s_lic) / 6.0;

      out.availability_report = StringFormat(
         "Sys=%.0f Cloud=%.0f DB=%.0f AI=%.0f Sync=%.0f Ntf=%.0f Lic=%.0f Rec=%.0f | BC=%.0f",
         s_sys, s_cloud, s_db, s_ai, s_sync, s_ntf, s_lic, s_rec, out.business_continuity);
     }
  };

#endif // GM_CBDR_BUSINESS_CONTINUITY_MQH
//+------------------------------------------------------------------+
