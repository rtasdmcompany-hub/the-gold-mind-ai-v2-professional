# INSTALLATION_GUIDE.md

**Product:** THE GOLD MIND PROFESSIONAL 1.2.0
**Installer:** `Commercial/Releases/1.2.0/installer/Setup.exe`

## Requirements
- Windows 10/11 (64-bit)
- MetaTrader 5 installed and opened at least once
- Customer Portal account + valid license key

## Steps
1. Download `Setup.exe` (verify SHA-256 against `SHA256SUMS.txt`).
2. Run `Setup.exe`.
3. Confirm install location (default: `%LOCALAPPDATA%\THE GOLD MIND PROFESSIONAL`).
4. Allow MT5 detection / EA deploy when prompted.
5. Activate license (email + key). Optional: Google login via
   https://the-gold-mind-ai-v2-professional.vercel.app/login?provider=google
6. Open MT5 -> Navigator -> Expert Advisors -> **The Gold Mind**.
7. Attach `TheGoldMindAI_Professional` to your chart.

## Uninstall
Settings -> Apps -> THE GOLD MIND PROFESSIONAL -> Uninstall

## Core note
Installer copies the certified `.ex5` only. Trading engine logic is never modified.
