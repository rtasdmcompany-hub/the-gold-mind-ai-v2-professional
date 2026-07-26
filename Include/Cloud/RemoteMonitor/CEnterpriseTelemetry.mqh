//+------------------------------------------------------------------+
//|                                   CEnterpriseTelemetry.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CENTERPRISE_TELEMETRY_MQH
#define GM_CENTERPRISE_TELEMETRY_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmRemoteMonitorResult.mqh"
#include "../CCloudSecurity.mqh"

class CGmEnterpriseTelemetry
  {
private:
   CGmCloudSecurity *m_sec;
   int               m_samples;
   string            m_last_payload_hash;
   bool              m_ready;

public:
                     CGmEnterpriseTelemetry(void)
                       : m_sec(NULL), m_samples(0), m_last_payload_hash(""), m_ready(false) {}

   bool Init(CGmCloudSecurity *sec)
     {
      m_sec = sec;
      m_samples = 0;
      m_ready = (m_sec != NULL && m_sec.IsReady());
      return m_ready;
     }

   int Samples(void) const { return m_samples; }
   string LastHash(void) const { return m_last_payload_hash; }

   void Collect(SGmRemoteMonitorResult &r)
     {
      if(!m_ready || m_sec == NULL)
        {
         r.telemetry_status = "Unavailable";
         return;
        }

      const string plain = StringFormat(
         "cpu=%.1f|ram=%.1f|health=%.1f|lat=%.0f|net=%.0f|stab=%.0f|tick=%.0f|ai=%.0f|t=%I64d",
         r.cpu_usage_pct, r.ram_usage_pct, r.overall_health_score,
         r.cloud_latency_ms, r.network_quality, r.system_stability,
         r.tick_processing_score, r.ai_processing_score, (long)TimeCurrent());

      const string enc = m_sec.EncryptToBase64(plain);
      m_last_payload_hash = m_sec.HashHex(enc);
      m_samples++;
      r.telemetry_samples = m_samples;
      r.encrypted_telemetry_hash = m_last_payload_hash;
      r.telemetry_status = "Secure Capture OK";
     }
  };

#endif // GM_CENTERPRISE_TELEMETRY_MQH
//+------------------------------------------------------------------+
