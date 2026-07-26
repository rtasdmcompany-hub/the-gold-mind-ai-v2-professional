//+------------------------------------------------------------------+
//|                                          CBdrPolicyManager.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CBDR_POLICY_MANAGER_MQH
#define GM_CBDR_POLICY_MANAGER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "BackupConstants.mqh"

class CGmBdrPolicyManager
  {
private:
   ENUM_GM_BDR_POLICY  m_policy;
   ENUM_GM_BDR_STORAGE m_storage;
   int                 m_retention_days;
   int                 m_rotation_keep;
   bool                m_archive;
   bool                m_ready;

public:
                     CGmBdrPolicyManager(void)
                       : m_policy(GM_BDR_POL_DAILY),
                         m_storage(GM_BDR_STORE_HYBRID),
                         m_retention_days(GM_BDR_RETENTION_DEFAULT),
                         m_rotation_keep(7),
                         m_archive(true),
                         m_ready(false) {}

   bool Init(const ENUM_GM_BDR_POLICY policy = GM_BDR_POL_DAILY)
     {
      m_policy = policy;
      m_storage = GM_BDR_STORE_HYBRID;
      m_retention_days = GM_BDR_RETENTION_DEFAULT;
      m_rotation_keep = 7;
      m_archive = true;
      m_ready = true;
      return true;
     }

   void SetPolicy(const ENUM_GM_BDR_POLICY p) { m_policy = p; }
   void SetStorage(const ENUM_GM_BDR_STORAGE s) { m_storage = s; }
   void SetRetention(const int days) { m_retention_days = MathMax(1, days); }

   ENUM_GM_BDR_POLICY Policy(void) const { return m_policy; }
   ENUM_GM_BDR_STORAGE Storage(void) const { return m_storage; }
   int RetentionDays(void) const { return m_retention_days; }

   int IntervalSeconds(void) const
     {
      if(m_policy == GM_BDR_POL_WEEKLY) return 7 * 86400;
      if(m_policy == GM_BDR_POL_MONTHLY) return 30 * 86400;
      if(m_policy == GM_BDR_POL_ON_DEMAND) return 0;
      return 86400; // daily / hybrid
     }

   datetime NextBackupAfter(const datetime last) const
     {
      const int iv = IntervalSeconds();
      if(iv <= 0) return 0;
      if(last <= 0) return TimeCurrent() + 60;
      return last + iv;
     }

   string Summary(void) const
     {
      return StringFormat("%s | Retention=%dd | Rotate=%d | Archive=%s | Store=%s",
                          GmBdrPolicyName(m_policy), m_retention_days, m_rotation_keep,
                          m_archive ? "yes" : "no", GmBdrStorageName(m_storage));
     }

   bool Due(const datetime last) const
     {
      if(!m_ready) return false;
      if(m_policy == GM_BDR_POL_ON_DEMAND) return false;
      const datetime next = NextBackupAfter(last);
      return (next > 0 && TimeCurrent() >= next);
     }
  };

#endif // GM_CBDR_POLICY_MANAGER_MQH
//+------------------------------------------------------------------+
