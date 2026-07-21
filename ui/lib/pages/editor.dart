import 'dart:convert';
import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart' hide Step;
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ui/color_map.dart';
import 'package:ui/extensions.dart';
import 'package:ui/modules/action_libary.dart';
import 'package:ui/modules/custom_tec.dart';
import 'package:ui/modules/drop_line.dart';
import 'package:ui/modules/misc.dart';
import 'package:ui/modules/resizable_container.dart';
import 'package:ui/modules/step_card.dart';
import 'package:ui/requests.dart';
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
  final ValueNotifier<String?> _draggingId = ValueNotifier(null);

  @override
  void dispose() {
    _draggingId.dispose();
    super.dispose();
  }

  final Map<String, GlobalKey> _cardKeys = {};
  GlobalKey _cardKey(String id) => _cardKeys.putIfAbsent(id, () => GlobalKey());

  bool _isDescendant(
    Map<String, Step> byId,
    String ancestorId,
    String candidateId,
  ) {
    final ancestor = byId[ancestorId];
    if (ancestor == null) return false;
    final children = <String>[];
    if (ancestor is IfStep) {
      children.addAll(ancestor.then);
      children.addAll(ancestor.else_);
    } else if (ancestor is LoopStep) {
      children.addAll(ancestor.steps);
    } else if (ancestor is RepeatStep) {
      children.addAll(ancestor.steps);
    }
    for (final c in children) {
      if (c == candidateId) return true;
      if (_isDescendant(byId, c, candidateId)) return true;
    }
    return false;
  }

  void _moveStep(
    String id,
    String branchKey,
    List<String> targetList,
    int targetIndex,
  ) {
    final shortcut = widget.shortcut;
    final byId = shortcut.stepsById();

    if (branchKey != "root") {
      final ownerId = branchKey.split(':').first;
      if (ownerId == id || _isDescendant(byId, id, ownerId)) return;
    }

    setState(() {
      int? removedFromIndex;
      for (final s in shortcut.steps) {
        List<String>? branch;
        if (s is IfStep) {
          if (s.then.contains(id))
            branch = s.then;
          else if (s.else_.contains(id))
            branch = s.else_;
        } else if (s is LoopStep) {
          if (s.steps.contains(id)) branch = s.steps;
        } else if (s is RepeatStep) {
          if (s.steps.contains(id)) branch = s.steps;
        }

        if (branch != null) {
          final idx = branch.indexOf(id);
          if (identical(branch, targetList)) removedFromIndex = idx;
          branch.removeAt(idx);
          break;
        }
      }

      if (branchKey == "root") {
        final moved = byId[id];
        shortcut.steps.removeWhere((s) => s.id == id);

        final childIds = <String>{};
        for (final s in shortcut.steps) {
          if (s is IfStep) {
            childIds.addAll(s.then);
            childIds.addAll(s.else_);
          } else if (s is LoopStep) {
            childIds.addAll(s.steps);
          } else if (s is RepeatStep) {
            childIds.addAll(s.steps);
          }
        }

        final topLevelIds = [
          for (final s in shortcut.steps)
            if (!childIds.contains(s.id)) s.id,
        ];

        if (moved != null) {
          if (targetIndex >= topLevelIds.length) {
            shortcut.steps.add(moved);
          } else {
            final anchorId = topLevelIds[targetIndex];
            final anchorPos = shortcut.steps.indexWhere(
              (s) => s.id == anchorId,
            );
            shortcut.steps.insert(anchorPos, moved);
          }
        }
      } else {
        var index = targetIndex;
        if (removedFromIndex != null && removedFromIndex < index) {
          index -= 1;
        }
        targetList.insert(index.clamp(0, targetList.length), id);
      }
    });
  }

  /// Full action definitions (with input/output schema) keyed by action id.
  /// The action-library picker only carries summaries, so we look up the
  /// schema here to seed steps and drive the inspector.
  late final Map<String, ActionDef> _actionDefs = {
    for (final def in getAllStepDefs()) def.id: def,
  };

  /// Id of the step currently shown in the inspector. Id (not list index)
  /// because steps now nest inside If branches — a flat index no longer
  /// identifies a step across the tree.
  String? _selectedId;
  bool _shortcutSelected = false;

  @override
  Widget build(BuildContext context) {
    final byId = widget.shortcut.stepsById();
    final selected = _selectedId == null ? null : byId[_selectedId];
    // Actions key by action id; control-flow steps key by their type ('if',
    // 'wait', ...), which matches the def id used in the palette.
    final selectedDef = selected == null
        ? null
        : selected is ActionStep
        ? _actionDefs[selected.actionId]
        : _actionDefs[selected.type];

    void _save(BuildContext context) {
      // Empty id = never persisted → create (POST). Otherwise update (PUT).
      final isNew = widget.shortcut.id.isEmpty;
      final request = isNew
          ? saveShortcut(widget.shortcut)
          : updateShortcut(widget.shortcut);
      request
          .then((saved) {
            // Adopt the server-minted id so subsequent saves update in place.
            setState(() => widget.shortcut.id = saved.id);
            print('saved successfully: ${saved.id}');
            showSnackBar(context, 'Saved successfully');
          })
          .catchError((e) {
            print('save failed: $e');
          });
    }

    void _editName() {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Edit Shortcut Name'),
          content: TextField(
            controller: TextEditingController(text: widget.shortcut.name),
            onChanged: (value) => setState(() => widget.shortcut.name = value),
            maxLength: 25,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: ValueListenableBuilder<String?>(
        valueListenable: _draggingId,
        builder: (context, id, child) => MouseRegion(
          cursor: id != null ? SystemMouseCursors.grabbing : MouseCursor.defer,
          child: child,
        ),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Column(
                  spacing: 16.0,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.only(
                            left: 16.0,
                            right: 16.0,
                          ),
                          child: Column(
                            // spacing: 16.0,
                            children: [
                              GestureDetector(
                                onTap: () => {
                                  setState(() {
                                    _shortcutSelected = true;
                                    _selectedId = null;
                                  }),
                                }, // show inspector to edit name and trigger
                                child: StepCard(
                                  isSelected: _shortcutSelected,
                                  label: widget.shortcut.name,
                                  icon:
                                      symbolFromName(widget.shortcut.icon) ??
                                      Icons.warning_rounded,
                                  iconColor: Theme.of(
                                    context,
                                  ).colorScheme.primaryContainer,
                                ),
                              ),
                              ..._renderIds(
                                context,
                                byId,
                                _topLevelIds(),
                                0,
                                'root',
                              ),
                              // Top-level add button — no branch, so the new step
                              // lands at the root of the flow.
                              _addActionButton(context, 0, null),
                              FloatingActionButton.extended(
                                label: Text("debug: print shortcut"),
                                onPressed: () {
                                  printObject(widget.shortcut);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    BottomAppBar(
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        spacing: 16,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    widget.shortcut.name,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.headlineMedium,
                                    textAlign: TextAlign.left,
                                  ),
                                  SizedBox(width: 4),
                                  IconButton(
                                    icon: Icon(Icons.edit),
                                    onPressed: _editName,
                                    iconSize: 16,
                                    padding: EdgeInsets.all(4),
                                    constraints: BoxConstraints(),
                                  ),
                                ],
                              ),

                              Text(
                                widget.shortcut.id.isEmpty
                                    ? 'New Shortcut'
                                    : widget.shortcut.id,
                                style: Theme.of(context)
                                    .extension<AppTextThemes>()!
                                    .mono
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withAlpha(128),
                                    ),

                                textAlign: TextAlign.left,
                              ),
                            ],
                          ),
                          Spacer(),
                          ElevatedButton(
                            child: const Text('Copy ID'),
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: widget.shortcut.id),
                              );
                              showSnackBar(context, 'ID copied to clipboard');
                            },
                          ),
                          ElevatedButton(
                            onPressed: () => _save(context),
                            style: ButtonStyle(
                              backgroundColor: WidgetStateProperty.all(
                                Theme.of(context).colorScheme.primaryContainer,
                              ),
                              foregroundColor: WidgetStateProperty.all(
                                Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                              ),
                            ),
                            child: const Text('Save'),
                          ),
                          ElevatedButton(
                            onPressed: () =>
                                runShortcutWithLog(context, widget.shortcut.id),
                            style: ButtonStyle(
                              backgroundColor: WidgetStateProperty.all(
                                Theme.of(
                                  context,
                                ).colorScheme.secondaryContainer,
                              ),
                              foregroundColor: WidgetStateProperty.all(
                                Theme.of(
                                  context,
                                ).colorScheme.onSecondaryContainer,
                              ),
                            ),
                            child: const Text('Run'),
                          ),
                        ],
                      ),
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
                      child: InspectorPanel(
                        // Rebuild inspector state when the selected step changes.
                        key: ValueKey(selected?.id),
                        def: selectedDef,
                        step: selected,
                        onDelete: selected == null
                            ? null
                            : () => setState(() {
                                _deleteStep(selected.id);
                                _selectedId = null;
                              }),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Ids of steps that no container references as a child — i.e. the root of
  /// the flow. Order follows the flat `steps` list.
  List<String> _topLevelIds() {
    final steps = widget.shortcut.steps;
    final childIds = <String>{};
    for (final s in steps) {
      if (s is IfStep) {
        childIds.addAll(s.then);
        childIds.addAll(s.else_);
      } else if (s is LoopStep) {
        childIds.addAll(s.steps);
      } else if (s is RepeatStep) {
        childIds.addAll(s.steps);
      }
    }
    return [
      for (final s in steps)
        if (!childIds.contains(s.id)) s.id,
    ];
  }

  /// Render a list of step ids at nesting [depth]. If steps expand into their
  /// THEN / ELSE branches (recursing one level deeper) capped by an "End If".
  List<Widget> _renderIds(
    BuildContext context,
    Map<String, Step> byId,
    List<String> ids,
    int depth,
    String branchKey,
  ) {
    final widgets = <Widget>[];
    widgets.add(
      DropLine(
        branchKey: branchKey,
        index: 0,
        targetList: ids,
        onMove: _moveStep,
      ),
    );
    for (int i = 0; i < ids.length; i++) {
      final id = ids[i];
      final step = byId[id];
      if (step == null) continue;
      widgets.add(_stepCard(context, step, depth));

      if (step is IfStep) {
        final childDepth = depth + 1;
        widgets
          ..add(_branchHeader(context, 'Then', childDepth))
          ..addAll(
            _renderIds(context, byId, step.then, childDepth, '${step.id}:then'),
          )
          ..add(_addActionButton(context, childDepth, step.then))
          ..add(_branchHeader(context, 'Else', childDepth))
          ..addAll(
            _renderIds(
              context,
              byId,
              step.else_,
              childDepth,
              '${step.id}:else',
            ),
          )
          ..add(_addActionButton(context, childDepth, step.else_))
          ..add(_endSection(context, depth, 'End If'));
      } else if (step is LoopStep) {
        final childDepth = depth + 1;
        widgets
          ..add(_branchHeader(context, 'Loop', childDepth))
          ..addAll(
            _renderIds(
              context,
              byId,
              step.steps,
              childDepth,
              '${step.id}:loop',
            ),
          )
          ..add(_addActionButton(context, childDepth, step.steps))
          ..add(_endSection(context, depth, 'End Loop'));
      } else if (step is RepeatStep) {
        final childDepth = depth + 1;
        widgets
          ..add(_branchHeader(context, 'Repeat', childDepth))
          ..addAll(
            _renderIds(
              context,
              byId,
              step.steps,
              childDepth,
              '${step.id}:repeat',
            ),
          )
          ..add(_addActionButton(context, childDepth, step.steps))
          ..add(_endSection(context, depth, 'End Repeat'));
      }

      widgets.add(
        DropLine(
          key: ValueKey('drop:$branchKey:${i + 1}'),
          branchKey: branchKey,
          index: i + 1,
          targetList: ids,
          onMove: _moveStep,
        ),
      );
    }
    return widgets;
  }

  /// One indented step card. Indent = 16 logical units per enclosing If.
  Widget _stepCard(BuildContext context, Step step, int depth) {
    final key = _cardKey(step.id);
    return Padding(
      padding: EdgeInsets.only(left: depth * 16.0),
      child: KeyedSubtree(
        key: key,
        child: ValueListenableBuilder<String?>(
          valueListenable: _draggingId,
          builder: (context, draggingId, child) => AnimatedOpacity(
            opacity: draggingId == step.id ? 0.35 : 1.0,
            duration: const Duration(milliseconds: 120),
            child: child,
          ),
          child: GestureDetector(
            onTap: () => setState(() {
              _selectedId = step.id;
              _shortcutSelected = false;
            }),
            child: StepCard(
              label: step.label ?? "error",
              icon: symbolFromName(step.icon) ?? Icons.warning_rounded,
              iconColor: context
                  .hue(getColor(step.color ?? "cs-error", context))
                  .primaryContainer,
              isSelected: _selectedId == step.id,
              description: step.description,
              trailing: DragHandle(
                context: context,
                stepId: step.id,
                draggingId: _draggingId,

                // feedbackCard: SizedBox(),
                // alternative design where it shows a copy of the step card
                feedbackCard: StepCardFeedback(
                  label: step.label ?? "error",
                  icon: symbolFromName(step.icon) ?? Icons.warning_rounded,
                  iconColor: context
                      .hue(getColor(step.color ?? "cs-error", context))
                      .primaryContainer,
                ),
                cardBox: () =>
                    key.currentContext?.findRenderObject() as RenderBox?,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Add button for a branch. [branch] is the container's child-id list (the
  /// If's `then`/`else`); null adds at the top level.
  Widget _addActionButton(
    BuildContext context,
    int depth,
    List<String>? branch,
  ) {
    return Padding(
      padding: EdgeInsets.only(left: depth * 16.0),
      child: AddActionButton(
        onActionSelected: (action) {
          final def = _actionDefs[action.id];
          if (def == null) return;
          setState(() {
            final step = widget.shortcut.addStep(def: def, branch: branch);
            _selectedId = step.id;
          });
        },
      ),
    );
  }

  /// "THEN" / "ELSE" category label above a branch's steps.
  Widget _branchHeader(BuildContext context, String text, int depth) {
    return Padding(
      padding: EdgeInsets.only(left: depth * 16.0, top: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            text,
            style: Theme.of(context)
                .extension<AppTextThemes>()!
                .mono
                .labelMedium
                ?.copyWith(
                  // letterSpacing: 1.0,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
          ),
        ),
      ),
    );
  }

  /// Closing marker at the If's own depth, bracketing the whole statement.
  Widget _endSection(BuildContext context, int depth, String label) {
    return Padding(
      padding: EdgeInsets.only(left: depth * 16.0, top: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: Theme.of(context)
                .extension<AppTextThemes>()!
                .mono
                .labelMedium
                ?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(180),
                ),
          ),
        ),
      ),
    );
  }

  /// Remove a step and, for containers, its whole subtree; then detach the
  /// removed ids from any parent branch lists so nothing dangles.
  void _deleteStep(String id) {
    final byId = widget.shortcut.stepsById();
    final toRemove = <String>{};
    void collect(String sid) {
      if (!toRemove.add(sid)) return;
      final s = byId[sid];
      if (s is IfStep) {
        s.then.forEach(collect);
        s.else_.forEach(collect);
      } else if (s is LoopStep) {
        s.steps.forEach(collect);
      } else if (s is RepeatStep) {
        s.steps.forEach(collect);
      }
    }

    collect(id);
    widget.shortcut.steps.removeWhere((s) => toRemove.contains(s.id));
    _cardKeys.removeWhere((k, _) => toRemove.contains(k));
    for (final s in widget.shortcut.steps) {
      if (s is IfStep) {
        s.then.removeWhere(toRemove.contains);
        s.else_.removeWhere(toRemove.contains);
      } else if (s is LoopStep) {
        s.steps.removeWhere(toRemove.contains);
      } else if (s is RepeatStep) {
        s.steps.removeWhere(toRemove.contains);
      }
    }
  }
}

// Full action definitions from the backend-written cache at
// ~/.config/quartz/actions_cache.json (includes input/output schema).
List<ActionDef> getActionDefs() {
  final home =
      Platform.environment['HOME'] ??
      Platform.environment['USERPROFILE'] ??
      '~';
  final cachePath = '$home/.config/quartz/actions_cache.json';
  final actionsMap =
      jsonDecode(File(cachePath).readAsStringSync()) as Map<String, dynamic>;

  return actionsMap.entries
      .expand<ActionDef>(
        (entry) => (entry.value as List<dynamic>).map(
          (action) => ActionDef.fromJson(action as Map<String, dynamic>),
        ),
      )
      .toList();
}

// Control-flow / special steps. Modeled as ActionDefs so they flow through the
// same palette → seed → inspector pipeline as real actions. Their `id` doubles
// as the step `type`. Branch/body containers (if.then/else, loop/repeat body)
// are child step-id lists handled on the canvas, not scalar inputs here.
List<ActionDef> getControlFlowDefs() => [
  ActionDef(
    id: 'if',
    category: 'Scripting',
    name: 'If / Else',
    description: 'Branch on a condition.',
    icon: 'arrow_split',
    color: 'cs-secondary',
    platforms: const ['linux', 'windows'],
    inputs: [
      ActionInput(
        name: 'condition',
        type: 'template',
        label: 'Condition',
        required: true,
      ),
    ],
    outputs: const [],
  ),
  ActionDef(
    id: 'loop',
    category: 'Scripting',
    name: 'Loop',
    description: 'Iterate over a list, binding each item to a variable.',
    icon: 'rotate_right',
    color: 'cs-secondary',
    platforms: const ['linux', 'windows'],
    inputs: [
      ActionInput(
        name: 'over',
        type: 'template',
        label: 'List',
        required: true,
      ),
      ActionInput(
        name: 'variable',
        type: 'string',
        label: 'Item variable',
        required: true,
        default_: 'item',
      ),
    ],
    outputs: const [],
  ),
  ActionDef(
    id: 'repeat',
    category: 'Scripting',
    name: 'Repeat',
    description: 'Run the body a fixed number of times.',
    icon: 'cycle',
    color: 'cs-secondary',
    platforms: const ['linux', 'windows'],
    inputs: [
      ActionInput(
        name: 'times',
        type: 'number',
        label: 'Times',
        required: true,
        default_: 1,
        min: 1,
      ),
    ],
    outputs: const [],
  ),
  ActionDef(
    id: 'set_var',
    category: 'Scripting',
    name: 'Set Variable',
    description: 'Assign a value to a variable.',
    icon: 'data_object',
    color: 'cs-secondary',
    platforms: const ['linux', 'windows'],
    inputs: [
      ActionInput(
        name: 'var_name',
        type: 'string',
        label: 'Name',
        required: true,
      ),
      ActionInput(
        name: 'var_type',
        type: 'choice',
        label: 'Type',
        required: true,
        default_: 'string',
        options: const ['string', 'number', 'boolean', 'list', 'auto'],
      ),
      ActionInput(name: 'value', type: 'template', label: 'Value'),
    ],
    outputs: const [],
  ),
  ActionDef(
    id: 'wait',
    category: 'Scripting',
    name: 'Wait',
    description: 'Pause before the next step.',
    icon: 'timer',
    color: 'cs-secondary',
    platforms: const ['linux', 'windows'],
    inputs: [
      ActionInput(
        name: 'duration',
        type: 'number',
        label: 'Duration (seconds)',
        required: true,
        default_: 1,
        min: 0,
      ),
    ],
    outputs: const [],
  ),
  ActionDef(
    id: 'stop',
    category: 'Scripting',
    name: 'Stop',
    description: 'Halt the shortcut.',
    icon: 'stop_circle',
    color: 'cs-secondary',
    platforms: const ['linux', 'windows'],
    inputs: [
      ActionInput(name: 'message', type: 'string', label: 'Message'),
      ActionInput(
        name: 'throwError',
        type: 'boolean',
        label: 'Throw Error',
        default_: false,
      ),
    ],
    outputs: const [],
  ),
];

// All palette entries: real actions plus control-flow steps.
List<ActionDef> getAllStepDefs() => [
  ...getActionDefs(),
  ...getControlFlowDefs(),
];

// Lightweight summaries for the action-library picker.
List<ActionSummary> getActionSummaries() => getAllStepDefs()
    .map(
      (d) => ActionSummary(
        id: d.id,
        name: d.name,
        description: d.description ?? '',
        icon: d.icon,
        color: d.color ?? 'cs-secondary',
        platforms: d.platforms,
        category: d.category,
      ),
    )
    .toList();

class AddActionButton extends StatelessWidget {
  final ValueChanged<ActionSummary>? onActionSelected;

  const AddActionButton({super.key, this.onActionSelected});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, top: 8, bottom: 8),
      child: SizedBox(
        // width: double.infinity,
        height: 60,
        child: GestureDetector(
          onTap: () async {
            final action = await showActionLibrary(
              context,
              getActionSummaries(),
            );
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
      ),
    );
  }
}

class InspectorPanel extends StatefulWidget {
  /// Schema for the selected step's action (null when nothing selected or the
  /// step is not an action step).
  final ActionDef? def;

  /// The selected step. Edits are written back through `setField`, which routes
  /// to the generic `inputs` map (actions) or typed config fields (control
  /// flow).
  final Step? step;

  /// Called when the Delete button is pressed. The parent owns the step list
  /// and its rebuild, so removal happens there.
  final VoidCallback? onDelete;

  const InspectorPanel({super.key, this.def, this.onDelete, this.step});

  @override
  State<InspectorPanel> createState() => InspectorPanelState();
}

class InspectorPanelState extends State<InspectorPanel> {
  @override
  Widget build(BuildContext context) {
    final def = widget.def;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (def != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(def.name, style: Theme.of(context).textTheme.titleMedium),
                Text(
                  widget.step?.id ?? "",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha(128),
                  ),
                ),
              ],
            ),
          ] else
            Text("Inspector", style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          if (def == null)
            Text(
              'Select a step to edit its properties.',
              style: Theme.of(context).textTheme.bodySmall,
            )
          else ...[
            Expanded(
              child: ListView(
                children: [
                  ...def.inputs.map((input) => _buildField(context, input)),
                ],
              ),
            ),
            Column(
              children: [
                Align(
                  alignment: Alignment.bottomRight,
                  child: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: widget.onDelete,
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.errorContainer,
                      foregroundColor: Theme.of(
                        context,
                      ).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
                SizedBox(height: 16.0),
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
                        if (widget.def?.outputs.isNotEmpty ?? false) ...[
                          Text(
                            "Outputs",
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.left,
                          ),
                          Wrap(
                            spacing: 8.0,
                            runSpacing: 8.0,
                            children: [
                              for (var output in widget.def!.outputs) ...[
                                Tooltip(
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHigh,
                                    borderRadius: BorderRadius.circular(4.0),
                                  ),
                                  textStyle: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                                  message:
                                      "\"${output.name}\" is of type \"${output.type}\".\nYou can reference this output using {{steps.${widget.step!.id}.${output.name}}} (click to copy)",
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
                                          text:
                                              "{{steps.${widget.step!.id}.${output.name}}}",
                                        ),
                                      );
                                      showSnackBar(
                                        context,
                                        "Copied to clipboard",
                                      );
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
          ],
        ],
      ),
    );
  }

  Widget _buildField(BuildContext context, ActionInput input) {
    final step = widget.step;
    final value = step?.getField(input.name) ?? input.default_;
    void set(dynamic v) => setState(() => step?.setField(input.name, v));

    Widget field;
    switch (input.type) {
      case 'boolean':
        field = Checkbox(value: value == true, onChanged: set);
        break;
      case 'choice':
        field = DropdownButton<String>(
          style: Theme.of(context).extension<AppTextThemes>()!.mono.bodyMedium,
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
          // onChanged: (v) => set(num.tryParse(v)),
          onChanged: set,
        );
        break;
      default: // string, path, template, and anything unknown
        field = CustomTextField(
          key: ValueKey(input.name),
          value: value?.toString() ?? '',
          onChanged: set,
          decoration: const InputDecoration(isDense: true),
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Text(
                      input.label,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      input.required ? ' *' : '',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                field,
              ],
            ),
    );
  }
}

class DragHandle extends StatelessWidget {
  final BuildContext context;
  final String stepId;
  final Widget feedbackCard;
  final RenderBox? Function() cardBox;
  final ValueNotifier<String?> draggingId;

  const DragHandle({
    super.key,
    required this.context,
    required this.stepId,
    required this.feedbackCard,
    required this.cardBox,
    required this.draggingId,
  });

  @override
  Widget build(BuildContext context) {
    return Draggable<String>(
      data: stepId,
      // dragAnchorStrategy: (draggable, context, position) {
      //   final box = cardBox();
      //   if (box == null || !box.hasSize) return Offset.zero;
      //   return box.globalToLocal(position);
      // },
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: Builder(
        builder: (_) {
          // final box = cardBox();
          // final size = box?.hasSize == true ? box!.size : const Size(320, 56);
          return Material(
            elevation: 0,
            color: Colors.transparent,
            child: feedbackCard,
          );
        },
      ),
      onDragStarted: () => draggingId.value = stepId,
      onDragEnd: (_) => draggingId.value = null,
      child: ValueListenableBuilder<String?>(
        valueListenable: draggingId,
        builder: (context, id, _) => MouseRegion(
          cursor: id == stepId
              ? SystemMouseCursors.grabbing
              : SystemMouseCursors.grab,
          child: Tooltip(
            message: "Drag to reorder",
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8),
            ),
            waitDuration: Duration(milliseconds: 750),
            textStyle: Theme.of(context).textTheme.bodyMedium,
            child: Icon(Icons.drag_handle),
          ),
        ),
      ),
    );
  }
}
