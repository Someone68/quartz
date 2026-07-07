import 'package:flutter/material.dart';

final Map<String, Color> colorMap = {
  'red': Colors.red,
  'orange': Colors.orange,
  'amber': Colors.amber,
  'yellow': Colors.yellow,
  'green': Colors.green,
  'lime': Colors.lime,
  'teal': Colors.teal,
  'blue': Colors.blue,
  'purple': Colors.purple,
  'pink': Colors.pink,
  'cyan': Colors.cyan,
};

Color getColor(String name, BuildContext context) {
  switch (name) {
    case "cs-primary":
      return Theme.of(context).colorScheme.primary;
    case "cs-secondary":
      return Theme.of(context).colorScheme.secondary;
    case "cs-tertiary":
      return Theme.of(context).colorScheme.tertiary;
    case "cs-error":
      return Theme.of(context).colorScheme.error;
    default:
      return colorMap[name.toLowerCase()] ??
          Theme.of(context).colorScheme.primary;
  }
}
