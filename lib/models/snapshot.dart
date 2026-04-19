enum GameStateEnum { idle, running, paused, flagged, unknown }

GameStateEnum _parseState(String? s) {
  switch (s) {
    case 'idle':
      return GameStateEnum.idle;
    case 'running':
      return GameStateEnum.running;
    case 'paused':
      return GameStateEnum.paused;
    case 'flagged':
      return GameStateEnum.flagged;
    default:
      return GameStateEnum.unknown;
  }
}

class PlayerSnapshot {
  final String name;
  final int timeMs;
  final int moves;
  final double score;

  const PlayerSnapshot({
    required this.name,
    required this.timeMs,
    required this.moves,
    required this.score,
  });

  factory PlayerSnapshot.fromJson(Map<String, dynamic> j) => PlayerSnapshot(
        name: (j['name'] ?? '') as String,
        timeMs: (j['time_ms'] as num?)?.toInt() ?? 0,
        moves: (j['moves'] as num?)?.toInt() ?? 0,
        score: (j['score'] as num?)?.toDouble() ?? 0.0,
      );
}

String formatScore(double s) {
  if (s == s.truncateToDouble()) return s.toInt().toString();
  return s.toStringAsFixed(1);
}

class TimeControlSnapshot {
  final int baseMs;
  final int incrementMs;
  final String mode;

  const TimeControlSnapshot({
    required this.baseMs,
    required this.incrementMs,
    required this.mode,
  });

  factory TimeControlSnapshot.fromJson(Map<String, dynamic> j) =>
      TimeControlSnapshot(
        baseMs: (j['base_ms'] as num?)?.toInt() ?? 0,
        incrementMs: (j['increment_ms'] as num?)?.toInt() ?? 0,
        mode: (j['mode'] ?? 'sudden_death') as String,
      );

  String get summary {
    final baseSec = baseMs ~/ 1000;
    final baseMin = baseSec ~/ 60;
    final baseRem = baseSec % 60;
    final baseStr = baseMin > 0
        ? (baseRem == 0 ? '${baseMin}m' : '${baseMin}m${baseRem}s')
        : '${baseSec}s';
    final incSec = incrementMs ~/ 1000;
    final modeLabel = switch (mode) {
      'fischer' => 'Fischer',
      'bronstein' => 'Bronstein',
      _ => 'Sudden death',
    };
    return incSec > 0 ? '$baseStr +${incSec}s · $modeLabel' : '$baseStr · $modeLabel';
  }
}

class GameSnapshot {
  final GameStateEnum state;
  final int active;
  final int? flaggedPlayer;
  final TimeControlSnapshot timeControl;
  final PlayerSnapshot p1;
  final PlayerSnapshot p2;

  const GameSnapshot({
    required this.state,
    required this.active,
    required this.flaggedPlayer,
    required this.timeControl,
    required this.p1,
    required this.p2,
  });

  factory GameSnapshot.fromJson(Map<String, dynamic> j) => GameSnapshot(
        state: _parseState(j['state'] as String?),
        active: (j['active'] as num?)?.toInt() ?? 1,
        flaggedPlayer: (j['flagged_player'] as num?)?.toInt(),
        timeControl: TimeControlSnapshot.fromJson(
          (j['time_control'] as Map?)?.cast<String, dynamic>() ?? const {},
        ),
        p1: PlayerSnapshot.fromJson(
          (j['p1'] as Map?)?.cast<String, dynamic>() ?? const {},
        ),
        p2: PlayerSnapshot.fromJson(
          (j['p2'] as Map?)?.cast<String, dynamic>() ?? const {},
        ),
      );

  PlayerSnapshot player(int n) => n == 1 ? p1 : p2;
}

const Map<String, String> kTimeControlPresets = {
  'bullet_1_0': 'Bullet 1+0',
  'bullet_2_1': 'Bullet 2+1',
  'blitz_3_0': 'Blitz 3+0',
  'blitz_3_2': 'Blitz 3+2',
  'blitz_5_0': 'Blitz 5+0',
  'blitz_5_3': 'Blitz 5+3',
  'rapid_10_0': 'Rapid 10+0',
  'rapid_15_10': 'Rapid 15+10',
  'classical_30_0': 'Classical 30+0',
};

String formatTime(int ms) {
  final safe = ms < 0 ? 0 : ms;
  final totalSec = safe ~/ 1000;
  final m = totalSec ~/ 60;
  final s = totalSec % 60;
  if (m >= 1) {
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
  final cs = (safe % 1000) ~/ 10;
  return '00:${s.toString().padLeft(2, '0')}.${cs.toString().padLeft(2, '0')}';
}
