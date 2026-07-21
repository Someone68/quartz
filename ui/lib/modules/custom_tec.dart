import 'package:flutter/material.dart';
import 'package:ui/extensions.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class CustomTextEditingController extends TextEditingController {
  CustomTextEditingController({String? text}) {
    if (text != null) setRaw(text);
  }

  static const int _puaBase = 0xE000;
  static const int _puaCount = 6400;
  static final RegExp _pattern = RegExp(r'\{\{(.*?)\}\}');

  final Map<int, String> _chips = {};
  int _nextId = 0;

  int? _idOf(int codeUnit) {
    final id = codeUnit - _puaBase;
    return (id >= 0 && id < _puaCount) ? id : null;
  }

  String get rawText {
    final b = StringBuffer();
    for (final u in text.codeUnits) {
      final name = _chips[_idOf(u) ?? -1];
      if (name != null) {
        b.write('{{$name}}');
      } else {
        b.writeCharCode(u);
      }
    }
    return b.toString();
  }

  void setRaw(String raw) {
    value = TextEditingValue(text: raw);
    super.value = value.copyWith(
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  @override
  set value(TextEditingValue newValue) {
    var v = _reviveDeleted(value, newValue);
    v = _collapseUntouched(v);
    super.value = v;
  }

  TextEditingValue _reviveDeleted(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.length != oldValue.text.length - 1) {
      return newValue;
    }
    var i = 0;
    while (i < newValue.text.length &&
        newValue.text.codeUnitAt(i) == oldValue.text.codeUnitAt(i)) {
      i++;
    }
    final id = _idOf(oldValue.text.codeUnitAt(i));
    final name = id == null ? null : _chips.remove(id);
    if (name == null) return newValue;
    final raw = '{{$name}}';
    return TextEditingValue(
      text: newValue.text.replaceRange(i, i, raw),
      selection: TextSelection.collapsed(offset: i + raw.length),
    );
  }

  TextEditingValue _collapseUntouched(TextEditingValue v) {
    var text = v.text;
    var sel = v.selection;
    for (final m in _pattern.allMatches(v.text).toList().reversed) {
      final touches = sel.isValid && sel.start <= m.end && sel.end >= m.start;
      if (touches) continue;
      final id = _nextId;
      _nextId = (_nextId + 1) % _puaCount;
      _chips[id] = m.group(1)!;
      text = text.replaceRange(
        m.start,
        m.end,
        String.fromCharCode(_puaBase + id),
      );
      sel = _shift(sel, m.start, m.end, 1);
    }
    return TextEditingValue(text: text, selection: sel);
  }

  TextSelection _shift(TextSelection s, int start, int end, int newLen) {
    if (!s.isValid) return s;
    final delta = newLen - (end - start);
    int adj(int o) => o <= start ? o : (o >= end ? o + delta : start);
    return TextSelection(
      baseOffset: adj(s.baseOffset),
      extentOffset: adj(s.extentOffset),
    );
  }

  void expandAt(int index) {
    final id = _idOf(text.codeUnitAt(index));
    final name = id == null ? null : _chips.remove(id);
    if (name == null) return;
    final raw = '{{$name}}';
    super.value = TextEditingValue(
      text: text.replaceRange(index, index + 1, raw),
      selection: TextSelection.collapsed(offset: index + raw.length),
    );
  }

  void collapseAll() {
    final collapsed = _collapseUntouched(
      TextEditingValue(
        text: text,
        selection: const TextSelection.collapsed(offset: -1),
      ),
    );
    if (collapsed.text == text) return;
    super.value = TextEditingValue(
      text: collapsed.text,
      selection: const TextSelection.collapsed(offset: -1),
    );
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    bool withComposing = false,
  }) {
    final children = <InlineSpan>[];
    final buf = StringBuffer();

    void flush() {
      if (buf.isNotEmpty) {
        children.add(TextSpan(text: buf.toString(), style: style));
        buf.clear();
      }
    }

    for (var i = 0; i < text.length; i++) {
      final u = text.codeUnitAt(i);
      final name = _chips[_idOf(u) ?? -1];
      if (name == null) {
        buf.writeCharCode(u);
        continue;
      }
      flush();
      final index = i;
      children.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: GestureDetector(
            onTap: () => expandAt(index),
            child: _VarChip(path: name),
          ),
        ),
      );
    }
    flush();
    return TextSpan(children: children, style: style);
  }
}

class _VarChip extends StatelessWidget {
  final String path;

  const _VarChip({required this.path});

  static (IconData, String, String) _parse(String path) {
    final dot = path.indexOf('.');
    if (dot <= 0 || dot == path.length - 1) {
      return (Icons.help_outline, path, "");
    }
    final ns = path.substring(0, dot);
    final rest = path.substring(dot + 1);
    switch (ns) {
      case 'variables':
        return (Symbols.data_object, rest, "variable");
      case 'steps':
        return (Symbols.graph_8, rest, "step");
      default:
        return (
          Symbols.help_center,
          path,
          "unknown",
        ); // unknown namespace, show it all
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, text, ns) = _parse(path);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: ns == "variable"
            ? theme.colorScheme.primaryContainer
            : ns == "step"
            ? theme.colorScheme.secondaryContainer
            : theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: ns == "variable"
                ? theme.colorScheme.onPrimaryContainer
                : ns == "step"
                ? theme.colorScheme.onSecondaryContainer
                : theme.colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 3),
          Text(text, style: theme.extension<AppTextThemes>()!.mono.bodyMedium),
        ],
      ),
    );
  }
}

class CustomTextField extends StatefulWidget {
  const CustomTextField({
    super.key,
    required this.value,
    required this.onChanged,
    this.decoration = const InputDecoration(isDense: true),
    this.maxLength,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final InputDecoration decoration;
  final int? maxLength;

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late final CustomTextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = CustomTextEditingController(text: widget.value);
    _focusNode = FocusNode()..addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) _controller.collapseAll();
  }

  @override
  void didUpdateWidget(CustomTextField old) {
    super.didUpdateWidget(old);
    if (widget.value != _controller.rawText) {
      _controller.setRaw(widget.value);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      style: Theme.of(context).extension<AppTextThemes>()!.mono.bodyMedium,
      controller: _controller,
      focusNode: _focusNode,
      decoration: widget.decoration,
      maxLines: null,
      maxLength: widget.maxLength,
      onChanged: (_) => widget.onChanged(_controller.rawText),
    );
  }
}
