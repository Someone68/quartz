import 'package:flutter/material.dart';

class Trigger {
  final String type;
  final Map<String, dynamic> config;

  Trigger({required this.type, this.config = const {}});
}

class Step {
  final String id;
  final String type;
  final String label;
  final bool enabled;

  Step({
    required this.id,
    required this.type,
    required this.label,
    required this.enabled,
  });
}

class Shortcut {
  final String id;
  final String name;
  final String description;
  final String icon;
  final bool enabled;
  final Trigger trigger;
  final List<Step> steps;

  Shortcut({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.enabled,
    required this.trigger,
    required this.steps,
  });
}

class ShortcutSummary {
  final String id;
  final String name;
  final String icon;
  final int stepCount;

  ShortcutSummary({
    required this.id,
    required this.name,
    required this.icon,
    required this.stepCount,
  });
}
