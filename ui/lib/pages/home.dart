import 'package:flutter/material.dart';
import 'package:ui/requests.dart';
import 'package:ui/types.dart';
import 'package:ui/modules/shortcut_card.dart';

/// Shortcuts list — the landing page. Placeholder until shortcut storage and
/// the list/grid view are wired up.

class HomePage extends StatefulWidget {
  HomePage({super.key, required this.onEdit});

  /// Opens a shortcut in the editor tab (provided by the shell).
  final void Function(Shortcut) onEdit;

  List<ShortcutSummary> shortcutSummaries = [];

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future<void> _loadShortcuts() async {
    final summaries = await getShortcuts();
    if (!mounted) return;
    setState(() => widget.shortcutSummaries = summaries);
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
        child: Wrap(
          spacing: 16.0,
          runSpacing: 16.0,
          children: [
            ...widget.shortcutSummaries.map(
              (summary) => ShortcutCard(
                shortcutSummary: summary,
                onEdit: widget.onEdit,
                onChanged: _loadShortcuts,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => widget.onEdit(
          Shortcut(id: '', name: 'New Shortcut', trigger: Trigger(type: '')),
        ),
        label: const Text('Create Shortcut'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
