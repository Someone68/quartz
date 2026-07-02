import 'package:flutter/material.dart';
import 'package:ui/modules/misc.dart';
import 'package:ui/types.dart';

Future<ActionSummary?> showActionLibrary(
  BuildContext context,
  List<ActionSummary> items,
) {
  return showModalBottomSheet<ActionSummary>(
    context: context,
    isScrollControlled: true,
    builder: (context) => ActionLibrary(items: items),
  );
}

class ActionLibrary extends StatefulWidget {
  final List<ActionSummary> items;

  ActionLibrary({required this.items});

  @override
  _ActionLibraryState createState() => _ActionLibraryState();
}

class _ActionLibraryState extends State<ActionLibrary> {
  late List<ActionSummary> filtered;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    filtered = widget.items;
  }

  void _filterItems(String query) {
    setState(() {
      filtered = widget.items
          .where(
            (item) => ("${item.category}: ${item.name}").toLowerCase().contains(
              query.toLowerCase(),
            ),
          )
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: _filterItems,
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: buildStyledIcon(
                      context,
                      Theme.of(context).colorScheme.primaryContainer,
                      symbolFromName(filtered[index].icon),
                    ),
                    title: Text(
                      "${filtered[index].category}: ${filtered[index].name}",
                    ),
                    onTap: () => Navigator.pop(context, filtered[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
