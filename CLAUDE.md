# Quartz

Cross-platform desktop automation app for Linux and Windows. Power users can build trigger-driven, chainable automations through a visual GUI — no code required. Like iOS Shortcuts for the desktop.

## What it does

Users create "shortcuts": a trigger + a sequence of steps that run in order. Steps can perform system actions, manipulate files, call APIs, or control flow (if/else, loops, variables). Outputs from one step feed into the next via a simple template syntax.

## Who it's for

Power users who want to automate their desktop without writing scripts. They're comfortable with logic (conditions, variables) but don't want to touch a terminal.

## Core concepts

- **Shortcut** — a named automation with one trigger and a list of steps
- **Trigger** — what fires the shortcut (hotkey, schedule, file change, app open, clipboard change, etc.)
- **Step** — one unit of work: run an action, set a variable, branch on a condition, loop, wait, or stop
- **Action** — a built-in capability (set brightness, send notification, move file, HTTP request, run shell command, etc.)
- **Context** — data passed between steps using `{{variables.name}}` or `{{steps.s1.output}}` syntax

## Stack

- **UI:** Flutter (cross-platform, fast, no browser engine)
- **Backend:** Python (FastAPI, runs locally in background)
- **Storage:** JSON files in `~/.config/quartz/` — no database, shortcuts are portable and shareable
- **Communication:** local HTTP between Flutter and Python backend

## Key features (v1)

- Visual shortcut builder with drag-to-reorder steps
- Trigger types: hotkey, schedule, file watch, app open/close, clipboard change, network connect, system idle, startup
- Action categories: System, Files, Apps, Clipboard, Network, Text, Shell
- Control flow steps: If/Else, Loop, Repeat, Set Variable, Wait, Stop
- Variable picker in UI showing available outputs at each point in the flow
- Run history with per-step output logs
- System tray integration

## Out of scope (v1)

macOS, cloud sync, user accounts, plugin marketplace, mobile, raw code editor
