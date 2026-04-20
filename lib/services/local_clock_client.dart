import 'dart:async';

import '../engine/game_engine.dart';
import '../models/snapshot.dart';
import 'clock_client.dart';

/// Local, in-process backend. Runs a [GameEngine] and ticks at 100 ms so the
/// UI sees the active player's clock fall in near real-time without any
/// network or server.
class LocalClockClient extends ClockClient {
  static const Duration _tickInterval = Duration(milliseconds: 100);

  final GameEngine _engine;
  Timer? _ticker;
  GameSnapshot? _snapshot;

  LocalClockClient({GameEngine? engine}) : _engine = engine ?? GameEngine() {
    _refresh();
  }

  @override
  GameSnapshot? get snapshot => _snapshot;
  @override
  bool get connected => true;
  @override
  String? get error => null;
  @override
  String? get url => null;
  @override
  bool get isLocal => true;

  void _refresh() {
    _snapshot = _engine.toSnapshot();
    notifyListeners();
  }

  void _ensureTicker() {
    if (_engine.state == GameStateEnum.running) {
      _ticker ??= Timer.periodic(_tickInterval, _onTick);
    } else {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  void _onTick(Timer _) {
    _engine.tick(_tickInterval.inMilliseconds);
    _refresh();
    if (_engine.state != GameStateEnum.running) {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  @override
  Future<void> connect(String targetUrl) async {}

  @override
  Future<void> disconnect() async {}

  @override
  void start() {
    _engine.start();
    _refresh();
    _ensureTicker();
  }

  @override
  void pause() {
    _engine.pause();
    _refresh();
    _ensureTicker();
  }

  @override
  void togglePause() {
    _engine.togglePause();
    _refresh();
    _ensureTicker();
  }

  @override
  void reset() {
    _engine.reset();
    _refresh();
    _ensureTicker();
  }

  @override
  void press(int player) {
    _engine.press(player);
    _refresh();
  }

  @override
  void setNames(String p1, String p2) {
    _engine.setNames(p1, p2);
    _refresh();
  }

  @override
  void setTimeControlPreset(String preset) {
    _engine.setTimeControlPreset(preset);
    _refresh();
    _ensureTicker();
  }

  @override
  void setCustomTimeControl({
    required int p1BaseMs,
    required int p2BaseMs,
    int incrementMs = 0,
    TimeControlMode mode = TimeControlMode.suddenDeath,
  }) {
    _engine.setCustomTimeControl(
      p1BaseMs: p1BaseMs,
      p2BaseMs: p2BaseMs,
      incrementMs: incrementMs,
      mode: mode,
    );
    _refresh();
    _ensureTicker();
  }

  @override
  void declareWinner(int winner) {
    _engine.declareWinner(winner);
    _refresh();
    _ensureTicker();
  }

  @override
  void resetScores() {
    _engine.resetScores();
    _refresh();
  }

  @override
  void requestSnapshot() {
    _refresh();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _ticker = null;
    super.dispose();
  }
}
