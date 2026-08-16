import 'package:flutter/material.dart';
import 'package:quartz/requests.dart';
import 'package:quartz/types.dart';
import 'package:quartz/modules/shortcut_card.dart';

/// Shortcuts list — the landing page. Placeholder until shortcut storage and
/// the list/grid view are wired up.

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.onEdit});

  /// Opens a shortcut in the editor tab (provided by the shell).
  final void Function(Shortcut) onEdit;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<ShortcutSummary> _shortcutSummaries = [];

  Future<void> _loadShortcuts() async {
    final summaries = await getShortcuts();
    if (!mounted) return;
    setState(() => _shortcutSummaries = summaries);
  }

  @override
  void initState() {
    super.initState();
    _loadShortcuts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shortcuts')),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 500.0,
            mainAxisExtent: 80,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemBuilder: (context, index) => ShortcutCard(
            shortcutSummary: _shortcutSummaries[index],
            onEdit: widget.onEdit,
            onChanged: _loadShortcuts,
          ),
          itemCount: _shortcutSummaries.length,
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => widget.onEdit(
          Shortcut(
            id: '',
            name: 'New Shortcut',
            trigger: Trigger(type: 'manual'),
          ),
        ),
        label: const Text('Create Shortcut'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
