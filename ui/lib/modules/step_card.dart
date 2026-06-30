import 'package:flutter/material.dart';

class StepCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? iconColor;
  final bool isSelected;

  const StepCard({
    super.key,
    required this.icon,
    required this.label,
    this.iconColor,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        color: isSelected
            ? Theme.of(context).colorScheme.secondaryContainer
            : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 60),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.all(Radius.circular(8)),
                      color:
                          iconColor ??
                          Theme.of(context).colorScheme.primaryContainer,
                    ),
                    child: Icon(icon, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Text(label, style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// TODO: add flow control (if statements and stuff)
