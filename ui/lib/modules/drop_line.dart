import 'package:flutter/material.dart';

class DropLine extends StatelessWidget {
  final String branchKey;
  final int index;
  final List<String> targetList;
  final void Function(String id, String branchKey, List<String> list, int index)
  onMove;

  const DropLine({
    super.key,
    required this.branchKey,
    required this.index,
    required this.targetList,
    required this.onMove,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<String>(
      onWillAcceptWithDetails: (details) => true,
      onAcceptWithDetails: (details) =>
          onMove(details.data, branchKey, targetList, index),
      builder: (context, candidateData, rejectedData) {
        final active = candidateData.isNotEmpty;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            height: active ? 4 : 0,
            margin: active ? const EdgeInsets.symmetric(vertical: 10) : null,
            decoration: BoxDecoration(
              color: active
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      },
    );
  }
}
