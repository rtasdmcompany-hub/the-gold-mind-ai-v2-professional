# BUILD_GUIDE.md

## Prerequisite
- Windows `csc.exe` (.NET Framework 4.x) - used automatically
- Certified `Experts/TheGoldMindAI_Professional.ex5` present
- Core mq5 SHA must equal `75002e46e3c200292c3696b2767bba20f2dd4200c74078555f84bc1f54a033ce`

## Build (unsigned / default)
```powershell
cd "Commercial\Installer\Professional\scripts"
powershell -ExecutionPolicy Bypass -File .\Build-CommercialRelease.ps1
```

## Sign (standard)
```powershell
.\Build-CommercialRelease.ps1 -SignMode standard -SignThumbprint <THUMBPRINT>
```

## Sign (EV PFX)
```powershell
.\Build-CommercialRelease.ps1 -SignMode ev -SignCertPath .\ev.pfx -SignCertPassword <SECRET>
```

## Validate
```powershell
.\Validate-Installer.ps1 -SetupExe "..\..\..\Releases\1.0.0\installer\Setup.exe"
```

## Output
`Commercial/Releases/1.0.0/installer/Setup.exe`

## Absolute rule
Do not modify Trading Engine / Risk / Recovery / Money / Entry / Exit / Order logic / Core SHA.
