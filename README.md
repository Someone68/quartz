# Quartz

a desktop automation app for windows and linux.

## gif

- insert gif here

## Quickstart

windows:

- download the latest release from the [releases page](https://example.com)
- install by running the .msix installer

linux:

> [!WARNING]
> linux version requires a systemd destribution

```bash
# i lowk forgot the script, insert here
```

## Features

- 20+ actions
- shortcut triggers
- variables and scripting logic
- material 3 flutter ui
- simple shortcut editor

## how to run it locally

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

## what it uses and why i chose them

- Python FastAPI: very simple and fast obviously
- Flutter UI: i was too lazy to learn react native and it comes with a ui framework
