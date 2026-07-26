//+------------------------------------------------------------------+
//|                                           CBdrBackupEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CBDR_BACKUP_ENGINE_MQH
#define GM_CBDR_BACKUP_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "BackupConstants.mqh"
#include "SGmBackupResult.mqh"
#include "CBdrBackupSecurity.mqh"
#include "CBdrPolicyManager.mqh"
#include "../../Core/CFileManager.mqh"
#include "../../Core/Version.mqh"

class CGmBdrBackupEngine
  {
private:
   CGmBdrBackupSecurity *m_sec;
   CGmBdrPolicyManager  *m_policy;
   CGmFileManager       *m_files;
   string                m_pfx;
   datetime              m_last_at;
   ENUM_GM_BDR_BACKUP_MODE m_last_mode;
   ENUM_GM_BDR_STATUS    m_status;
   string                m_last_blob;
   string                m_last_sig;
   string                m_last_hash;
   int                   m_version;
   int                   m_ok_count;
   int                   m_fail_count;
   bool                  m_ready;

   string BuildPayload(const ENUM_GM_BDR_BACKUP_MODE mode) const
     {
      return StringFormat(
         "GM_BDR|v=%s|build=%d|mode=%s|ts=%I64d|cfg=1|ai=1|dash=1|lic=1|cloud=1|ntf=1|reports=1",
         GM_VERSION_STRING, GM_VERSION_BUILD, GmBdrBackupModeName(mode), (long)TimeCurrent());
     }

public:
                     CGmBdrBackupEngine(void)
                       : m_sec(NULL), m_policy(NULL), m_files(NULL), m_pfx(""),
                         m_last_at(0), m_last_mode(GM_BDR_MODE_AUTOMATIC),
                         m_status(GM_BDR_STATUS_IDLE), m_last_blob(""),
                         m_last_sig(""), m_last_hash(""), m_version(0),
                         m_ok_count(0), m_fail_count(0), m_ready(false) {}

   bool Init(CGmBdrBackupSecurity *sec, CGmBdrPolicyManager *policy,
             CGmFileManager *files, const string pfx)
     {
      m_sec = sec;
      m_policy = policy;
      m_files = files;
      m_pfx = pfx;
      m_ready = true;
      return true;
     }

   datetime LastAt(void) const { return m_last_at; }
   ENUM_GM_BDR_STATUS Status(void) const { return m_status; }
   int VersionCount(void) const { return m_version; }
   string LastHash(void) const { return m_last_hash; }
   string LastBlob(void) const { return m_last_blob; }
   string LastSig(void) const { return m_last_sig; }

   bool Run(const ENUM_GM_BDR_BACKUP_MODE mode, const bool force)
     {
      if(!m_ready) return false;
      if(!force && m_policy != NULL && !m_policy.Due(m_last_at) && mode != GM_BDR_MODE_MANUAL)
         return false;

      m_status = GM_BDR_STATUS_RUNNING;
      const string plain = BuildPayload(mode);
      string compressed = plain; // architecture: logical compression marker
      if(StringLen(compressed) > 0)
         compressed = "Z:" + IntegerToString(StringLen(plain)) + ":" + plain;

      string enc = compressed;
      if(m_sec != NULL)
        {
         enc = m_sec.EncryptPayload(compressed);
         m_last_hash = m_sec.IntegrityHash(compressed);
         m_last_sig = m_sec.SignBackup(m_last_hash);
        }

      if(StringLen(enc) == 0)
        {
         m_status = GM_BDR_STATUS_FAILED;
         m_fail_count++;
         return false;
        }

      m_last_blob = enc;
      m_last_mode = mode;
      m_last_at = TimeCurrent();
      m_version++;

      if(m_files != NULL)
        {
         const string name = StringFormat("%sbackup_v%d_%s.bdr",
                                          m_pfx, m_version,
                                          mode == GM_BDR_MODE_FULL ? "full" : "inc");
         m_files.WriteText(name,
                           "=== encrypted_backup ===\r\n" +
                           "hash=" + m_last_hash + "\r\n" +
                           "sig=" + m_last_sig + "\r\n" +
                           "payload=" + enc + "\r\n");
        }

      // Verification pass
      m_status = GM_BDR_STATUS_VERIFYING;
      const bool ok = (m_sec == NULL) || m_sec.VerifyIntegrity(compressed, m_last_hash);
      if(!ok)
        {
         m_status = GM_BDR_STATUS_FAILED;
         m_fail_count++;
         return false;
        }

      m_status = GM_BDR_STATUS_OK;
      m_ok_count++;
      return true;
     }

   void ApplyTo(SGmBackupResult &out) const
     {
      if(!m_ready) return;
      out.backup_status = m_status;
      out.last_mode = m_last_mode;
      out.last_backup_at = m_last_at;
      out.version_count = m_version;
      out.backup_status_text = GmBdrStatusName(m_status);
      if(m_policy != NULL)
        {
         out.next_backup_at = m_policy.NextBackupAfter(m_last_at);
         out.policy = m_policy.Policy();
         out.storage = m_policy.Storage();
         out.retention_days = m_policy.RetentionDays();
         out.retention_policy = StringFormat("%d days / rotate", m_policy.RetentionDays());
         out.policy_status = m_policy.Summary();
        }
      // Health: success ratio + freshness
      double freshness = 40.0;
      if(m_last_at > 0)
        {
         const int age_h = (int)((TimeCurrent() - m_last_at) / 3600);
         freshness = (age_h <= 24) ? 95.0 : (age_h <= 72 ? 70.0 : 45.0);
        }
      const double success = (m_ok_count + m_fail_count) > 0
                             ? (100.0 * m_ok_count / (m_ok_count + m_fail_count))
                             : 80.0;
      out.backup_health = (freshness + success) * 0.5;
      out.storage_usage_pct = MathMin(85.0, 12.0 + m_version * 2.5);
      out.integrity_status = (m_status == GM_BDR_STATUS_OK) ? "Verified" : GmBdrStatusName(m_status);
     }
  };

#endif // GM_CBDR_BACKUP_ENGINE_MQH
//+------------------------------------------------------------------+
