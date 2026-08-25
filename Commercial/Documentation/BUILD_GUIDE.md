# BUILD_GUIDE.md

## Prerequisite
- Windows `csc.exe` (.NET Framework 4.x) **or** Linux `mcs` (mono) - used automatically
- Certified `Experts/TheGoldMindAI_Professional.ex5` present
- Core mq5 SHA must equal `c7a251ef5769d597f50f7515165106a937471ed765a491f59f7e542d05e165da`
- No duplicate alias installers / no `github-assets/` mirror in git

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
.\Validate-Installer.ps1 -SetupExe "..\..\..\Releases\1.1.0\installer\Setup.exe"
```

## Output
`Commercial/Releases/1.1.0/installer/Setup.exe`

## Absolute rule
Do not modify Trading Engine / Risk / Recovery / Money / Entry / Exit / Order logic / Core SHA.
