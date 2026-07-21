import 'package:flutter/material.dart' hide Step;
import 'package:flutter/services.dart';
import 'package:ui/color_map.dart';
import 'package:ui/extensions.dart';
import 'package:ui/modules/drop_line.dart';
import 'package:ui/modules/editor/add_action_button.dart';
import 'package:ui/modules/editor/drag_handle.dart';
import 'package:ui/modules/editor/inspector_panel.dart';
import 'package:ui/modules/editor/shortcut_inspector.dart';
import 'package:ui/modules/editor/step_defs.dart';
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
                      child: _shortcutSelected
                          ? ShortcutInspector(
                              shortcut: widget.shortcut,
                              onChanged: () => setState(() {}),
                            )
                          : InspectorPanel(
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
