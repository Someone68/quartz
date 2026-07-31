import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:quartz/types.dart';

class AppPicker extends StatefulWidget {
  final int port;
  final Function(AppEntry) onSelect;

  const AppPicker({super.key, required this.port, required this.onSelect});

  @override
  State<AppPicker> createState() => _AppPickerState();
}

class _AppPickerState extends State<AppPicker> {
  List<AppEntry> _all = [];
  List<AppEntry> _shown = [];

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await http
          .get(Uri.parse('http://127.0.0.1:${widget.port}/apps'))
          .timeout(const Duration(seconds: 10));
      final list = (jsonDecode(res.body)['apps'] as List)
          .map((j) => AppEntry.fromJson(j))
          .toList();
      setState(() {
        _all = list;
        _shown = list;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  void _filter(String q) {
    q = q.toLowerCase().trim();
    setState(() {
      _shown = q.isEmpty
          ? _all
          : _all.where((a) => a.nameLower.contains(q)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(child: Text('Failed: $_error'));
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search apps',
            ),
            onChanged: _filter,
          ),
        ),
        Expanded(
          child: ListView.builder(
            // builds only visible rows
            itemCount: _shown.length,
            itemExtent: 56, // fixed height = faster layout
            itemBuilder: (_, i) {
              final a = _shown[i];
              return ListTile(
                leading: a.icon != null
                    ? Image.memory(
                        a.icon!,
                        width: 32,
                        height: 32,
                        gaplessPlayback: true,
                      )
                    : const Icon(Icons.apps, size: 32),
                title: Text(a.name),
                onTap: () => widget.onSelect(a),
              );
            },
          ),
        ),
      ],
    );
  }
}
