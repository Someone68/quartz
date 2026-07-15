import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme_notifier.dart';

/// App settings. Currently just theme controls; more to follow.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeNotifier>();
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text('Dark mode'),
            value: theme.mode == ThemeMode.dark,
            onChanged: (_) => theme.toggle(),
          ),
          ListTile(
            leading: const Icon(Icons.color_lens_outlined),
            title: const Text('Theme color'),
            trailing: ColorIndicator(color: theme.seed),
          ),
          ColorPicker(
            color: theme.seed,
            crossAxisAlignment: CrossAxisAlignment.start,
            enableShadesSelection: false,
            pickersEnabled: const {
              ColorPickerType.wheel: false,
              ColorPickerType.primary: true,
              ColorPickerType.accent: false,
            },
            onColorChanged: (c) => theme.setSeed(c),
          ),
        ],
      ),
    );
  }
}
