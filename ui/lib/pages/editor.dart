import 'package:flutter/material.dart';
import 'package:ui/modules/step_card.dart';

/// Shortcut editor — trigger + step list. Placeholder until the builder UI
/// lands.
class EditorPage extends StatelessWidget {
  const EditorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editor')),
      body: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                spacing: 16.0,
                children: [
                  StepCard(
                    label: "test",
                    icon: Icons.star,
                    iconColor: Theme.of(context).colorScheme.primaryContainer,
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: 280,
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: InspectorPanel(),
          ),
        ],
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
