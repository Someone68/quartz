# Quartz — Product Requirements Document

## Overview
Quartz is a cross-platform desktop automation app for Linux and Windows. Power users build trigger-driven, chainable automations through a visual GUI with no code required. The product is built around the idea that system automation should be accessible to anyone comfortable with logic, not just developers. Every feature surfaces that principle: shortcuts are composable, readable, and portable by design.

## Users

**Power User**
Can create, edit, and run shortcuts. Builds triggers and step sequences through the visual editor, views run history, and manages their shortcut library. No account required.

## Core Features
1. Build a "shortcut": a named automation consisting of one trigger and an ordered sequence of steps.
2. Choose from trigger types: hotkey, schedule, file watch, app open/close, clipboard change, network connect, system idle, startup.
3. Add steps from action categories: System, Files, Apps, Clipboard, Network, Text, Shell.
4. Add control flow steps: If/Else, Loop, Repeat, Set Variable, Wait, Stop.
5. Pass outputs between steps using `{{variables.name}}` or `{{steps.s1.output}}` syntax.
6. Reorder steps by dragging.
7. Use the variable picker to see available outputs at each point in the flow while building.
8. Run any shortcut manually or let its trigger fire it automatically.
9. View run history with per-step output logs.
10. Manage shortcuts from the system tray.
11. Store shortcuts as portable JSON files in `~/.config/quartz/` — no account, no database, shareable by copying a file.

## Out of Scope
The following are excluded from v1:
- macOS support
- Cloud sync or remote access
- User accounts or authentication
- Plugin marketplace or third-party extensions
- Mobile companion app
- Raw code editor or scripting interface

## Pages / Screens

**Dashboard**
The main shortcut library. Lists all shortcuts with name, trigger type, last run time, and enabled/disabled toggle. Includes a button to create a new shortcut and a link to run history.

**Shortcut Editor**
The visual builder for a single shortcut. Shows the trigger at the top and the step sequence below it. Each step is an expandable card with its action type, configuration fields, and a handle for drag-to-reorder. The variable picker is accessible from any input field and shows outputs available at that point in the flow.

**Settings/Run History**
App settings, including appearance, and a log of past shortcut executions. Each entry shows the shortcut name, trigger that fired it, timestamp, pass/fail status, and a per-step breakdown of outputs and any errors.

**System Tray Menu**
Accessible from the OS tray icon. Shows enabled shortcuts, lets the user run any shortcut manually, and provides quick access to the dashboard.

## User Flows

**A user automates a repetitive task**
1. Opens the dashboard and clicks to create a new shortcut.
2. Names the shortcut and picks a trigger (for example, a hotkey or a schedule).
3. Adds steps in order: a file action, a notification, an HTTP request.
4. Uses the variable picker to wire the output of one step into the input of the next.
5. Adds an If/Else step to branch based on the HTTP response.
6. Saves and tests the shortcut by running it manually.
7. Checks run history to verify each step's output.
8. Enables the shortcut so it fires automatically from then on.

**A user shares a shortcut with a colleague**
1. Locates the shortcut's JSON file in `~/.config/quartz/`.
2. Sends the file. The colleague drops it into their own config directory.
3. The shortcut appears in their dashboard, ready to run or edit.

## Design Direction
Clean, dense, and functional. The editor is the product — design serves clarity of the automation logic above all else. Light theme. Step cards should feel like structured blocks, not forms: clear type hierarchy, tight spacing, and visual distinction between trigger, action steps, and control flow steps. The variable picker should feel surgical: fast to open, easy to scan, zero friction to insert. Reference the feel of a refined developer tool (Linear, Raycast) kept calm rather than flashy. No decorative UI.

## Definition of Done
- A user can create, edit, enable, disable, and delete shortcuts on Linux and Windows.
- All v1 trigger types fire correctly and launch their shortcut.
- All action categories and control flow step types work end-to-end.
- Step outputs are accessible in downstream steps via the template syntax.
- The variable picker shows only outputs available at each position in the flow.
- Run history records every execution with per-step output and error detail.
- Shortcuts are stored as human-readable JSON and can be moved between machines by copying the file.
- The app runs as a background process accessible from the system tray.
