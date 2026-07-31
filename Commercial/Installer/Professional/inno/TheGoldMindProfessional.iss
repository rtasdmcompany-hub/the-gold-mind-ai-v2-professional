; THE GOLD MIND PROFESSIONAL — Inno Setup 6 script
; Commercial packaging only. Does NOT modify Core Trading Engine.
; Compile: ISCC.exe TheGoldMindProfessional.iss

#define MyAppName "THE GOLD MIND PROFESSIONAL"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "THE GOLD MIND"
#define MyAppURL "https://the-gold-mind-ai-v2-professional.vercel.app"
#define MyAppExeName "TGM-Professional-Launcher.exe"
; AppId string kept for upgrade continuity (not customer-visible branding)
#define MyAppId "RTAS.TheGoldMind.Professional.1"

[Setup]
AppId={{#MyAppId}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}/support
AppUpdatesURL={#MyAppURL}/downloads
DefaultDirName={localappdata}\THE GOLD MIND PROFESSIONAL
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
VersionInfoVersion=1.0.0.0
VersionInfoCompany={#MyAppPublisher}
VersionInfoDescription={#MyAppName} Setup
VersionInfoProductName={#MyAppName}
VersionInfoProductVersion={#MyAppVersion}
VersionInfoCopyright=Copyright (C) 2026 {#MyAppPublisher}
; Signing: uncomment and set SignTool when certificate available
; SignTool=signtool
; SignedUninstaller=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a &Desktop shortcut"; GroupDescription: "Additional icons:"; Flags: unchecked
Name: "deployea"; Description: "Install Expert Advisor into selected MetaTrader 5 terminal"; GroupDescription: "MetaTrader 5:"; Flags: checkedonce

[Files]
Source: "payload\bin\*"; DestDir: "{app}\bin"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "payload\config\*"; DestDir: "{app}\config"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "payload\docs\*"; DestDir: "{app}\docs"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "payload\ea\TheGoldMindAI_Professional.ex5"; DestDir: "{app}\ea"; Flags: ignoreversion
Source: "payload\ea\CORE_SHA256.txt"; DestDir: "{app}\ea"; Flags: ignoreversion
Source: "payload\scripts\*"; DestDir: "{app}\scripts"; Flags: ignoreversion
Source: "payload\README.txt"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\bin\{#MyAppExeName}"; WorkingDir: "{app}"
Name: "{group}\Open Customer Portal"; Filename: "https://the-gold-mind-ai-v2-professional.vercel.app"
Name: "{group}\Uninstall {#MyAppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\bin\{#MyAppExeName}"; WorkingDir: "{app}"; Tasks: desktopicon

[Run]
Filename: "{app}\bin\{#MyAppExeName}"; Description: "Launch {#MyAppName}"; Flags: nowait postinstall skipifsilent
; Post-install MT5/license configuration is handled by the WinForms launcher (no customer PowerShell windows).

[UninstallDelete]
Type: filesandordirs; Name: "{app}\logs"
Type: filesandordirs; Name: "{app}\updates"
Type: filesandordirs; Name: "{app}\rollback"

[Code]
function DeployEaFlag(Param: String): String;
begin
  if WizardIsTaskSelected('deployea') then
    Result := 'Yes'
  else
    Result := 'No';
end;
