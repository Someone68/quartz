; Inno Setup script for the Quartz Windows installer.
;
; Builds an unsigned, per-user installer: no admin rights, no code-signing
; certificate, no MSIX trust wall. Users get a SmartScreen "unknown publisher"
; prompt they can click through via "More info" -> "Run anyway".
;
; Because this is not a packaged (MSIX) app it has no package identity, so the
; windows.startupTask extension in AppxManifest.xml does not apply. Autostart
; is a plain HKCU Run value instead, written below and removed on uninstall.
;
; Built by packaging/windows/build-installer.ps1, which stages the payload
; into build\innosetup first. AppVersion is stamped by packaging/set-version.sh.
;
; Requires Inno Setup 6.3+ (for ArchitecturesAllowed=x64compatible).

#define AppName "Quartz"
#define AppVersion "0.2.0"
#define AppPublisher "Quartz"
#define AppURL "https://github.com/Someone68/quartz"
#define UIExe "quartz.exe"
#define DaemonExe "quartzd.exe"

; Payload directory, normally passed by build-installer.ps1 as /DStageDir=...
#ifndef StageDir
  #define StageDir "..\..\build\innosetup"
#endif

[Setup]
; Never change AppId: it is how Inno recognises an existing install and
; upgrades in place rather than stacking copies.
AppId={{289554f7-f539-4662-8055-3a3946fd2b06}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
AppPublisherURL={#AppURL}
AppSupportURL={#AppURL}/issues
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
; Per-user install: {autopf} resolves to %LOCALAPPDATA%\Programs, no UAC prompt.
; The daemon is a per-user background process anyway, and skipping elevation
; removes the scariest dialog from an unsigned installer's flow.
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
OutputDir=..\..\dist
OutputBaseFilename=quartz-setup-{#AppVersion}
SetupIconFile=..\..\dist\quartz.ico
UninstallDisplayIcon={app}\{#UIExe}
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
; Show the license the repo already ships.
LicenseFile=..\..\LICENSE

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop shortcut"; GroupDescription: "Additional shortcuts:"
Name: "autostart"; Description: "Start the Quartz background service when I log in"; GroupDescription: "Startup:"

[Files]
; The staging dir holds the Flutter release bundle (quartz.exe + DLLs + data\)
; with quartzd.exe copied in beside it. Both binaries must land in the same
; directory: the UI looks for the daemon as a sibling and the tray does the
; reverse.
Source: "{#StageDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\{#UIExe}"
Name: "{group}\Uninstall {#AppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#UIExe}"; Tasks: desktopicon

[Registry]
; Autostart for the daemon only — the UI is launch-on-demand. uninsdeletevalue
; drops this on uninstall.
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; \
    ValueType: string; ValueName: "Quartz"; ValueData: """{app}\{#DaemonExe}"""; \
    Flags: uninsdeletevalue; Tasks: autostart

[Run]
; Start the daemon now so triggers work without a reboot, then optionally the UI.
Filename: "{app}\{#DaemonExe}"; Description: "Start the Quartz background service"; \
    Flags: nowait postinstall skipifsilent
Filename: "{app}\{#UIExe}"; Description: "Launch {#AppName}"; \
    Flags: nowait postinstall skipifsilent

[UninstallRun]
; Stop the daemon before removing its files, or the uninstaller leaves a
; running process holding a locked exe.
Filename: "{sys}\taskkill.exe"; Parameters: "/f /im {#DaemonExe}"; \
    Flags: runhidden; RunOnceId: "StopQuartzd"

[UninstallDelete]
; PyInstaller onefile unpacks to %TEMP%\_MEIxxxxxx; a hard-killed daemon can
; leave one behind. Nothing else in {app} is generated at runtime.
Type: dirifempty; Name: "{app}"

[Code]
{ An upgrade over a running daemon fails on locked files, so stop it first.
  taskkill on a non-existent image just returns non-zero, which is fine. }
function PrepareToInstall(var NeedsRestart: Boolean): String;
var
  ResultCode: Integer;
begin
  Exec(ExpandConstant('{sys}\taskkill.exe'), '/f /im {#DaemonExe}', '',
       SW_HIDE, ewWaitUntilTerminated, ResultCode);
  Exec(ExpandConstant('{sys}\taskkill.exe'), '/f /im {#UIExe}', '',
       SW_HIDE, ewWaitUntilTerminated, ResultCode);
  Result := '';
end;
