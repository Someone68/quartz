import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:ui/types.dart';

/// POST a shortcut. Backend mints an id on create and echoes the stored
/// shortcut back; we parse and return it so callers pick up the id.
Future<Shortcut> saveShortcut(Shortcut shortcut) async {
  final res = await http.post(
    Uri.parse('http://localhost:8757/shortcuts'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(shortcut),
  );
  if (res.statusCode != 201) {
    throw Exception('Save failed: ${res.statusCode} ${res.body}');
  }
  return Shortcut.fromJson(jsonDecode(res.body));
}

Future<List<ActionDef>> getActions() async {
  final res = await http.get(Uri.parse('http://localhost:8757/actions'));
  if (res.statusCode != 200) {
    throw Exception('Get failed: ${res.statusCode} ${res.body}');
  }
  return (jsonDecode(res.body) as List)
      .map((s) => ActionDef.fromJson(s))
      .toList();
}

Future<Shortcut> updateShortcut(Shortcut shortcut) async {
  final res = await http.put(
    Uri.parse('http://localhost:8757/shortcuts/${shortcut.id}'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(shortcut),
  );
  if (res.statusCode != 200) {
    throw Exception('Update failed: ${res.statusCode} ${res.body}');
  }
  return Shortcut.fromJson(jsonDecode(res.body));
}

Future<RunLog> runShortcut(String id) async {
  final res = await http.post(
    Uri.parse('http://localhost:8757/shortcuts/$id/run'),
    headers: {'Content-Type': 'application/json'},
  );
  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw Exception('Run failed: ${res.statusCode} ${res.body}');
  }
  return RunLog.fromJson(jsonDecode(res.body));
}

Future<List<ShortcutSummary>> getShortcuts() async {
  final res = await http.get(Uri.parse('http://localhost:8757/shortcuts'));
  if (res.statusCode != 200) {
    throw Exception('Get failed: ${res.statusCode} ${res.body}');
  }
  return (jsonDecode(res.body) as List)
      .map((s) => ShortcutSummary.fromJson(s))
      .toList();
}

Future<Shortcut> getShortcut(String id) async {
  final res = await http.get(Uri.parse('http://localhost:8757/shortcuts/$id'));
  if (res.statusCode != 200) {
    throw Exception('Get failed: ${res.statusCode} ${res.body}');
  }
  return Shortcut.fromJson(jsonDecode(res.body));
}

Future<Shortcut> renameShortcut(String id, String name) async {
  final res = await http.patch(
    Uri.parse('http://localhost:8757/shortcuts/$id/rename'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'name': name}),
  );
  if (res.statusCode != 200) {
    throw Exception('Rename failed: ${res.statusCode} ${res.body}');
  }
  return Shortcut.fromJson(jsonDecode(res.body));
}

Future<void> deleteShortcut(String id) async {
  final res = await http.delete(
    Uri.parse('http://localhost:8757/shortcuts/$id'),
  );
  if (res.statusCode != 204) {
    throw Exception('Delete failed: ${res.statusCode} ${res.body}');
  }
}
