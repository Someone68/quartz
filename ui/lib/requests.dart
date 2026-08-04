import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:quartz/config.dart';
import 'package:quartz/types.dart';

Future<Map<String, dynamic>> getConfig() async {
  final res = await http.get(apiUri('/config'), headers: authHeaders());
  if (res.statusCode != 200) {
    throw Exception('Get failed: ${res.statusCode} ${res.body}');
  }
  return jsonDecode(res.body);
}

Future<Map<String, dynamic>> setConfig(Map<String, dynamic> config) async {
  final res = await http.put(
    apiUri('/config'),
    headers: authHeaders({'Content-Type': 'application/json'}),
    body: jsonEncode(config),
  );
  if (res.statusCode != 200) {
    throw Exception('Put failed: ${res.statusCode} ${res.body}');
  }
  return jsonDecode(res.body);
}

/// POST a shortcut. Backend mints an id on create and echoes the stored
/// shortcut back; we parse and return it so callers pick up the id.
Future<Shortcut> saveShortcut(Shortcut shortcut) async {
  final res = await http.post(
    apiUri('/shortcuts'),
    headers: authHeaders({'Content-Type': 'application/json'}),
    body: jsonEncode(shortcut),
  );
  if (res.statusCode != 201) {
    throw Exception('Save failed: ${res.statusCode} ${res.body}');
  }
  return Shortcut.fromJson(jsonDecode(res.body));
}

Future<List<ActionDef>> getActions() async {
  final res = await http.get(apiUri('/actions'), headers: authHeaders());
  if (res.statusCode != 200) {
    throw Exception('Get failed: ${res.statusCode} ${res.body}');
  }
  return (jsonDecode(res.body) as List)
      .map((s) => ActionDef.fromJson(s))
      .toList();
}

Future<Shortcut> updateShortcut(Shortcut shortcut) async {
  final res = await http.put(
    apiUri('/shortcuts/${shortcut.id}'),
    headers: authHeaders({'Content-Type': 'application/json'}),
    body: jsonEncode(shortcut),
  );
  if (res.statusCode != 200) {
    throw Exception('Update failed: ${res.statusCode} ${res.body}');
  }
  return Shortcut.fromJson(jsonDecode(res.body));
}

Future<RunLog> runShortcut(String id) async {
  final res = await http.post(
    apiUri('/shortcuts/$id/run'),
    headers: authHeaders({'Content-Type': 'application/json'}),
  );
  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw Exception('Run failed: ${res.statusCode} ${res.body}');
  }
  return RunLog.fromJson(jsonDecode(res.body));
}

Future<List<ShortcutSummary>> getShortcuts() async {
  final res = await http.get(apiUri('/shortcuts'), headers: authHeaders());
  if (res.statusCode != 200) {
    throw Exception('Get failed: ${res.statusCode} ${res.body}');
  }
  return (jsonDecode(res.body) as List)
      .map((s) => ShortcutSummary.fromJson(s))
      .toList();
}

Future<Shortcut> getShortcut(String id) async {
  final res = await http.get(apiUri('/shortcuts/$id'), headers: authHeaders());
  if (res.statusCode != 200) {
    throw Exception('Get failed: ${res.statusCode} ${res.body}');
  }
  return Shortcut.fromJson(jsonDecode(res.body));
}

Future<Shortcut> renameShortcut(String id, String name) async {
  final res = await http.patch(
    apiUri('/shortcuts/$id/rename'),
    headers: authHeaders({'Content-Type': 'application/json'}),
    body: jsonEncode({'name': name}),
  );
  if (res.statusCode != 200) {
    throw Exception('Rename failed: ${res.statusCode} ${res.body}');
  }
  return Shortcut.fromJson(jsonDecode(res.body));
}

Future<void> deleteShortcut(String id) async {
  final res = await http.delete(
    apiUri('/shortcuts/$id'),
    headers: authHeaders(),
  );
  if (res.statusCode != 204) {
    throw Exception('Delete failed: ${res.statusCode} ${res.body}');
  }
}

/// Installed applications, used by the app picker.
Future<List<AppEntry>> getApps() async {
  final res = await http
      .get(apiUri('/apps'), headers: authHeaders())
      .timeout(const Duration(seconds: 10));
  if (res.statusCode != 200) {
    throw Exception('Get failed: ${res.statusCode} ${res.body}');
  }
  return (jsonDecode(res.body)['apps'] as List)
      .map((j) => AppEntry.fromJson(j))
      .toList();
}
