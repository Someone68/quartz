# Quartz

a desktop automation app for windows and linux.

## gif

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
curl -fLO https://github.com/you/quartz/releases/latest/download/quartz-linux-x64.tar.gz
tar xzf quartz-linux-x64.tar.gz
cd quartz-*-linux-x64 && ./install.sh
```

uninstall:

```bash
# run the script
~/.local/lib/quartz/uninstall.sh
# or wherever the install script told you it was
```

## Features

- 20+ actions
- shortcut triggers
- variables and scripting logic
- material 3 flutter ui
- simple shortcut editor

## How to run it locally

**requirements**:

- flutter sdk, in PATH (any modern version)
- python 3.11+, in PATH
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

building (requires docker):

```bash
docker build -t quartz-daemon-build -f packaging/docker/Dockerfile.daemon packaging/docker
docker build -t quartz-ui-build -f packaging/docker/Dockerfile.ui packaging/docker

./packaging/build.sh 0.1.0 # you can replace this with whatever u want tbh
```

## What it uses and why i chose them

- Python FastAPI: very simple and fast obviously
- Flutter UI: i was too lazy to learn react native and it comes with a ui framework
