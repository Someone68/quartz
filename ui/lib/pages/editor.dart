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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(spacing: 16.0, children: [StepCard()]),
      ),
    );
  }
}
