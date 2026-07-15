import 'package:flutter/material.dart';
import 'package:ui/modules/misc.dart';

class StepCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? description;
  final Color? iconColor;
  final Widget? trailing;
  final bool isSelected;

  const StepCard({
    super.key,
    required this.icon,
    required this.label,
    this.description,
    this.iconColor,
    this.isSelected = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final card = Card(
      color: isSelected
          ? Theme.of(context).colorScheme.surfaceContainerHighest
          : null,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 40),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              buildStyledIcon(
                context,
                iconColor ?? Theme.of(context).colorScheme.primaryContainer,
                icon,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              if (trailing != null) trailing!,
            ],
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
