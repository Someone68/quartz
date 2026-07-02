import 'package:flutter/material.dart';

extension HueScheme on BuildContext {
  ColorScheme hue(Color seed) => ColorScheme.fromSeed(
    seedColor: seed,
    brightness: Theme.of(this).brightness,
  );
}
