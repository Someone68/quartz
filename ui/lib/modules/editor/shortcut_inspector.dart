import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart' hide Step;
import 'package:flutter/services.dart';
import 'package:ui/extensions.dart';
import 'package:ui/modules/custom_tec.dart';
import 'package:ui/modules/misc.dart';
import 'package:ui/types.dart';

class ShortcutInspector extends StatefulWidget {
  final Shortcut shortcut;
  final VoidCallback onChanged;

  const ShortcutInspector({
    super.key,
    required this.shortcut,
    required this.onChanged,
  });

  @override
  State<ShortcutInspector> createState() => _ShortcutInspectorState();
}

class _ShortcutInspectorState extends State<ShortcutInspector> {
  late final Map<String, TriggerDef> _triggerDefs;

  List<TriggerDef> getTriggerDefs() {
    final home =
        Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        '~';
    final cachePath = '$home/.config/quartz/triggers_cache.json';
    final file = File(cachePath);
    if (!file.existsSync()) return [];
    final map = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    return map.values
        .map((e) => TriggerDef.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Map<String, TriggerDef> triggerDefsByType() => {
    for (final d in getTriggerDefs()) d.type: d,
  };

  @override
  void initState() {
    super.initState();
    _triggerDefs = triggerDefsByType();
  }

  Trigger get _trigger => widget.shortcut.trigger; // assumes non-null

  void _setType(String type) {
    setState(() {
      // New type → reset config (old config keys won't match new schema).
      widget.shortcut.trigger = Trigger(type: type, config: {});
    });
    widget.onChanged();
  }

  void _setConfig(String name, dynamic v) {
    _trigger.config[name] = v; // mutate map in place
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final def = _triggerDefs[_trigger.type];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Shortcut', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),

          Text('Name', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          CustomTextField(
            value: widget.shortcut.name,
            maxLength: 25,
            onChanged: (v) {
              widget.shortcut.name = v;
              widget.onChanged();
            },
          ),
          const SizedBox(height: 16),

          Text('Trigger', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          DropdownButton<String>(
            isExpanded: true,
            style: Theme.of(
              context,
            ).extension<AppTextThemes>()?.mono.bodyMedium,
            value: kTriggerTypes.contains(_trigger.type) ? _trigger.type : null,
            items: kTriggerTypes
                .map(
                  (t) => DropdownMenuItem(
                    value: t,
                    child: Text(_triggerDefs[t]?.name ?? t),
                  ),
                )
                .toList(),
            onChanged: (t) => t == null ? null : _setType(t),
          ),
          const SizedBox(height: 16),

          // Config fields for the selected trigger type. Always Expanded so the
          // outputs box below stays pinned to the bottom, even with no fields.
          Expanded(
            child: def != null
                ? ListView(
                    children: def.inputs
                        .map((i) => _triggerField(context, i))
                        .toList(),
                  )
                : _trigger.type != "manual"
                ? Text(
                    'No config schema for "${_trigger.type}".',
                    style: Theme.of(context).textTheme.bodySmall,
                  )
                : const SizedBox.shrink(),
          ),

          Align(
            alignment: Alignment.bottomLeft,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8.0),
              ),
              padding: EdgeInsets.all(16.0),
              width: double.infinity,
              child: Column(
                spacing: 8.0,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (def?.outputs.isNotEmpty ?? false) ...[
                    Text(
                      "Trigger outputs",
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.left,
                    ),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: [
                        for (var output in def!.outputs) ...[
                          Tooltip(
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            textStyle: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            message:
                                "\"${output.name}\" is of type \"${output.type}\".\nYou can reference this output using {{trigger.${output.name}}} (click to copy)",
                            child: TinyChipButton(
                              label: output.name,
                              color: output.type == "string"
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer
                                  : output.type == "number"
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.secondaryContainer
                                  : output.type == "boolean"
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.tertiaryContainer
                                  : Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainer,
                              context: context,
                              onTap: () {
                                Clipboard.setData(
                                  ClipboardData(
                                    text: "{{trigger.${output.name}}}",
                                  ),
                                );
                                showSnackBar(context, "Copied to clipboard");
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ] else
                    Text(
                      "No outputs",
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.left,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _triggerField(BuildContext context, TriggerInput input) {
    final value = _trigger.config[input.name] ?? input.default_;
    void set(dynamic v) => setState(() => _setConfig(input.name, v));

    Widget field;
    switch (input.type) {
      case 'boolean':
        field = Checkbox(value: value == true, onChanged: set);
        break;
      case 'choice':
        field = DropdownButton<String>(
          isExpanded: true,
          value: (input.options?.contains(value) ?? false)
              ? value as String
              : null,
          items: (input.options ?? [])
              .map((o) => DropdownMenuItem(value: o, child: Text(o)))
              .toList(),
          onChanged: set,
        );
        break;
      case 'number':
        field = CustomTextField(
          key: ValueKey(input.name),
          value: value?.toString() ?? '',
          decoration: const InputDecoration(isDense: true),
          onChanged: (v) => set(num.tryParse(v)),
        );
        break;
      default: // string, path, template, dynamic, unknown
        field = CustomTextField(
          key: ValueKey(input.name),
          value: value?.toString() ?? '',
          onChanged: set,
        );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: input.type != 'boolean'
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      input.label,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    Text(
                      input.required ? ' *' : '',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                field,
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  input.label,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(width: 8),
                field,
              ],
            ),
    );
  }
}
