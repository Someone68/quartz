# Build and sign the Quartz MSIX.
#
# Produces a package containing the Flutter UI (quartz.exe) and the frozen
# daemon (quartzd.exe), with the StartupTask from AppxManifest.xml. Needs:
#   - Python + Flutter on PATH
#   - Windows SDK (makeappx.exe, signtool.exe)
#   - a signing cert: run make-cert.ps1 first
#
#   powershell -ExecutionPolicy Bypass -File packaging\windows\build-msix.ps1

param(
    [string]$PfxPath  = "packaging\windows\quartz-dev.pfx",
    [string]$Password = "quartz"
)

$ErrorActionPreference = "Stop"
$root  = (Resolve-Path "$PSScriptRoot\..\..").Path
$dist  = Join-Path $root "dist"
$stage = Join-Path $root "build\msix"
New-Item -ItemType Directory -Force -Path $dist  | Out-Null

# --- 1. Daemon (PyInstaller) ------------------------------------------------
$venv = Join-Path $root "backend\.venv"
if (-not (Test-Path $venv)) { python -m venv $venv }
& "$venv\Scripts\pip.exe" install -q --upgrade pip
& "$venv\Scripts\pip.exe" install -q -r "$root\backend\requirements.txt" pyinstaller
& "$venv\Scripts\pyinstaller.exe" "$root\packaging\quartzd.spec" `
    --distpath $dist --workpath "$root\build\pyinstaller" -y

# --- 2. UI (Flutter) --------------------------------------------------------
Push-Location "$root\ui"
# material_symbols_icons drives IconData from non-constant values, which
# the icon tree-shaker rejects; --no-tree-shake-icons keeps the full font.
flutter build windows --release --no-tree-shake-icons
Pop-Location
$release = "$root\ui\build\windows\x64\runner\Release"

# --- 3. Stage the package layout -------------------------------------------
if (Test-Path $stage) { Remove-Item -Recurse -Force $stage }
New-Item -ItemType Directory -Force -Path "$stage\Assets" | Out-Null
Copy-Item "$release\*" $stage -Recurse -Force          # quartz.exe + dlls + data
Copy-Item "$dist\quartzd.exe" $stage -Force            # background daemon
Copy-Item "$PSScriptRoot\AppxManifest.xml" $stage -Force

# Package logos (square placeholders generated from the app icon).
$py = "$venv\Scripts\python.exe"
& $py "$root\packaging\gen_icon.py" "$stage\Assets\StoreLogo.png" 50
& $py "$root\packaging\gen_icon.py" "$stage\Assets\Square44x44Logo.png" 44
& $py "$root\packaging\gen_icon.py" "$stage\Assets\Square150x150Logo.png" 150
& $py "$root\packaging\gen_icon.py" "$stage\Assets\Wide310x150Logo.png" 150

# --- 4. Pack + sign ---------------------------------------------------------
$msix = Join-Path $dist "quartz.msix"
makeappx pack /o /d $stage /p $msix
signtool sign /fd SHA256 /a /f $PfxPath /p $Password $msix

Write-Host "Built $msix"
