import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:ui/modules/resizable_container.dart';
import 'package:ui/modules/step_card.dart';

/// Shortcut editor — trigger + step list. Placeholder until the builder UI
/// lands.
class EditorPage extends StatelessWidget {
  const EditorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: const Text('Editor')),
      body: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                top: 16.0,
              ),
              child: Column(
                spacing: 16.0,
                children: [
                  StepCard(
                    label: "test",
                    icon: Icons.star_rounded,
                    iconColor: Theme.of(context).colorScheme.primaryContainer,
                  ),
                  AddActionButton(),
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
                    child: InspectorPanel(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AddActionButton extends StatelessWidget {
  const AddActionButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // width: double.infinity,
      height: 60,
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
