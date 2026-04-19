import 'package:flutter/material.dart';

import 'screens/connect_screen.dart';
import 'services/clock_client.dart';

void main() {
  runApp(const ChessClockApp());
}

class ChessClockApp extends StatefulWidget {
  const ChessClockApp({super.key});

  @override
  State<ChessClockApp> createState() => _ChessClockAppState();
}

class _ChessClockAppState extends State<ChessClockApp> {
  final ClockClient _client = ClockClient();

  @override
  void dispose() {
    _client.dispose();
    super.dispose();
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
      home: ConnectScreen(client: _client),
    );
  }
}
