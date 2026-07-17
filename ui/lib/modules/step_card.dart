import 'package:flutter/material.dart' hide Step;
import 'package:ui/color_map.dart';
import 'package:ui/extensions.dart';
import 'package:ui/modules/misc.dart';
import 'package:ui/types.dart';

class StepCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? description;
  final Color? iconColor;
  final Widget? trailing;
  final bool isSelected;
  final double opacity;

  const StepCard({
    super.key,
    required this.icon,
    required this.label,
    this.description,
    this.iconColor,
    this.isSelected = false,
    this.trailing,
    this.opacity = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final card = Card(
      color: isSelected
          ? Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: opacity)
          : Theme.of(
              context,
            ).colorScheme.surfaceContainer.withValues(alpha: opacity),
      elevation: opacity < 1 ? 0 : null,
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

class StepCardFeedback extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? iconColor;

  const StepCardFeedback({
    required this.icon,
    required this.label,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 30, maxWidth: 320),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              buildStyledIcon(
                context,
                iconColor ?? Theme.of(context).colorScheme.primaryContainer,
                icon,
                size: 20,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
