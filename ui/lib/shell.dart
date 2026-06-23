import 'package:flutter/material.dart';

import 'pages/home.dart';
import 'pages/editor.dart';
import 'pages/settings.dart';

/// Top-level frame: a thin icon-only nav rail on the left and the active page
/// on the right. Pages are kept alive in an [IndexedStack] so switching tabs
/// preserves their scroll position and in-progress state.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _destinations = [
    _Dest(Icons.bolt_outlined, Icons.bolt, 'Shortcuts'),
    _Dest(Icons.edit_outlined, Icons.edit, 'Editor'),
    _Dest(Icons.settings_outlined, Icons.settings, 'Settings'),
  ];

  static const _pages = [HomePage(), EditorPage(), SettingsPage()];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
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
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(
            child: IndexedStack(index: _index, children: _pages),
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
