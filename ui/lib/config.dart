import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

class BackendConfig {
  final String host;
  final int port;

  const BackendConfig({this.host = '127.0.0.1', this.port = 8757});

  factory BackendConfig.fromJson(Map<String, dynamic> j) => BackendConfig(
    host: (j['host'] as String?)?.trim().isNotEmpty == true
        ? (j['host'] as String).trim()
        : const BackendConfig().host,
    port: (j['port'] as num?)?.toInt() ?? const BackendConfig().port,
  );

  /// `host:port` in the form `Uri.http` expects. IPv6 literals need brackets.
  String get authority => host.contains(':') ? '[$host]:$port' : '$host:$port';

  @override
  String toString() => 'BackendConfig(host: $host, port: $port)';
}

String quartzConfigDir() {
  final home =
      Platform.environment['HOME'] ??
      Platform.environment['USERPROFILE'] ??
      '~';
  return '$home/.config/quartz';
}

String quartzConfigPath(String name) => '${quartzConfigDir()}/$name';

BackendConfig backendConfig = const BackendConfig();

BackendConfig loadBackendConfig() {
  final file = File(quartzConfigPath('config.json'));
  try {
    if (file.existsSync()) {
      backendConfig = BackendConfig.fromJson(
        jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
      );
    } else {
      backendConfig = const BackendConfig();
    }
  } catch (e) {
    debugPrint('Bad ${file.path} ($e); using default backend host/port.');
    backendConfig = const BackendConfig();
  }
  return backendConfig;
}

Uri apiUri(String path, [Map<String, dynamic>? query]) =>
    Uri.http(backendConfig.authority, path, query);
