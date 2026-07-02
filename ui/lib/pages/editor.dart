import 'dart:convert';
import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:ui/modules/action_libary.dart';
import 'package:ui/modules/misc.dart';
import 'package:ui/modules/resizable_container.dart';
import 'package:ui/modules/step_card.dart';
import 'package:ui/types.dart';

/// Shortcut editor — trigger + step list. Placeholder until the builder UI
/// lands.

class EditorPage extends StatefulWidget {
  final Shortcut shortcut;

  const EditorPage({super.key, required this.shortcut});

  @override
  State<EditorPage> createState() => EditorPageState();
}

class EditorPageState extends State<EditorPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: const Text('Editor')),
      body: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                top: 16.0,
              ),
              child: Column(
                spacing: 16.0,
                children: [
                  ...widget.shortcut.steps
                      .map(
                        (s) => StepCard(
                          label: s.label ?? "error",
                          icon: symbolFromName(s.icon) ?? Icons.warning_rounded,
                          iconColor: Theme.of(
                            context,
                          ).colorScheme.primaryContainer,
                        ),
                      )
                      .toList(),
                  AddActionButton(
                    onActionSelected: (action) {
                      widget.shortcut.addActionStep(action: action);
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),
          ),
          Column(
            children: [
              Expanded(
                child: ResizableContainer(
                  resizeFromLeft: true,
                  initialWidth: 280,
                  minWidth: 250,
                  maxWidth: 600,
                  height: double.infinity,
                  handleWidth: 6,
                  handleColor: Theme.of(context).colorScheme.surfaceBright,
                  child: Container(
                    width: 280,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainer,
                    ),
                    child: InspectorPanel(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// get action summaries from tmp_actions_list.json
List<ActionSummary> getActionSummaries() {
  final actionsMap =
      jsonDecode(File('lib/tmp_actions_list.json').readAsStringSync())
          as Map<String, dynamic>;

  return actionsMap.entries
      .expand<ActionSummary>(
        (entry) => (entry.value as List<dynamic>).map(
          (action) => ActionSummary(
            id: action['id'],
            name: action['name'],
            description: action['description'],
            icon: action['icon'],
            platforms: List<String>.from(action['platforms']),
            category: entry.key,
          ),
        ),
      )
      .toList();
}

class AddActionButton extends StatelessWidget {
  final ValueChanged<ActionSummary>? onActionSelected;

  const AddActionButton({super.key, this.onActionSelected});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // width: double.infinity,
      height: 60,
      child: GestureDetector(
        onTap: () async {
          final action = await showActionLibrary(context, getActionSummaries());
          if (action != null) onActionSelected?.call(action);
        },
        child: DottedBorder(
          color: Theme.of(context).colorScheme.surfaceBright,
          strokeWidth: 2,
          dashPattern: const [8, 4], // dash, gap
          borderType: BorderType.RRect,
          radius: const Radius.circular(8),
          child: Container(
            color: Theme.of(context).colorScheme.surface,
            padding: const EdgeInsets.all(0.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 60),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Icon(Icons.add, size: 24),
                      const SizedBox(width: 16),
                      Text(
                        "Add Action",
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class InspectorPanel extends StatelessWidget {
  const InspectorPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Inspector', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          // step fields go here
        ],
      ),
    );
  }
}
