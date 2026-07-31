; THE GOLD MIND PROFESSIONAL — Inno Setup 6 script
; Commercial packaging only. Does NOT modify Core Trading Engine.
; Compile: ISCC.exe TheGoldMindProfessional.iss
;
; Brand + product values: brand-defines.iss (from portal src/lib/brand.ts + src/lib/product.ts).
; Regenerate: cd Commercial/CustomerPortal/web && npx tsx scripts/export-brand.mjs

#include "brand-defines.iss"

; AppId string kept for upgrade continuity (not customer-visible branding)
#define MyAppId "RTAS.TheGoldMind.Professional.1"

[Setup]
AppId={{#MyAppId}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppSupportURL}
AppUpdatesURL={#MyAppUpdateURL}
AppCopyright={#MyAppCopyright}
DefaultDirName={localappdata}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=no
LicenseFile=payload\EULA.txt
InfoBeforeFile=payload\INFO_BEFORE.txt
OutputDir=..\..\..\Releases\1.0.0\installer
OutputBaseFilename=Setup
; SetupIconFile=payload\app.ico
UninstallDisplayIcon={app}\bin\{#MyAppExeName}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "payload\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
; Exclude build scripts from customer payload if present
Source: "payload\bin\*"; DestDir: "{app}\bin"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\bin\{#MyAppExeName}"
Name: "{group}\Uninstall {#MyAppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\bin\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\bin\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#MyAppName}}"; Flags: nowait postinstall skipifsilent
