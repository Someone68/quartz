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

  static const _kEditorIndex = 1;
  // Icon-only NavigationRail minimum width in Material 3.
  static const _kRailWidth = 72.0;

  static const _destinations = [
    _Dest(Icons.bolt_outlined, Icons.bolt, 'Shortcuts'),
    _Dest(Icons.edit_outlined, Icons.edit, 'Editor'),
    _Dest(Icons.settings_outlined, Icons.settings, 'Settings'),
  ];

  static final _pages = [
    HomePage(),
    EditorPage(
      shortcut: Shortcut(
        id: '',
        name: '',
        description: '',
        icon: '',
        enabled: false,
        trigger: Trigger(type: ''),
        steps: [],
      ),
    ),
    SettingsPage(),
  ];

  bool get _editorActive => _index == _kEditorIndex;

  void _selectDestination(int i) {
    setState(() {
      _index = i;
      _navOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

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
              child: IndexedStack(index: _index, children: _pages),
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
            child: IndexedStack(index: _index, children: _pages),
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
