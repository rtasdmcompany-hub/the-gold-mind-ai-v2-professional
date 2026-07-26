# MOBILE_ARCHITECTURE.md

**Phase:** 11 · Sprint 6  
**Product:** THE GOLD MIND Mobile Companion  
**Isolation:** Mobile Companion communicates only with commercial APIs. Trading remains exclusively in certified MT5 Professional.

## Platforms

| Platform | Stack | Push |
|----------|-------|------|
| Android | React Native (Expo) · Kotlin modules for biometrics/Keystore | FCM |
| iOS | React Native (Expo) · Swift modules for Keychain/Face ID | APNs |

## Layers

- Responsive API: `/api/mobile/*`
- Offline cache: encrypted SWR snapshot (TTL 3600s)
- Auth: email · google_oauth · 2fa · biometric_unlock
- Version management: Android 1.0.0 / iOS 1.0.0

## Scaffold

`H:\PERSONAL\RTAS Digital Marketing Company\RTAS Softwear\THE GOLD MIND AI v2.0 Professional\Commercial\MobileCompanion`

## Hard rule

Trading prohibited: **true**
