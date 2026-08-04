import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'config.dart';

/// Discover a running daemon; if none answers, spawn the installed `quartzd`
/// and wait for it. The UI is a client — it must never assume the backend is
/// up, since the daemon is a background service the user may have stopped.
Future<void> ensureBackend() async {
  loadBackendConfig();
  if (await _healthy()) return;

  if (!_spawnDaemon()) {
    // Nothing to launch (e.g. running from source without an installed
    // binary). Leave backendConfig as-is; API calls will surface the error.
    debugPrint('No quartzd binary found to launch.');
    return;
  }

  // Poll for the daemon to write its handshake and answer /health (~5s budget).
  for (var i = 0; i < 25; i++) {
    await Future.delayed(const Duration(milliseconds: 200));
    loadBackendConfig(); // re-read runtime.json the daemon just wrote
    if (await _healthy()) return;
  }
  debugPrint('quartzd did not become healthy in time.');
}

Future<bool> _healthy() async {
  try {
    final res = await http
        .get(apiUri('/health'))
        .timeout(const Duration(milliseconds: 500));
    return res.statusCode == 200;
  } catch (_) {
    return false;
  }
}

bool _spawnDaemon() {
  final exe = _daemonPath();
  if (exe == null) return false;
  try {
    // Detached so the daemon outlives this UI process — triggers keep firing
    // after the window closes.
    Process.start(exe, const [], mode: ProcessStartMode.detached);
    return true;
  } catch (e) {
    debugPrint('Failed to launch quartzd at $exe: $e');
    return false;
  }
}

/// Installed daemon location per platform, or null if not found.
String? _daemonPath() {
  if (Platform.isWindows) {
    // MSIX ships quartzd.exe alongside the UI executable.
    final dir = File(Platform.resolvedExecutable).parent.path;
    final exe = '$dir\\quartzd.exe';
    return File(exe).existsSync() ? exe : null;
  }
  // Linux: system package first, then user source-build install.
  final home = Platform.environment['HOME'] ?? '';
  for (final p in [
    '/usr/lib/quartz/quartzd',
    '$home/.local/lib/quartz/quartzd',
  ]) {
    if (File(p).existsSync()) return p;
  }
  return null;
}
