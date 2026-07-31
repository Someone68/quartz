import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Reproduces the layout constraint the Port tile hit: a text field has no
// intrinsic width, and ListTile.trailing hands it an unbounded one.
void main() {
  testWidgets('bare text field in ListTile.trailing overflows', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              ListTile(
                title: const Text('Port'),
                trailing: TextFormField(initialValue: '8757'),
              ),
            ],
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNotNull);
  });

  testWidgets('width-bounded text field lays out cleanly', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              ListTile(
                title: const Text('Port'),
                trailing: SizedBox(
                  width: 88,
                  child: TextField(
                    controller: TextEditingController(text: '8757'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('8757'), findsOneWidget);
  });
}
