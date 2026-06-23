import 'package:flutter/material.dart';
import 'package:ui/shortcut.dart';
import 'package:ui/modules/shortcut_card.dart';

List<ShortcutSummary> shortcutSummaries = [
  ShortcutSummary(id: 'test', name: 'test', icon: '', stepCount: 69),
  ShortcutSummary(id: 'test2', name: 'test2', icon: '', stepCount: 67),
];

/// Shortcuts list — the landing page. Placeholder until shortcut storage and
/// the list/grid view are wired up.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shortcuts')),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        child: Wrap(
          spacing: 16.0,
          runSpacing: 16.0,
          children: [
            ...shortcutSummaries.map(
              (summary) => ShortcutCard(shortcutSummary: summary),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        label: const Text('Create Shortcut'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
