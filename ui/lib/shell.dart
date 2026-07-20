import 'package:flutter/material.dart';

import 'pages/home.dart';
import 'pages/editor.dart';
import 'pages/settings.dart';
import 'types.dart';

/// Top-level frame: a thin icon-only nav rail on the left and the active page
/// on the right. Pages are kept alive in an [IndexedStack] so switching tabs
/// preserves their scroll position and in-progress state.
///
/// On the editor page the rail hides; a chevron button at the left edge
/// slides it back in as an overlay (drawer-style).
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  bool _navOpen = false;

  /// Bumped whenever the Shortcuts tab is (re)selected, to force HomePage to
  /// rebuild fresh and refetch — the IndexedStack keeps it alive otherwise.
  int _homeEpoch = 0;

  /// Shortcut currently loaded in the editor tab. Null until the user opens
  /// one (edit button) or starts a new one (create button).
  Shortcut? _editorShortcut;

  static const _kEditorIndex = 1;
  // Icon-only NavigationRail minimum width in Material 3.
  static const _kRailWidth = 72.0;

  static const _destinations = [
    _Dest(Icons.bolt_outlined, Icons.bolt, 'Shortcuts'),
    _Dest(Icons.edit_outlined, Icons.edit, 'Editor'),
    _Dest(Icons.settings_outlined, Icons.settings, 'Settings'),
  ];

  bool get _editorActive => _index == _kEditorIndex;

  /// Load a shortcut into the editor and switch to it in-place, so the nav
  /// rail stays available (no route push = no softlock).
  void _openEditor(Shortcut shortcut) {
    setState(() {
      _editorShortcut = shortcut;
      _index = _kEditorIndex;
      _navOpen = false;
    });
  }

  Shortcut _blankShortcut() => Shortcut(
    id: '',
    name: 'New Shortcut',
    trigger: Trigger(type: 'manual'),
    steps: [],
  );

  void _selectDestination(int i) {
    setState(() {
      // Opening the editor tab with nothing loaded starts a new shortcut.
      if (i == _kEditorIndex) _editorShortcut ??= _blankShortcut();
      // Landing back on Shortcuts refetches the list (may have changed in editor).
      if (i == 0) _homeEpoch++;
      _index = i;
      _navOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final editorShortcut = _editorShortcut ??= _blankShortcut();
    final pages = [
      HomePage(key: ValueKey(_homeEpoch), onEdit: _openEditor),
      // Key by id so loading a different shortcut rebuilds the editor fresh.
      EditorPage(key: ValueKey(editorShortcut.id), shortcut: editorShortcut),
      SettingsPage(),
    ];

    final rail = NavigationRail(
      selectedIndex: _index,
      onDestinationSelected: _selectDestination,
      labelType: NavigationRailLabelType.none,
      backgroundColor: scheme.surfaceContainerLow,
      groupAlignment: -1,
      destinations: [
        for (final d in _destinations)
          NavigationRailDestination(
            icon: Icon(d.icon),
            selectedIcon: Icon(d.selectedIcon),
            label: Text(d.label),
          ),
      ],
    );

    if (!_editorActive) {
      return Scaffold(
        body: Row(
          children: [
            rail,
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(
              child: IndexedStack(index: _index, children: pages),
            ),
          ],
        ),
      );
    }

    // Editor page: full-width content + collapsible rail overlay.
    return Scaffold(
      body: Stack(
        children: [
          // Page content — full width.
          Positioned.fill(
            child: IndexedStack(index: _index, children: pages),
          ),

          // Dark scrim — fades in/out; IgnorePointer when transparent.
          Positioned.fill(
            child: IgnorePointer(
              ignoring: !_navOpen,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeInOut,
                opacity: _navOpen ? 1.0 : 0.0,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _navOpen = false),
                  child: const ColoredBox(color: Color(0x66000000)),
                ),
              ),
            ),
          ),

          // Sliding rail overlay.
          AnimatedPositioned(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeInOut,
            left: _navOpen ? 0 : -_kRailWidth,
            top: 0,
            bottom: 0,
            child: Material(
              elevation: 4,
              child: SizedBox(width: _kRailWidth, child: rail),
            ),
          ),

          // Chevron toggle button (only when rail is closed).
          if (!_navOpen)
            Positioned(
              left: 0,
              bottom: 12,
              child: Material(
                color: scheme.surfaceContainerLow,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
                elevation: 2,
                child: InkWell(
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                  onTap: () => setState(() => _navOpen = true),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: Icon(Icons.chevron_right, size: 18),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Dest {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  const _Dest(this.icon, this.selectedIcon, this.label);
}
