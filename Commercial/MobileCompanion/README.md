# THE GOLD MIND Mobile Companion

Commercial customer management for Android and iOS.

## Hard rules

- **NOT** a trading terminal
- **NEVER** executes trades or contains strategy / risk / order logic
- All trading remains in certified **MT5 Professional**
- Communicates only with authenticated commercial APIs (`/api/mobile/*`)

## Stack

React Native (Expo) · secure token storage · FCM/APNs · biometric unlock

## Backend

Portal module: `CustomerPortal/web/src/server/mobile`  
CLI: `npm run phase11:sprint6`
