import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

class BackendConfig {
  final String host;
  final int port;

  /// Per-run token from the daemon's runtime.json. Null when we only have
  /// config.json (daemon not yet up); requests then go out unauthenticated and
  /// get a 401 until the handshake is read.
  final String? token;

  const BackendConfig({
    this.host = '127.0.0.1',
    this.port = 8757,
    this.token,
  });

  factory BackendConfig.fromJson(Map<String, dynamic> j) => BackendConfig(
    host: (j['host'] as String?)?.trim().isNotEmpty == true
        ? (j['host'] as String).trim()
        : const BackendConfig().host,
    port: (j['port'] as num?)?.toInt() ?? const BackendConfig().port,
    token: (j['token'] as String?)?.trim().isNotEmpty == true
        ? (j['token'] as String).trim()
        : null,
  );

  /// `host:port` in the form `Uri.http` expects. IPv6 literals need brackets.
  String get authority => host.contains(':') ? '[$host]:$port' : '$host:$port';

  /// Authorization header for API calls, empty until we have a token.
  Map<String, String> get authHeaders =>
      token != null ? {'Authorization': 'Bearer $token'} : const {};

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
  // runtime.json is written by the running daemon and holds the ACTUAL bound
  // port plus the auth token. Prefer it. Fall back to config.json (which only
  // carries the user's preferred port, no token) so the UI has a target before
  // the daemon comes up — it self-spawns the daemon and re-reads afterwards.
  final runtime = File(quartzConfigPath('runtime.json'));
  try {
    if (runtime.existsSync()) {
      backendConfig = BackendConfig.fromJson(
        jsonDecode(runtime.readAsStringSync()) as Map<String, dynamic>,
      );
      return backendConfig;
    }
  } catch (e) {
    debugPrint('Bad ${runtime.path} ($e); falling back to config.json.');
  }

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

/// Headers for an API call: the auth token plus any [extra] (e.g. Content-Type).
Map<String, String> authHeaders([Map<String, String>? extra]) => {
  ...backendConfig.authHeaders,
  ...?extra,
};
