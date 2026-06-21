import 'package:flutter/material.dart';

/// Shortcuts list — the landing page. Placeholder until shortcut storage and
/// the list/grid view are wired up.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shortcuts')),
      body: const Center(child: Text('No shortcuts yet')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }
}
