# THE GOLD MIND PROFESSIONAL - Installer Pack

**Edition:** Website Professional commercial packaging  
**Core Trading Engine:** never modified by these scripts or Setup.exe

## Build release (produces Setup.exe)

```powershell
cd scripts
powershell -ExecutionPolicy Bypass -File .\Build-CommercialRelease.ps1
```

Output: `Commercial/Releases/1.0.0/installer/Setup.exe`

## Validate

```powershell
powershell -ExecutionPolicy Bypass -File .\Validate-Installer.ps1 -SetupExe ..\..\..\Releases\1.0.0\installer\Setup.exe
```

## Customer install

1. Run `Setup.exe`
2. Optional: MT5 EA deploy + license activation wizards
3. Start Menu: Activate License / Deploy EA to MT5
4. Open MT5 -> Navigator -> The Gold Mind -> attach EA

## Signing

```powershell
.\Build-CommercialRelease.ps1 -SignMode standard -SignThumbprint <THUMBPRINT>
.\Build-CommercialRelease.ps1 -SignMode ev -SignCertPath .\ev.pfx -SignCertPassword <SECRET>
```

## Rule

If verification fails: cancel installation, keep previous version, inform the customer.
