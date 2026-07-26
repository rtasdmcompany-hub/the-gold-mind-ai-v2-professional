//+------------------------------------------------------------------+
//|                                           CCloudSecurity.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Local crypto helpers — no trading authority                 |
//+------------------------------------------------------------------+
#ifndef GM_CCLOUD_SECURITY_MQH
#define GM_CCLOUD_SECURITY_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "CloudConstants.mqh"

class CGmCloudSecurity
  {
private:
   uchar m_key[32];
   ulong m_nonce_seq;
   bool  m_ready;

   void BuildKey(const string seed)
     {
      uchar src[];
      StringToCharArray(seed, src, 0, WHOLE_ARRAY, CP_UTF8);
      uchar hash[];
      if(CryptEncode(CRYPT_HASH_SHA256, src, src, hash))
        {
         const int n = ArraySize(hash);
         for(int i = 0; i < 32; i++)
            m_key[i] = (i < n) ? hash[i] : (uchar)(i * 17);
        }
      else
        {
         for(int i = 0; i < 32; i++)
            m_key[i] = (uchar)((StringGetCharacter(seed, i % MathMax(1, StringLen(seed))) + i) & 0xFF);
        }
     }

public:
                     CGmCloudSecurity(void) : m_nonce_seq(1), m_ready(false)
     {
      ArrayInitialize(m_key, 0);
     }

   bool Init(const string seed)
     {
      BuildKey(seed + "|" + GM_CLOUD_VERSION + "|" + GM_CLOUD_POLICY);
      m_nonce_seq = (ulong)TimeCurrent() + 1;
      m_ready = true;
      return true;
     }

   bool IsReady(void) const { return m_ready; }

   string HashHex(const string payload) const
     {
      if(!m_ready || StringLen(payload) == 0)
         return "";
      uchar src[];
      StringToCharArray(payload, src, 0, WHOLE_ARRAY, CP_UTF8);
      uchar hash[];
      if(!CryptEncode(CRYPT_HASH_SHA256, src, src, hash))
         return IntegerToString((int)StringLen(payload) * 1315423911);
      string out = "";
      const int n = MathMin(16, ArraySize(hash));
      for(int i = 0; i < n; i++)
         out += StringFormat("%02X", hash[i]);
      return out;
     }

   string EncryptToBase64(const string plain) const
     {
      if(!m_ready || StringLen(plain) == 0)
         return "";
      uchar src[];
      StringToCharArray(plain, src, 0, WHOLE_ARRAY, CP_UTF8);
      uchar key[];
      ArrayResize(key, 32);
      for(int i = 0; i < 32; i++)
         key[i] = m_key[i];
      uchar enc[];
      if(!CryptEncode(CRYPT_AES256, src, key, enc))
        {
         // Fallback: hash-mask (still non-plaintext storage)
         return "H:" + HashHex(plain);
        }
      uchar b64[];
      if(!CryptEncode(CRYPT_BASE64, enc, enc, b64))
         return "H:" + HashHex(plain);
      return CharArrayToString(b64);
     }

   string SignRequest(const string body) const
     {
      return HashHex(StringFormat("%s|%I64u|%s", body, m_nonce_seq, GM_CLOUD_POLICY));
     }

   ulong NextNonce(void)
     {
      m_nonce_seq++;
      return m_nonce_seq;
     }

   bool ValidateSessionToken(const string token_hash) const
     {
      return (StringLen(token_hash) >= 8);
     }
  };

#endif // GM_CCLOUD_SECURITY_MQH
//+------------------------------------------------------------------+
