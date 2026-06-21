import 'package:flutter/material.dart';
import 'package:ui/shortcut_card.dart';

/// Shortcuts list — the landing page. Placeholder until shortcut storage and
/// the list/grid view are wired up.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shortcuts')),
      body: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(children: [ShortcutCard()]),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }
}
