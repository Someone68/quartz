import 'package:flutter/material.dart' hide Step;

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
