# Installing quartz

Quartz is built for windows or linux, and will not work on anything else.

## Windows Installation

To install on windows, just download the latest .MSIX release from the [releases page](https://github.com/quartz-scheduler/quartz/releases) and double-click on the downloaded file to install.

You can also [build from source](#building-from-source) for some reason.

## Linux Installation

> [!NOTE]
> The use of a systemd-based distribution is required.
> If your distribution does not support .DEB or .RPM packages, see the [building from source](#building-from-source) instructions.

To install on linux, just download the latest .DEB or .RPM release from the [releases page](https://github.com/quartz-scheduler/quartz/releases) and follow the installation instructions for your distribution.

## Building from source

Requirements:

- Python 3.8+, in PATH
- pip in PATH
- flutter SDK, in PATH (see [flutter docs](https://docs.flutter.dev/install/manual))
- Windows: Visual Studio Build Tools (C++)
- Windows: Microsoft PowerShell
- Linux: Bash

Linux:

```bash
git clone https://github.com/Someone68/quartz.git
cd quartz
bash ./packaging/linux/install-from-source.sh
# installed!
```

Windows (Powershell):

```bash
git clone https://github.com/Someone68/quartz.git
cd quartz
./packaging/windows/build-installer.ps1
# .msix installer built in dist/quartz-setup-*.exe
```
