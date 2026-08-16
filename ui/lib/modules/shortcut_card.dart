import 'package:flutter/material.dart';
import 'package:quartz/extensions.dart';
import 'package:quartz/modules/misc.dart';
import 'package:quartz/requests.dart';
import 'package:quartz/types.dart';

class _HoverCard extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;
  ColorScheme? colorScheme;

  _HoverCard({
    super.key,
    required this.onTap,
    required this.child,
    this.colorScheme,
  });

  @override
  State<_HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<_HoverCard> {
  bool _isHovered = false;
  bool _suppressHover = false;

  void setSuppressed(bool value) {
    setState(() => _suppressHover = value);
  }

  @override
  Widget build(BuildContext context) {
    final showHover = _isHovered && !_suppressHover;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: AnimatedPhysicalModel(
          duration: const Duration(milliseconds: 150),
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(8),
          clipBehavior: Clip.antiAlias,
          elevation: showHover ? 8 : 2,
          color: Colors.transparent,
          shadowColor: Colors.black,
          child: Material(
            color:
                widget.colorScheme?.surfaceContainerLow ??
                Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: widget.onTap,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

class _EditButton extends StatefulWidget {
  final VoidCallback onTap;
  final ValueChanged<bool> onHoverEnter;
  Color? color;

  _EditButton({required this.onTap, required this.onHoverEnter, this.color});

  @override
  State<_EditButton> createState() => _EditButtonState();
}

class _EditButtonState extends State<_EditButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        setState(() => _isHovered = true);
        widget.onHoverEnter(true);
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        widget.onHoverEnter(false);
      },
      // fixed-size hit area, no padding shift
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: AnimatedScale(
            duration: const Duration(milliseconds: 150),
            scale: _isHovered ? 1.12 : 1.0,
            child: Material(
              color:
                  widget.color ??
                  Theme.of(context).colorScheme.primaryContainer,
              shape: const CircleBorder(),
              elevation: _isHovered ? 6 : 0,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: widget.onTap,
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(Icons.edit, size: 20),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ShortcutCard extends StatefulWidget {
  final ShortcutSummary shortcutSummary;
  final void Function(Shortcut) onEdit;

  /// Called after a rename/delete so the dashboard can reload the list.
  final VoidCallback onChanged;

  const ShortcutCard({
    super.key,
    required this.shortcutSummary,
    required this.onEdit,
    required this.onChanged,
  });

  @override
  State<ShortcutCard> createState() => _ShortcutCardState();
}

class _ShortcutCardState extends State<ShortcutCard> {
  final _hoverCardKey = GlobalKey<_HoverCardState>();

  Future<void> _promptRename() async {
    final controller = TextEditingController(text: widget.shortcutSummary.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Shortcut'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Name'),
          onSubmitted: (v) => Navigator.of(context).pop(v.trim()),
          maxLength: 25,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Rename'),
          ),
        ],
      ),
    );
    if (newName == null || newName.isEmpty) return;
    try {
      await renameShortcut(widget.shortcutSummary.id, newName);
      widget.onChanged();
    } catch (e) {
      if (mounted) _showError('Rename failed: $e');
    }
  }

  Future<void> _promptDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Shortcut'),
        content: Text('Delete "${widget.shortcutSummary.name}"?'),
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
    try {
      await deleteShortcut(widget.shortcutSummary.id);
      widget.onChanged();
    } catch (e) {
      if (mounted) _showError('Delete failed: $e');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints.expand(height: 80.0),
      child: _HoverCard(
        key: _hoverCardKey,
        colorScheme: context.hue(Color(widget.shortcutSummary.color)),
        onTap: () => runShortcutWithLog(context, widget.shortcutSummary.id),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 4.0,
                          backgroundColor: context
                              .hue(Color(widget.shortcutSummary.color))
                              .primary,
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: Text(
                            widget.shortcutSummary.name,
                            style: Theme.of(context).textTheme.titleLarge,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${widget.shortcutSummary.stepCount} actions',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8.0),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                tooltip: 'Options',
                onOpened: () => _hoverCardKey.currentState?.setSuppressed(true),
                onCanceled: () =>
                    _hoverCardKey.currentState?.setSuppressed(false),
                onSelected: (value) {
                  _hoverCardKey.currentState?.setSuppressed(false);
                  if (value == 'rename') _promptRename();
                  if (value == 'delete') _promptDelete();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'rename', child: Text('Rename')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
              _EditButton(
                onTap: () {
                  // Fetch full shortcut, then hand off to the shell which
                  // swaps to the editor tab in-place (keeps the nav rail).
                  getShortcut(widget.shortcutSummary.id).then(widget.onEdit);
                },
                onHoverEnter: (hovered) {
                  _hoverCardKey.currentState?.setSuppressed(hovered);
                },
                color: context
                    .hue(Color(widget.shortcutSummary.color))
                    .primaryContainer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
