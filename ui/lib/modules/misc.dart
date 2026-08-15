import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/iconname_to_unicode_map.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:quartz/modules/app_picker.dart';
import 'package:quartz/requests.dart';
import 'package:quartz/types.dart';

Container buildStyledIcon(
  BuildContext context,
  Color color,
  IconData? icon, {
  double size = 32,
}) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.all(Radius.circular(size / 4)),
      color: color,
    ),
    child: icon != null ? Icon(icon, size: size * 0.75) : null,
  );
}

/// Readable foreground for an arbitrary user-picked background colour.
Color onColorFor(Color background) =>
    ThemeData.estimateBrightnessForColor(background) == Brightness.dark
    ? Colors.white
    : Colors.black;

IconData? symbolFromName(String? name) {
  final codepoint =
      materialSymbolsIconNameToUnicodeMap[name]; // verify exact map name after import
  if (codepoint == null) return null;
  // Icons are named at run time by the backend schema, so the code point can't
  // be a literal. Build with --no-tree-shake-icons or these render as boxes.
  return IconData(
    // ignore: non_const_argument_for_const_parameter
    codepoint,
    fontFamily: 'MaterialSymbolsOutlined', // or Rounded / Sharp
    fontPackage: 'material_symbols_icons',
  );
}

void printObject(dynamic obj) {
  if (obj is Map) {
    obj.forEach((key, value) => debugPrint('$key: $value'));
  } else {
    try {
      printObject(obj.toJson());
    } catch (e) {
      debugPrint(obj.toString());
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
        // The run is async; the caller's page may be gone by the time it ends.
        if (!context.mounted) return;
        if (log.status != 'success' && log.status != 'stopped') {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Run Failed'),
              content: Text('${log.status}: ${log.error}'),
              actions: [
                TextButton(
                  onPressed: () => {
                    Clipboard.setData(
                      ClipboardData(text: '${log.status}: ${log.error}'),
                    ),
                    Navigator.of(context).pop(),
                  },
                  child: const Text('Copy'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
        // debugPrint('run log: ');
        // printObject(log);
      })
      .catchError((e) {
        if (!context.mounted) return;
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

/// Label + required marker + optional help tooltip for one inspector field.
/// Shared so action inputs and trigger inputs stay identical; both inspectors
/// use it for every field type, including booleans.
class InputLabelRow extends StatelessWidget {
  final String label;
  final bool required;
  final String? tooltip;
  final TextStyle? style;

  const InputLabelRow({
    super.key,
    required this.label,
    this.required = false,
    this.tooltip,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final tip = tooltip;
    return Row(
      children: [
        Text(label, style: style ?? Theme.of(context).textTheme.labelMedium),
        if (required)
          Text(
            ' *',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        if (tip != null && tip.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: buildStyledTooltip(
              context: context,
              message: tip,
              child: const Icon(Symbols.help, size: 16),
            ),
          ),
      ],
    );
  }
}

class TinyChip extends StatelessWidget {
  final String label;
  final Color color;
  final TextStyle? style;
  final BuildContext context;

  const TinyChip({
    super.key,
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
    super.key,
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

class TimePickerField extends StatefulWidget {
  final TimeOfDay? initial;
  final ValueChanged<DateTime>? onChanged;
  const TimePickerField({super.key, this.initial, this.onChanged});

  @override
  State<TimePickerField> createState() => _TimePickerFieldState();
}

class _TimePickerFieldState extends State<TimePickerField> {
  TimeOfDay? _time;

  @override
  void initState() {
    super.initState();
    _time = widget.initial;
  }

  DateTime _toDateTime(TimeOfDay t) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, t.hour, t.minute);
  }

  Future<void> _pick() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _time = picked);
      widget.onChanged?.call(_toDateTime(picked)); // DateTime, not TimeOfDay
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _pick,
      child: InputDecorator(
        decoration: const InputDecoration(
          suffixIcon: Icon(Icons.access_time),
          border: OutlineInputBorder(),
        ),
        child: Text(_time != null ? _time!.format(context) : 'Select time'),
      ),
    );
  }
}

Widget buildStyledTooltip({
  required String message,
  required Widget child,
  TextStyle? textStyle,
  Decoration? decoration,
  Duration? waitDuration,
  Duration? exitDuration,
  required BuildContext context,
}) {
  return Tooltip(
    enableTapToDismiss: true,
    ignorePointer: true,
    decoration:
        decoration ??
        BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(4.0),
        ),
    textStyle:
        textStyle ?? TextStyle(color: Theme.of(context).colorScheme.onSurface),
    richMessage: message.isNotEmpty ? TextSpan(text: message) : null,
    constraints: BoxConstraints(maxWidth: 400),
    waitDuration: waitDuration,
    exitDuration: exitDuration,
    child: child,
  );
}

/// Show the installed-app list in a bottom sheet and return the app the user
/// picked, or null if they dismissed the sheet.
///
/// The sheet is scroll-controlled and given an explicit height because
/// [AppPicker] puts its list in an [Expanded], which needs a bounded box.
Future<AppEntry?> showAppPicker(
  BuildContext context, {
  double heightFactor = 0.7,
  Function(AppEntry)? onSelect,
}) {
  return showModalBottomSheet<AppEntry>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) => Padding(
      // Keep the search field clear of the on-screen keyboard / IME panel.
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
      ),
      child: SizedBox(
        height: MediaQuery.of(sheetContext).size.height * heightFactor,
        child: AppPicker(
          onSelect: (app) {
            Navigator.pop(sheetContext, app);
            onSelect?.call(app);
          },
        ),
      ),
    ),
  );
}

String truncate(String s, int max) =>
    s.length <= max ? s : '${s.substring(0, max)}...';
