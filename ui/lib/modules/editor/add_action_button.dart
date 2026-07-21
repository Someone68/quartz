import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart' hide Step;
import 'package:ui/modules/action_libary.dart';
import 'package:ui/modules/editor/step_defs.dart';
import 'package:ui/types.dart';

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
