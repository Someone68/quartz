import 'dart:async';
import 'dart:io';

import 'package:quartz/config.dart';

enum BackendStatus { unknown, online, offline }

class BackendMonitor {
  String get host => backendConfig.host;
  int get port => backendConfig.port;

  final _controller = StreamController<BackendStatus>.broadcast();
  Timer? _timer;

  Stream<BackendStatus> get status => _controller.stream;
  BackendStatus _lastStatus = BackendStatus.unknown;
  Duration _interval = const Duration(seconds: 1);

  BackendStatus get current => _lastStatus;

  final Duration _minInterval = const Duration(seconds: 1);
  final Duration _maxInterval = const Duration(seconds: 15);
  bool _running = false;

  BackendMonitor();

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
    if (_lastStatus != BackendStatus.online) loadBackendConfig();

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
}

final backendStatus = BackendMonitor()..start();
