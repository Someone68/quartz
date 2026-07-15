import 'package:flutter/material.dart';
import 'package:material_symbols_icons/iconname_to_unicode_map.dart';
import 'package:ui/requests.dart';

Container buildStyledIcon(BuildContext context, Color color, IconData? icon) {
  return Container(
    width: 32,
    height: 32,
    decoration: BoxDecoration(
      borderRadius: const BorderRadius.all(Radius.circular(8)),
      color: color,
    ),
    child: icon != null ? Icon(icon, size: 24) : null,
  );
}

IconData? symbolFromName(String? name) {
  final codepoint =
      materialSymbolsIconNameToUnicodeMap[name]; // verify exact map name after import
  if (codepoint == null) return null;
  return IconData(
    codepoint,
    fontFamily: 'MaterialSymbolsOutlined', // or Rounded / Sharp
    fontPackage: 'material_symbols_icons',
  );
}

void printObject(dynamic obj) {
  if (obj is Map) {
    obj.forEach((key, value) => print('$key: $value'));
  } else {
    try {
      printObject(obj.toJson());
    } catch (e) {
      print(obj.toString());
    }
  }
}

class _NotificationManager {
  static final List<_TopNotificationState> _active = [];

  static double topOffsetFor(_TopNotificationState state) {
    final index = _active.indexOf(state);
    return index * 64.0; // slot height, adjust to your content height
  }

  static void register(_TopNotificationState state) {
    _active.add(state);
  }

  static void unregister(_TopNotificationState state) {
    _active.remove(state);
    for (final s in _active) {
      s.reposition();
    }
  }
}

void showSnackBar(BuildContext context, String message) {
  final overlay = Overlay.of(context);
  final theme = Theme.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => _TopNotification(
      message: message,
      theme: theme,
      onDismiss: () => entry.remove(),
    ),
  );
  overlay.insert(entry);
}

class _TopNotification extends StatefulWidget {
  final String message;
  final ThemeData theme;
  final VoidCallback onDismiss;
  const _TopNotification({
    required this.message,
    required this.theme,
    required this.onDismiss,
  });
  @override
  State<_TopNotification> createState() => _TopNotificationState();
}

class _TopNotificationState extends State<_TopNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offset;
  double _topOffset = 0;

  @override
  void initState() {
    super.initState();
    _NotificationManager.register(this);
    _topOffset = _NotificationManager.topOffsetFor(this);

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _offset = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
    Future.delayed(const Duration(seconds: 3), () async {
      if (mounted) {
        await _controller.reverse();
        _NotificationManager.unregister(this);
        widget.onDismiss();
      }
    });
  }

  void reposition() {
    if (mounted) {
      setState(() {
        _topOffset = _NotificationManager.topOffsetFor(this);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = widget.theme.colorScheme;
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 200),
      top: MediaQuery.of(context).padding.top + 16 + _topOffset,
      right: 16,
      child: SlideTransition(
        position: _offset,
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 360),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(40),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline, color: colorScheme.primary),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    widget.message,
                    style: widget.theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void runShortcutWithLog(BuildContext context, String shortcutId) {
  runShortcut(shortcutId)
      .then((log) {
        if (log.status != 'success' && log.status != 'stopped') {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Run Failed'),
              content: Text('${log.status}: ${log.error}'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
        print('run log: ');
        printObject(log);
      })
      .catchError((e) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Run Failed'),
            content: Text('$e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      });
}

class TinyChip extends StatelessWidget {
  final String label;
  final Color color;
  final TextStyle? style;
  final BuildContext context;

  const TinyChip({
    required this.label,
    required this.color,
    required this.context,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Text(
        label,
        style: style ?? Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

class TinyChipButton extends StatelessWidget {
  final String label;
  final Color color;
  final TextStyle? style;
  final BuildContext context;
  final VoidCallback? onTap;

  const TinyChipButton({
    required this.label,
    required this.color,
    required this.context,
    this.style,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: TinyChip(
          label: label,
          color: color,
          context: context,
          style: style,
        ),
      ),
    );
  }
}
