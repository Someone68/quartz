import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'extensions.dart';

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
          colorScheme: ColorScheme.fromSeed(
            seedColor: theme.seed,
            dynamicSchemeVariant: DynamicSchemeVariant.tonalSpot,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          textTheme: GoogleFonts.interTextTheme(),
          extensions: [
            AppTextThemes(mono: GoogleFonts.jetBrainsMonoTextTheme()),
          ],
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(
            seedColor: theme.seed,
            dynamicSchemeVariant: DynamicSchemeVariant.tonalSpot,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
          extensions: [
            AppTextThemes(
              mono: GoogleFonts.jetBrainsMonoTextTheme(
                ThemeData.dark().textTheme,
              ),
            ),
          ],
        ),
        themeMode: theme.mode,
        home: const AppShell(),
      ),
    );
  }
}
