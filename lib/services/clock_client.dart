import 'package:flutter/foundation.dart';

import '../models/snapshot.dart';

/// Abstract backend consumed by the UI. Two implementations:
/// - [LocalClockClient] runs a Dart `GameEngine` in-process (offline default).
/// - [RemoteClockClient] talks to a Python `ws_server.py` over WebSocket
///   (reserved for the physical clock).
abstract class ClockClient extends ChangeNotifier {
  GameSnapshot? get snapshot;
  bool get connected;
  String? get error;
  String? get url;
  bool get isLocal;

  bool get hasSnapshot => snapshot != null;

  Future<void> connect(String targetUrl);
  Future<void> disconnect();

  void start();
  void pause();
  void togglePause();
  void reset();
  void press(int player);
  void setNames(String p1, String p2);
  void setTimeControlPreset(String preset);
  void declareWinner(int winner);
  void resetScores();
  void requestSnapshot();
}
