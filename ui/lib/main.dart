import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:io';

import 'daemon.dart';
import 'extensions.dart';

import 'shell.dart';
import 'theme_notifier.dart';

const _lockPort = 45123; // pick something unused

Future<bool> _claimSingleInstance() async {
  try {
    final server = await ServerSocket.bind(
      InternetAddress.loopbackIPv4,
      _lockPort,
      shared: false,
    );
    server.listen((sock) {
      // second instance pinged us: focus window here
      // windowManager.show(); windowManager.focus();
      sock.destroy();
    });
    return true;
  } on SocketException {
    // tell the running instance to focus, then quit
    try {
      final s = await Socket.connect(InternetAddress.loopbackIPv4, _lockPort);
      s.destroy();
    } catch (_) {}
    return false;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!await _claimSingleInstance()) exit(0);
  // Discover the running daemon (host/port/token from runtime.json) or spawn
  // it, before any widget can fire a request. Every API call builds on this.
  await ensureBackend();
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
