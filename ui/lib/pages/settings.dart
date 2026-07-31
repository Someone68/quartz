import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';
import 'package:quartz/modules/misc.dart';
import 'package:quartz/requests.dart';
import 'dart:io';

import '../config.dart';
import '../theme_notifier.dart';

/// Where the backend writes run logs — under its config dir, not a
/// platform-specific one.
String runLogsPath() => quartzConfigPath('runs');

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => SettingsPageState();
}

/// App settings. Currently just theme controls; more to follow.
class SettingsPageState extends State<SettingsPage> {
  Map<String, dynamic>? _config;

  // The config arrives after the first build, so the field is driven by a
  // controller — TextFormField.initialValue is only read once and would leave
  // the box empty forever.
  final _portController = TextEditingController();
  final _portFocus = FocusNode();

  Future<void> _loadConfig() async {
    final config = await getConfig();
    if (!mounted) return;
    setState(() {
      _config = config;
      _portController.text = config['port'].toString();
    });
  }

  @override
  void initState() {
    super.initState();
    _loadConfig();
    // Commit on focus loss too; typing a port and clicking away is as much a
    // "done" signal as pressing enter.
    _portFocus.addListener(() {
      if (!_portFocus.hasFocus) _savePort(_portController.text);
    });
  }

  @override
  void dispose() {
    _portController.dispose();
    _portFocus.dispose();
    super.dispose();
  }

  /// Persist a new backend port. Rejects anything outside the valid range and
  /// restores the stored value, so the field can never show an unsaved port.
  Future<void> _savePort(String value) async {
    final config = _config;
    if (config == null) return;

    final current = config['port'] as int;
    final port = int.tryParse(value.trim());
    if (port == null || port < 1 || port > 65535) {
      _portController.text = current.toString();
      if (mounted) showSnackBar(context, 'Port must be between 1 and 65535');
      return;
    }
    if (port == current) return;

    try {
      // PUT /config replaces the whole model, so send the loaded config with
      // just the port swapped — omitted keys would reset to their defaults.
      final saved = await setConfig({...config, 'port': port});
      if (!mounted) return;
      setState(() => _config = saved);
      _portController.text = saved['port'].toString();
      // The running backend keeps its old port until it restarts, so
      // backendConfig deliberately stays as-is for the rest of this session.
      showSnackBar(context, 'Port saved — restart Quartz to apply');
    } catch (e) {
      if (!mounted) return;
      _portController.text = current.toString();
      showSnackBar(context, 'Could not save port: $e');
    }
  }

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
          ListTile(
            leading: const Icon(Icons.folder_outlined),
            title: const Text('View run logs'),
            onTap: () async {
              final path = runLogsPath();
              if (Platform.isWindows) {
                await Process.run('explorer.exe', [path]);
              } else if (Platform.isLinux) {
                await Process.run('xdg-open', [path]);
              } else if (Platform.isMacOS) {
                await Process.run('open', [path]);
              }
            },
          ),
          ListTile(
            title: Text(
              'Backend Settings',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          ListTile(
            leading: const Icon(Symbols.cable),
            title: const Text('Port'),
            subtitle: Text(
              _config == null
                  ? 'Loading…'
                  : 'Backend listens on ${_config!['host']}:${_config!['port']}',
            ),
            // A text field has no intrinsic width; ListTile.trailing gives it
            // an unbounded one, which trips the InputDecorator assertion.
            trailing: SizedBox(
              width: 88,
              child: TextField(
                controller: _portController,
                focusNode: _portFocus,
                enabled: _config != null,
                textAlign: TextAlign.end,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(5),
                ],
                decoration: const InputDecoration(isDense: true),
                onSubmitted: _savePort,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.folder_outlined),
            title: const Text('View config folder'),
            onTap: () async {
              final path = quartzConfigDir();
              if (Platform.isWindows) {
                await Process.run('explorer.exe', [path]);
              } else if (Platform.isLinux) {
                await Process.run('xdg-open', [path]);
              } else if (Platform.isMacOS) {
                await Process.run('open', [path]);
              }
            },
          ),
          // todo: add more backend settings
        ],
      ),
    );
  }
}
