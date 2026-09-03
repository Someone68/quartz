# Quartz

a desktop automation app for windows and linux.

![gif](https://github.com/Someone68/quartz/blob/main/preview.gif?raw=true)

## Quickstart

windows:

- download the latest release from the [releases page](https://github.com/Someone68/quartz/releases/latest)
- install by running the .msix installer

linux:

> [!WARNING]
> requires:
>
> - systemd
> - glibc 2.31+

```bash
# stable release
curl -fLO https://github.com/you/quartz/releases/latest/download/quartz-linux-x64.tar.gz
tar xzf quartz-linux-x64.tar.gz
cd quartz-*-linux-x64 && ./install.sh
```

if you prefer to use .deb/.rpm packages, you can download them from the [releases page](https://github.com/Someone68/quartz/releases/latest)

uninstall:

```bash
# run the script
~/.local/lib/quartz/uninstall.sh
# or wherever the install script told you it was (its probably here unless you have weird file paths)
```

macos: unsupported. you should lowkey just use the shortcuts app.

other os: idk, if you can figure it out thats great!

## Features

- 20+ actions
- shortcut triggers
- variables and scripting logic
- material 3 flutter ui
- simple shortcut editor

## Usage

Refer to the [usage guide](https://github.com/Someone68/quartz/wiki/Usage)

## How to run it locally

**requirements**:

- flutter sdk, in PATH (any modern version)
- python 3.11+, in PATH
- linux: nfpm
- windows: visual studio build tools (c++)
- windows: microsoft powershell

setup venv:

```bash
cd backend
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

start backend:

```bash
# in backend dir
python main.py
```

start ui (dev):

```bash
cd ui
flutter run
```

building:

in a container:

```bash
docker build -t quartz-daemon-build -f packaging/docker/Dockerfile.daemon packaging/docker
docker build -t quartz-ui-build -f packaging/docker/Dockerfile.ui packaging/docker

# creates tarball in dist/
./packaging/build.sh
```

on the host:

```bash
# creates .deb/.rpm packages
make linux

# rootless install, same way as using the tarball
make install
```

## What it uses and why i chose them

- Python FastAPI: very simple and fast (obviously)
- Flutter UI: i was too lazy to learn react native and it comes with m3 ui
