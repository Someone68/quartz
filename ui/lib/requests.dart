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

Future<void> deleteShortcut(String id) async {
  final res = await http.delete(
    Uri.parse('http://localhost:8757/shortcuts/$id'),
  );
  if (res.statusCode != 204) {
    throw Exception('Delete failed: ${res.statusCode} ${res.body}');
  }
}
