import 'package:flutter_test/flutter_test.dart';
import 'package:quartz/config.dart';

void main() {
  test('reads host and port written by the backend', () {
    loadBackendConfig();
    expect(backendConfig.port, isPositive);
    expect(backendConfig.host, isNotEmpty);
    expect(
      apiUri('/shortcuts').toString(),
      'http://${backendConfig.authority}/shortcuts',
    );
  });

  test('falls back to backend defaults on a missing key', () {
    final cfg = BackendConfig.fromJson({});
    expect(cfg.host, '127.0.0.1');
    expect(cfg.port, 8757);
  });

  test('brackets IPv6 hosts in the authority', () {
    const cfg = BackendConfig(host: '::1', port: 9000);
    expect(cfg.authority, '[::1]:9000');
    expect(Uri.http(cfg.authority, '/config').toString(), 'http://[::1]:9000/config');
  });

  test('builds paths with segments that need escaping', () {
    const cfg = BackendConfig(host: '10.0.0.5', port: 1234);
    backendConfig = cfg;
    expect(apiUri('/shortcuts/a b/run').toString(),
        'http://10.0.0.5:1234/shortcuts/a%20b/run');
    loadBackendConfig();
  });
}
