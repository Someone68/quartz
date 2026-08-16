import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quartz/extensions.dart';
import 'package:quartz/modules/misc.dart';
import 'package:quartz/requests.dart';
import 'package:quartz/types.dart';

class _HoverCard extends StatefulWidget {
  final VoidCallback onTap;
  final bool selected;
  final Widget child;
  final ColorScheme? colorScheme;

  const _HoverCard({
    super.key,
    required this.onTap,
    required this.selected,
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
    final scheme = widget.colorScheme ?? Theme.of(context).colorScheme;

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
            color: widget.selected
                ? scheme.secondaryContainer
                : scheme.surfaceContainerLow,
            // Border lives on the Material shape so selecting a card does not
            // inset its child and shift the layout.
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: widget.selected
                  ? BorderSide(color: scheme.primary, width: 2)
                  : BorderSide.none,
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              // No onDoubleTap: registering one makes every tap wait out the
              // double-tap timeout before firing. The card times taps itself.
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
  final Color? color;

  const _EditButton({
    required this.onTap,
    required this.onHoverEnter,
    this.color,
  });

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

/// Modifier keys held during a selecting click.
class SelectModifiers {
  /// Ctrl (or Meta) — toggle this card without dropping the rest.
  final bool toggle;

  /// Shift — extend the selection from the anchor to this card.
  final bool range;

  const SelectModifiers({required this.toggle, required this.range});
}

class ShortcutCard extends StatefulWidget {
  final ShortcutSummary shortcutSummary;
  final void Function(Shortcut) onEdit;

  /// Called after a rename/delete so the dashboard can reload the list.
  final VoidCallback onChanged;

  /// Whether this card is part of the dashboard's current selection.
  final bool selected;

  /// Single click — the dashboard owns the selection, this only reports intent.
  final void Function(SelectModifiers) onSelect;

  /// A run of this shortcut is in flight — the card greys out and refuses to
  /// start another one until it finishes.
  final bool running;

  const ShortcutCard({
    super.key,
    required this.shortcutSummary,
    required this.onEdit,
    required this.onChanged,
    required this.selected,
    required this.onSelect,
    this.running = false,
  });

  @override
  State<ShortcutCard> createState() => _ShortcutCardState();
}

class _ShortcutCardState extends State<ShortcutCard> {
  final _hoverCardKey = GlobalKey<_HoverCardState>();

  /// When this card was last clicked, for the hand-rolled double-click check.
  DateTime? _lastTap;

  /// Every click toggles selection right away — no waiting on a double-tap
  /// recognizer. A second click inside the double-tap window also runs, and
  /// its toggle undoes the first one, so a double click lands back where the
  /// selection started.
  void _handleTap() {
    final keys = HardwareKeyboard.instance;
    widget.onSelect(
      SelectModifiers(
        toggle: keys.isControlPressed || keys.isMetaPressed,
        range: keys.isShiftPressed,
      ),
    );

    final now = DateTime.now();
    final previous = _lastTap;
    if (previous != null && now.difference(previous) < kDoubleTapTimeout) {
      _lastTap = null;
      // Selection still works while running; only the run is blocked.
      if (!widget.running) {
        runShortcutWithLog(context, widget.shortcutSummary.id);
      }
    } else {
      _lastTap = now;
    }
  }

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
        selected: widget.selected,
        onTap: _handleTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: widget.running ? 0.45 : 1.0,
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
                          if (widget.running)
                            SizedBox(
                              width: 8.0,
                              height: 8.0,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.0,
                                color: context
                                    .hue(Color(widget.shortcutSummary.color))
                                    .primary,
                              ),
                            )
                          else
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
                  onOpened: () =>
                      _hoverCardKey.currentState?.setSuppressed(true),
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
                  color: widget.selected
                      ? context
                            .hue(Color(widget.shortcutSummary.color))
                            .surfaceContainerHigh
                      : context
                            .hue(Color(widget.shortcutSummary.color))
                            .primaryContainer,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
