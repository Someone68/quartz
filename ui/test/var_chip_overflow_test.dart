import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quartz/extensions.dart';
import 'package:quartz/modules/custom_tec.dart';

Widget _host(String value, {double width = 220}) => MaterialApp(
  theme: ThemeData(
    extensions: [AppTextThemes(mono: GoogleFonts.jetBrainsMonoTextTheme())],
  ),
  home: Scaffold(
    body: Center(
      child: SizedBox(
        width: width,
        child: CustomTextField(value: value, onChanged: (_) {}),
      ),
    ),
  ),
);

void main() {
  testWidgets('long step-output chip fits a narrow field', (tester) async {
    // Step ids are UUIDs, so real chips get long fast.
    await tester.pumpWidget(
      _host(
        '{{steps.550e8400-e29b-41d4-a716-446655440000.some_long_output_name}}',
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('long variable chip fits a narrow field', (tester) async {
    await tester.pumpWidget(
      _host('{{variables.a_really_long_variable_name_that_will_not_fit}}'),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('chip plus surrounding text fits', (tester) async {
    await tester.pumpWidget(
      _host('prefix {{trigger.some_quite_long_trigger_output}} suffix'),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('short chip keeps its full label', (tester) async {
    await tester.pumpWidget(_host('{{variables.count}}'));
    expect(tester.takeException(), isNull);
    expect(find.text('count'), findsOneWidget);
  });

  testWidgets('chip never renders wider than the field', (tester) async {
    const width = 220.0;
    await tester.pumpWidget(
      _host('{{steps.550e8400-e29b-41d4-a716-446655440000.output}}',
          width: width),
    );
    final chip = tester.getSize(find.byType(Icon).first);
    expect(chip.width, lessThan(width));
    expect(tester.getSize(find.byType(Row).last).width, lessThanOrEqualTo(width));
  });

  testWidgets('tapping a chip still expands it to raw text', (tester) async {
    await tester.pumpWidget(_host('{{variables.count}}'));
    expect(find.byType(Icon), findsOneWidget); // collapsed chip
    await tester.tap(find.byType(Icon));
    await tester.pump();
    expect(find.byType(Icon), findsNothing); // expanded to {{variables.count}}
    expect(tester.takeException(), isNull);
  });
}
