import '../models/snapshot.dart';

/// Pure Dart port of the Python `game.py` engine.
/// Player 1 = White (moves first). Player 2 = Black.
/// Drive with [tick] at a fixed cadence (100 ms by default).

enum TimeControlMode { suddenDeath, fischer, bronstein }

String timeControlModeKey(TimeControlMode m) {
  switch (m) {
    case TimeControlMode.suddenDeath:
      return 'sudden_death';
    case TimeControlMode.fischer:
      return 'fischer';
    case TimeControlMode.bronstein:
      return 'bronstein';
  }
}

class TimeControlConfig {
  final int baseMs;
  final int incrementMs;
  final TimeControlMode mode;

  const TimeControlConfig({
    required this.baseMs,
    this.incrementMs = 0,
    this.mode = TimeControlMode.suddenDeath,
  });
}

const Map<String, TimeControlConfig> kPresetConfigs = {
  'bullet_1_0': TimeControlConfig(baseMs: 60000),
  'bullet_2_1': TimeControlConfig(
    baseMs: 120000,
    incrementMs: 1000,
    mode: TimeControlMode.fischer,
  ),
  'blitz_3_0': TimeControlConfig(baseMs: 180000),
  'blitz_3_2': TimeControlConfig(
    baseMs: 180000,
    incrementMs: 2000,
    mode: TimeControlMode.fischer,
  ),
  'blitz_5_0': TimeControlConfig(baseMs: 300000),
  'blitz_5_3': TimeControlConfig(
    baseMs: 300000,
    incrementMs: 3000,
    mode: TimeControlMode.fischer,
  ),
  'rapid_10_0': TimeControlConfig(baseMs: 600000),
  'rapid_15_10': TimeControlConfig(
    baseMs: 900000,
    incrementMs: 10000,
    mode: TimeControlMode.fischer,
  ),
  'classical_30_0': TimeControlConfig(baseMs: 1800000),
};

const String kDefaultPreset = 'blitz_5_3';
const String kDefaultP1Name = 'White';
const String kDefaultP2Name = 'Black';

class _PlayerState {
  String name;
  int timeMs;
  int moves = 0;
  double score = 0.0;

  _PlayerState({required this.name, required this.timeMs});
}

class GameEngine {
  TimeControlConfig timeControl;
  final _PlayerState _p1;
  final _PlayerState _p2;
  GameStateEnum state;
  int active;
  int? flaggedPlayer;
  int _turnStartTimeMs;

  GameEngine({
    TimeControlConfig? timeControl,
    String p1Name = kDefaultP1Name,
    String p2Name = kDefaultP2Name,
  })  : timeControl = timeControl ?? kPresetConfigs[kDefaultPreset]!,
        _p1 = _PlayerState(
          name: p1Name,
          timeMs: (timeControl ?? kPresetConfigs[kDefaultPreset]!).baseMs,
        ),
        _p2 = _PlayerState(
          name: p2Name,
          timeMs: (timeControl ?? kPresetConfigs[kDefaultPreset]!).baseMs,
        ),
        state = GameStateEnum.idle,
        active = 1,
        flaggedPlayer = null,
        _turnStartTimeMs =
            (timeControl ?? kPresetConfigs[kDefaultPreset]!).baseMs;

  _PlayerState _player(int n) => n == 1 ? _p1 : _p2;

  void start() {
    if (state == GameStateEnum.idle || state == GameStateEnum.paused) {
      if (state == GameStateEnum.idle) {
        active = 1;
        _turnStartTimeMs = _player(active).timeMs;
      }
      state = GameStateEnum.running;
    }
  }

  void pause() {
    if (state == GameStateEnum.running) {
      state = GameStateEnum.paused;
    }
  }

  void togglePause() {
    if (state == GameStateEnum.running) {
      pause();
    } else if (state == GameStateEnum.idle || state == GameStateEnum.paused) {
      start();
    }
  }

  void press(int player) {
    if (state != GameStateEnum.running || player != active) return;
    final p = _player(player);
    p.moves += 1;

    switch (timeControl.mode) {
      case TimeControlMode.fischer:
        p.timeMs += timeControl.incrementMs;
        break;
      case TimeControlMode.bronstein:
        final used = _turnStartTimeMs - p.timeMs;
        final refund = used < 0 ? 0 : used;
        final capped =
            refund < timeControl.incrementMs ? refund : timeControl.incrementMs;
        p.timeMs += capped;
        break;
      case TimeControlMode.suddenDeath:
        break;
    }

    active = player == 1 ? 2 : 1;
    _turnStartTimeMs = _player(active).timeMs;
  }

  void tick(int dtMs) {
    if (state != GameStateEnum.running || dtMs <= 0) return;
    final p = _player(active);
    p.timeMs -= dtMs;
    if (p.timeMs <= 0) {
      p.timeMs = 0;
      state = GameStateEnum.flagged;
      flaggedPlayer = active;
      final opponent = active == 1 ? 2 : 1;
      _player(opponent).score += 1.0;
    }
  }

  void reset() {
    _p1.timeMs = timeControl.baseMs;
    _p2.timeMs = timeControl.baseMs;
    _p1.moves = 0;
    _p2.moves = 0;
    state = GameStateEnum.idle;
    active = 1;
    flaggedPlayer = null;
    _turnStartTimeMs = timeControl.baseMs;
  }

  void declareWinner(int winner) {
    if (state == GameStateEnum.running || state == GameStateEnum.paused) {
      if (winner == 1) {
        _p1.score += 1.0;
      } else if (winner == 2) {
        _p2.score += 1.0;
      } else if (winner == 0) {
        _p1.score += 0.5;
        _p2.score += 0.5;
      }
    }
    reset();
  }

  void resetScores() {
    _p1.score = 0.0;
    _p2.score = 0.0;
  }

  void setNames(String p1Name, String p2Name) {
    _p1.name = p1Name.isEmpty ? kDefaultP1Name : p1Name;
    _p2.name = p2Name.isEmpty ? kDefaultP2Name : p2Name;
  }

  void setTimeControl(TimeControlConfig tc) {
    timeControl = tc;
    reset();
  }

  bool setTimeControlPreset(String preset) {
    final tc = kPresetConfigs[preset];
    if (tc == null) return false;
    setTimeControl(tc);
    return true;
  }

  GameSnapshot toSnapshot() {
    return GameSnapshot(
      state: state,
      active: active,
      flaggedPlayer: flaggedPlayer,
      timeControl: TimeControlSnapshot(
        baseMs: timeControl.baseMs,
        incrementMs: timeControl.incrementMs,
        mode: timeControlModeKey(timeControl.mode),
      ),
      p1: PlayerSnapshot(
        name: _p1.name,
        timeMs: _p1.timeMs,
        moves: _p1.moves,
        score: _p1.score,
      ),
      p2: PlayerSnapshot(
        name: _p2.name,
        timeMs: _p2.timeMs,
        moves: _p2.moves,
        score: _p2.score,
      ),
    );
  }
}
