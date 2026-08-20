import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:quartz/config.dart';

enum BackendStatus { unknown, online, offline }

class BackendMonitor {
  final String host;
  final int port;

  final _controller = StreamController<BackendStatus>.broadcast();
  Timer? _timer;

  Stream<BackendStatus> get status => _controller.stream;
  BackendStatus _lastStatus = BackendStatus.unknown;
  Duration _interval = Duration(seconds: 1);

  BackendStatus get current => _lastStatus;

  Duration _minInterval = Duration(seconds: 1);
  Duration _maxInterval = Duration(seconds: 15);
  bool _running = false;

  Future<void> refresh() async {
    _timer?.cancel();
    await _tick();
  }

  void start() {
    if (_running) return;
    _running = true;
    _tick();
  }

  Future<void> _tick() async {
    final up = await _checkStatus();
    if (!_running) return;
    final next = up ? BackendStatus.online : BackendStatus.offline;

    if (next != _lastStatus) {
      _controller.add(next);
      _lastStatus = next;
      _interval = _minInterval;
    } else if (!up) {
      _interval = _interval * 2 > _maxInterval ? _maxInterval : _interval * 2;
    } else {
      _interval = const Duration(seconds: 5);
    }

    _timer = Timer(_interval, _tick);
  }

  Future<bool> _checkStatus() async {
    try {
      final socket = await Socket.connect(
        host,
        port,
        timeout: const Duration(milliseconds: 300),
      );
      socket.destroy();
      return true;
    } on SocketException {
      return false;
    }
  }

  Future<void> waitUntilOnline({
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (_lastStatus == BackendStatus.online) return;
    await status.firstWhere((s) => s == BackendStatus.online).timeout(timeout);
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
    _running = false;
    _controller.close();
  }

  void markOffline() {
    if (_lastStatus != BackendStatus.offline) {
      _controller.add(BackendStatus.offline);
      _lastStatus = BackendStatus.offline;
    }

    _interval = _minInterval;
    _timer?.cancel();
    _timer = Timer(_minInterval, _tick);
  }

  BackendMonitor({required this.host, required this.port});
}

final backendConfig = BackendConfig.fromJson(
  jsonDecode(File(quartzConfigPath('config.json')).readAsStringSync())
      as Map<String, dynamic>,
);

final backendStatus = BackendMonitor(
  host: backendConfig.host,
  port: backendConfig.port,
)..start();
