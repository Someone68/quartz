import 'package:flutter/material.dart';
import 'package:ui/modules/misc.dart';

class StepCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? description;
  final Color? iconColor;
  final bool isSelected;

  const StepCard({
    super.key,
    required this.icon,
    required this.label,
    this.description,
    this.iconColor,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final card = Card(
      color: isSelected
          ? Theme.of(context).colorScheme.secondaryContainer
          : null,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 40),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                buildStyledIcon(
                  context,
                  iconColor ?? Theme.of(context).colorScheme.primaryContainer,
                  icon,
                ),
                const SizedBox(width: 16),
                Text(label, style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          ),
        ),
      ),
    );

    final desc = description;
    return SizedBox(
      width: double.infinity,
      // Wrap in a Tooltip only when a description exists; Tooltip asserts a
      // non-null message.
      child: (desc != null && desc.isNotEmpty)
          ? Tooltip(message: desc, child: card)
          : card,
    );
  }
}

// TODO: add flow control (if statements and stuff)
