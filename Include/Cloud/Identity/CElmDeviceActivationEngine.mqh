//+------------------------------------------------------------------+
//|                                 CElmDeviceActivationEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CELM_DEVICE_ACTIVATION_ENGINE_MQH
#define GM_CELM_DEVICE_ACTIVATION_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "IdentityConstants.mqh"
#include "SGmIdentityResult.mqh"
#include "CElmIdentitySecurity.mqh"

struct SGmElmDeviceRec
  {
   string                  fingerprint;
   string                  name;
   ENUM_GM_ELM_DEVICE_ROLE role;
   datetime                registered_at;
   datetime                last_seen;
   bool                    trusted;
   bool                    revoked;

   void Reset(void)
     {
      fingerprint = name = "";
      role = GM_ELM_DEV_PENDING;
      registered_at = last_seen = 0;
      trusted = false;
      revoked = false;
     }
  };

class CGmElmDeviceActivationEngine
  {
private:
   CGmElmIdentitySecurity *m_sec;
   SGmElmDeviceRec         m_devices[GM_ELM_DEVICE_MAX];
   int                     m_n;
   int                     m_max_devices;
   string                  m_history;
   string                  m_current_fp;
   bool                    m_ready;

public:
                     CGmElmDeviceActivationEngine(void)
                       : m_sec(NULL), m_n(0), m_max_devices(3),
                         m_history(""), m_current_fp(""), m_ready(false) {}

   bool Init(CGmElmIdentitySecurity *sec, const int max_devices = 3)
     {
      m_sec = sec;
      m_max_devices = MathMax(1, MathMin(max_devices, GM_ELM_DEVICE_MAX));
      m_n = 0;
      m_history = "";
      m_ready = true;
      return true;
     }

   int Count(void) const { return m_n; }
   int MaxDevices(void) const { return m_max_devices; }
   string CurrentFp(void) const { return m_current_fp; }

   bool Register(const string name, const string fingerprint, const bool as_primary)
     {
      if(!m_ready || StringLen(fingerprint) < 8) return false;

      for(int i = 0; i < m_n; i++)
        {
         if(m_devices[i].fingerprint == fingerprint)
           {
            if(m_devices[i].revoked) return false;
            m_devices[i].last_seen = TimeCurrent();
            m_devices[i].trusted = true;
            m_current_fp = fingerprint;
            return true;
           }
        }

      int active = 0;
      for(int j = 0; j < m_n; j++)
         if(!m_devices[j].revoked) active++;
      if(active >= m_max_devices)
         return false;

      if(m_n >= GM_ELM_DEVICE_MAX) return false;

      SGmElmDeviceRec rec;
      rec.Reset();
      rec.fingerprint = fingerprint;
      rec.name = name;
      rec.role = as_primary ? GM_ELM_DEV_PRIMARY : GM_ELM_DEV_SECONDARY;
      rec.registered_at = TimeCurrent();
      rec.last_seen = rec.registered_at;
      rec.trusted = true;
      m_devices[m_n++] = rec;
      m_current_fp = fingerprint;
      m_history += TimeToString(rec.registered_at, TIME_DATE | TIME_SECONDS) +
                   " REGISTER " + name + " (" + GmElmDeviceRoleName(rec.role) + "); ";
      return true;
     }

   bool Revoke(const string fingerprint)
     {
      for(int i = 0; i < m_n; i++)
        {
         if(m_devices[i].fingerprint == fingerprint)
           {
            m_devices[i].revoked = true;
            m_devices[i].role = GM_ELM_DEV_REVOKED;
            m_devices[i].trusted = false;
            m_history += TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS) +
                         " REVOKE " + m_devices[i].name + "; ";
            return true;
           }
        }
      return false;
     }

   bool TransferPrimary(const string new_primary_fp)
     {
      int found = -1;
      for(int i = 0; i < m_n; i++)
        {
         if(m_devices[i].fingerprint == new_primary_fp && !m_devices[i].revoked)
            found = i;
         if(m_devices[i].role == GM_ELM_DEV_PRIMARY)
            m_devices[i].role = GM_ELM_DEV_SECONDARY;
        }
      if(found < 0) return false;
      m_devices[found].role = GM_ELM_DEV_PRIMARY;
      m_history += TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS) +
                   " TRANSFER primary->" + m_devices[found].name + "; ";
      return true;
     }

   void ApplyTo(SGmIdentityResult &out) const
     {
      if(!m_ready) return;
      int active = 0;
      string summary = "";
      string current_name = "—";
      for(int i = 0; i < m_n; i++)
        {
         if(m_devices[i].revoked) continue;
         active++;
         if(StringLen(summary) > 0) summary += " | ";
         summary += m_devices[i].name + "=" + GmElmDeviceRoleName(m_devices[i].role);
         if(m_devices[i].fingerprint == m_current_fp)
            current_name = m_devices[i].name;
        }
      out.activated_devices = active;
      out.max_devices = m_max_devices;
      out.current_device = current_name;
      out.device_manager_summary = summary;
      out.activation_history = (StringLen(m_history) > 0) ? m_history : "None";
     }
  };

#endif // GM_CELM_DEVICE_ACTIVATION_ENGINE_MQH
//+------------------------------------------------------------------+
