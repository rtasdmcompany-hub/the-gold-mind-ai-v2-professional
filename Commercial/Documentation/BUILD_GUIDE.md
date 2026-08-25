# BUILD_GUIDE.md

## Prerequisite
- Windows `csc.exe` (.NET Framework 4.x) **or** Linux `mcs` (mono) - used automatically
- Certified `Experts/TheGoldMindAI_Professional.ex5` present
- Core mq5 SHA must equal `734b0cc4831dc15fadb2cd838776928e8e9fbe611d7880a6801c548548591f4e`
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
.\Validate-Installer.ps1 -SetupExe "..\..\..\Releases\1.2.0\installer\Setup.exe"
```

## Output
`Commercial/Releases/1.2.0/installer/Setup.exe`

## Absolute rule
Do not modify Trading Engine / Risk / Recovery / Money / Entry / Exit / Order logic / Core SHA.
