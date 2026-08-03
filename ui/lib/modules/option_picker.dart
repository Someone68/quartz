import 'package:flutter/material.dart';
import 'package:quartz/extensions.dart';

/// Searchable list of plain string options.
///
/// Used instead of [DropdownMenu] for large option sets (timezones, locales,
/// ...). [DropdownMenu] mounts every entry twice — once offstage to measure the
/// widest label, once in the menu panel — and neither list is lazy, so a few
/// hundred options stall every layout pass. This builds only the visible rows.
class OptionPicker extends StatefulWidget {
  final List<String> options;
  final String? selected;
  final String hintText;
  final ValueChanged<String> onSelect;

  const OptionPicker({
    super.key,
    required this.options,
    required this.onSelect,
    this.selected,
    this.hintText = 'Search',
  });

  @override
  State<OptionPicker> createState() => _OptionPickerState();
}

class _OptionPickerState extends State<OptionPicker> {
  late List<String> _shown = widget.options;
  late final List<String> _lower = [
    for (final o in widget.options) o.toLowerCase(),
  ];

  void _filter(String q) {
    q = q.toLowerCase().trim();
    setState(() {
      _shown = q.isEmpty
          ? widget.options
          : [
              for (var i = 0; i < widget.options.length; i++)
                if (_lower[i].contains(q)) widget.options[i],
            ];
    });
  }

  @override
  Widget build(BuildContext context) {
    final mono = Theme.of(context).extension<AppTextThemes>()!.mono.bodyMedium;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: TextField(
            autofocus: true,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: widget.hintText,
            ),
            onChanged: _filter,
          ),
        ),
        Expanded(
          child: ListView.builder(
            // builds only visible rows
            itemCount: _shown.length,
            itemExtent: 44, // fixed height = faster layout
            itemBuilder: (_, i) {
              final o = _shown[i];
              return ListTile(
                dense: true,
                selected: o == widget.selected,
                title: Text(o, style: mono, overflow: TextOverflow.ellipsis),
                onTap: () => widget.onSelect(o),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Show [OptionPicker] in a bottom sheet and return the picked option, or null
/// if the sheet was dismissed.
Future<String?> showOptionPicker(
  BuildContext context, {
  required List<String> options,
  String? selected,
  String hintText = 'Search',
  double heightFactor = 0.7,
  ValueChanged<String>? onSelect,
}) {
  return showModalBottomSheet<String>(
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
        // OptionPicker puts its list in an Expanded, which needs a bounded box.
        height: MediaQuery.of(sheetContext).size.height * heightFactor,
        child: OptionPicker(
          options: options,
          selected: selected,
          hintText: hintText,
          onSelect: (o) {
            Navigator.pop(sheetContext, o);
            onSelect?.call(o);
          },
        ),
      ),
    ),
  );
}
