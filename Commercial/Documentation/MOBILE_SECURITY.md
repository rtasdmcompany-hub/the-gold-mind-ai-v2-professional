# MOBILE_SECURITY.md

| Control | Status |
|---------|--------|
| Biometric | Supported (device flag) |
| Encrypted local storage | EncryptedSharedPreferences / Keystore / Keychain + Data Protection Complete |
| Certificate validation | TLS ≥ 1.2 |
| Secure API | Bearer over HTTPS |
| Token refresh | access 1h · refresh 30d · rotation on refresh |
| Remote session revocation | true |
| Device integrity | Failures force session revoke |
| Trading on mobile | **FORBIDDEN** |

Never stored: trading_credentials, mt5_passwords, strategy_params
