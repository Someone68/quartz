import 'package:flutter/material.dart';

extension HueScheme on BuildContext {
  ColorScheme hue(Color seed) => ColorScheme.fromSeed(
    seedColor: seed,
    brightness: Theme.of(this).brightness,
  );
}

class AppTextThemes extends ThemeExtension<AppTextThemes> {
  final TextTheme mono;

  const AppTextThemes({required this.mono});

  @override
  AppTextThemes copyWith({TextTheme? mono}) {
    return AppTextThemes(mono: mono ?? this.mono);
  }

  @override
  AppTextThemes lerp(ThemeExtension<AppTextThemes>? other, double t) {
    if (other is! AppTextThemes) return this;
    return AppTextThemes(mono: TextTheme.lerp(mono, other.mono, t)!);
  }
}
