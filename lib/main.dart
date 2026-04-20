import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/clock_client.dart';
import 'services/local_clock_client.dart';

void main() {
  runApp(const ChessClockApp());
}

class ChessClockApp extends StatefulWidget {
  const ChessClockApp({super.key});

  @override
  State<ChessClockApp> createState() => _ChessClockAppState();
}

class _ChessClockAppState extends State<ChessClockApp> {
  ClockClient _client = LocalClockClient();

  @override
  void dispose() {
    _client.dispose();
    super.dispose();
  }

  void _switchBackend(ClockClient next) {
    final old = _client;
    setState(() {
      _client = next;
    });
    old.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chess Clock',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFFB86B),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF121418),
      ),
      home: HomeScreen(
        client: _client,
        onSwitchBackend: _switchBackend,
      ),
    );
  }
}
