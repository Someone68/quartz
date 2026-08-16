import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:quartz/backend_status.dart';
import 'package:quartz/modules/misc.dart';
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

  /// Ids of selected shortcuts. Single click selects, double click runs.
  final Set<String> _selected = {};

  /// Where a shift-click range starts from.
  int? _anchorIndex;

  bool _loadInFlight = false;
  bool _loading = false;

  Future<void> _loadShortcuts() async {
    if (_loadInFlight) return;
    _loadInFlight = true;
    _loading = true;
    try {
      final summaries = await getShortcuts();
      if (!mounted) return;
      setState(() {
        _shortcutSummaries = summaries;
        // Drop selections for shortcuts that no longer exist.
        final ids = summaries.map((s) => s.id).toSet();
        _selected.removeWhere((id) => !ids.contains(id));
        _anchorIndex = null;
        _loading = false;
      });
    } on ClientException {
      backendStatus.markOffline();
      if (!mounted) return;
      setState(() => _loading = true);
    } finally {
      _loadInFlight = false;
      _loading = false;
    }
  }

  String? error;
  StreamSubscription<BackendStatus>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = backendStatus.status.listen((status) {
      if (!mounted) return;
      if (status == BackendStatus.online) _loadShortcuts();
    });
    if (backendStatus.current == BackendStatus.online) {
      _loadShortcuts();
    } else {
      backendStatus.refresh();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _handleSelect(int index, SelectModifiers mods) {
    final id = _shortcutSummaries[index].id;
    setState(() {
      if (mods.range && _anchorIndex != null) {
        final start = math.min(_anchorIndex!, index);
        final end = math.max(_anchorIndex!, index);
        // Plain shift replaces the selection; ctrl+shift adds to it.
        if (!mods.toggle) _selected.clear();
        for (var i = start; i <= end; i++) {
          _selected.add(_shortcutSummaries[i].id);
        }
      } else if (mods.toggle) {
        if (!_selected.remove(id)) _selected.add(id);
        _anchorIndex = index;
      } else if (_selected.length == 1 && _selected.contains(id)) {
        // Clicking the only selected card deselects it.
        _selected.clear();
        _anchorIndex = null;
      } else {
        _selected
          ..clear()
          ..add(id);
        _anchorIndex = index;
      }
    });
  }

  void _clearSelection() {
    if (_selected.isEmpty) return;
    setState(() {
      _selected.clear();
      _anchorIndex = null;
    });
  }

  void _selectAll() {
    setState(() {
      _selected.addAll(_shortcutSummaries.map((s) => s.id));
      _anchorIndex = null;
    });
  }

  Future<void> _deleteSelected() async {
    final ids = _selected.toList();
    if (ids.isEmpty) return;
    final label = ids.length == 1
        ? '"${_shortcutSummaries.firstWhere((s) => s.id == ids.first).name}"'
        : '${ids.length} shortcuts';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Shortcuts'),
        content: Text('Delete $label?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final failed = <String>[];
    for (final id in ids) {
      try {
        await deleteShortcut(id);
      } catch (e) {
        failed.add('$e');
      }
    }
    if (!mounted) return;
    if (failed.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${failed.length} delete(s) failed: ${failed.first}'),
        ),
      );
    }
    await _loadShortcuts();
  }

  @override
  Widget build(BuildContext context) {
    final selecting = _selected.isNotEmpty;

    return ValueListenableBuilder<Set<String>>(
      valueListenable: runningShortcutIds,
      builder: (context, running, _) =>
          _buildScaffold(context, selecting, running),
    );
  }

  Widget _buildScaffold(
    BuildContext context,
    bool selecting,
    Set<String> running,
  ) {
    return Scaffold(
      appBar: AppBar(
        leading: selecting
            ? IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Clear selection',
                onPressed: _clearSelection,
              )
            : null,
        title: Text(selecting ? '${_selected.length} selected' : 'Shortcuts'),
        actions: selecting
            ? [
                IconButton(
                  icon: const Icon(Icons.play_arrow),
                  tooltip: _selected.length == 1
                      ? 'Run'
                      : 'Cannot run more than one shortcut at a time',
                  onPressed: _selected.length == 1
                      ? () => runShortcutWithLog(context, _selected.first)
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.play_arrow),
                  tooltip: _selected.length != 1
                      ? 'Cannot run more than one shortcut at a time'
                      : running.contains(_selected.first)
                      ? 'Already running'
                      : 'Run',
                  onPressed:
                      _selected.length == 1 &&
                          !running.contains(_selected.first)
                      ? () => runShortcutWithLog(context, _selected.first)
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.select_all),
                  tooltip: 'Select all',
                  onPressed: _selectAll,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Delete selected',
                  onPressed: _deleteSelected,
                ),
                const SizedBox(width: 8.0),
              ]
            : null,
      ),
      body: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): _clearSelection,
          const SingleActivator(LogicalKeyboardKey.keyA, control: true):
              _selectAll,
          const SingleActivator(LogicalKeyboardKey.delete): () {
            if (_selected.isNotEmpty) _deleteSelected();
          },
        },
        child: Focus(
          autofocus: true,
          child: GestureDetector(
            // Clicking the empty grid background drops the selection.
            behavior: HitTestBehavior.opaque,
            onTap: _clearSelection,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: backendStatus.current == BackendStatus.online
                  ? GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 500.0,
                            mainAxisExtent: 80,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                      itemBuilder: (context, index) => ShortcutCard(
                        shortcutSummary: _shortcutSummaries[index],
                        onEdit: widget.onEdit,
                        onChanged: _loadShortcuts,
                        selected: _selected.contains(
                          _shortcutSummaries[index].id,
                        ),
                        running: running.contains(_shortcutSummaries[index].id),
                        onSelect: (mods) => _handleSelect(index, mods),
                      ),
                      itemCount: _shortcutSummaries.length,
                    )
                  : Text("Backend is offline."),
            ),
          ),
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
