import 'package:flutter/material.dart';
import 'package:material_symbols_icons/iconname_to_unicode_map.dart';

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

  @override
  void initState() {
    super.initState();
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
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = widget.theme.colorScheme;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
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
