import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'shell.dart';
import 'theme_notifier.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final theme = ThemeNotifier();
  await theme.load();
  runApp(ChangeNotifierProvider.value(value: theme, child: const QuartzApp()));
}

class QuartzApp extends StatefulWidget {
  const QuartzApp({super.key});

  @override
  State<QuartzApp> createState() => _QuartzAppState();
}

class _QuartzAppState extends State<QuartzApp> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context, theme, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.light,
          colorSchemeSeed: theme.seed,
          useMaterial3: true,
          textTheme: GoogleFonts.interTextTheme(),
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          colorSchemeSeed: theme.seed,
          useMaterial3: true,
          textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        ),
        themeMode: theme.mode,
        home: const AppShell(),
      ),
    );
  }
}
