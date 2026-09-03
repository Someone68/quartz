# Build the unsigned Quartz installer for Windows.
#
# Produces dist\quartz-setup-<version>.exe containing the Flutter UI
# (quartz.exe) and the frozen daemon (quartzd.exe). No code-signing cert is
# involved, so users will see a SmartScreen "unknown publisher" warning and
# have to click "More info" -> "Run anyway".
#
# Needs on PATH:
#   - Python 3 and Flutter
#   - ISCC.exe (Inno Setup 6). Preinstalled on GitHub's windows runners;
#     locally: winget install JRSoftware.InnoSetup
#
#   powershell -ExecutionPolicy Bypass -File packaging\windows\build-installer.ps1

$ErrorActionPreference = "Stop"
$root  = (Resolve-Path "$PSScriptRoot\..\..").Path
$dist  = Join-Path $root "dist"
$stage = Join-Path $root "build\innosetup"
New-Item -ItemType Directory -Force -Path $dist | Out-Null

# --- 1. Daemon (PyInstaller) ------------------------------------------------
$venv = Join-Path $root "backend\.venv"
if (-not (Test-Path $venv)) { python -m venv $venv }
& "$venv\Scripts\pip.exe" install -q --upgrade pip
& "$venv\Scripts\pip.exe" install -q -r "$root\backend\requirements.txt" pyinstaller
& "$venv\Scripts\pyinstaller.exe" "$root\packaging\quartzd.spec" `
    --distpath $dist --workpath "$root\build\pyinstaller" -y
if ($LASTEXITCODE -ne 0) { throw "PyInstaller failed" }

# --- 2. UI (Flutter) --------------------------------------------------------
Push-Location "$root\ui"
# material_symbols_icons drives IconData from non-constant values, which
# the icon tree-shaker rejects; --no-tree-shake-icons keeps the full font.
flutter build windows --release --no-tree-shake-icons
Pop-Location
if ($LASTEXITCODE -ne 0) { throw "flutter build windows failed" }
$release = "$root\ui\build\windows\x64\runner\Release"

# --- 3. Stage the install payload ------------------------------------------
# Both binaries go in one flat directory: the UI launches the daemon as a
# sibling (ui/lib/daemon.dart) and the tray finds the UI the same way.
if (Test-Path $stage) { Remove-Item -Recurse -Force $stage }
New-Item -ItemType Directory -Force -Path $stage | Out-Null
Copy-Item "$release\*" $stage -Recurse -Force
Copy-Item "$dist\quartzd.exe" $stage -Force

# Installer + shortcut icon.
& "$venv\Scripts\python.exe" "$root\packaging\gen_icon.py" "$dist\quartz.ico" 256

# --- 4. Compile the installer ----------------------------------------------
$iscc = Get-Command ISCC.exe -ErrorAction SilentlyContinue
if (-not $iscc) {
    foreach ($p in @("${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
                     "$env:ProgramFiles\Inno Setup 6\ISCC.exe")) {
        if (Test-Path $p) { $iscc = $p; break }
    }
    if (-not $iscc) { throw "ISCC.exe not found. Install Inno Setup 6." }
} else { $iscc = $iscc.Source }

& $iscc "/DStageDir=$stage" "$PSScriptRoot\quartz.iss"
if ($LASTEXITCODE -ne 0) { throw "ISCC failed" }

Get-ChildItem "$dist\quartz-setup-*.exe" | ForEach-Object {
    Write-Host "Built $($_.FullName)"
}
