import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/snapshot.dart';
import 'clock_client.dart';

class RemoteClockClient extends ClockClient {
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;

  GameSnapshot? _snapshot;
  bool _connected = false;
  String? _error;
  String? _url;

  @override
  GameSnapshot? get snapshot => _snapshot;
  @override
  bool get connected => _connected;
  @override
  String? get error => _error;
  @override
  String? get url => _url;
  @override
  bool get isLocal => false;

  @override
  Future<void> connect(String targetUrl) async {
    await disconnect();
    _error = null;
    notifyListeners();
    try {
      final channel = WebSocketChannel.connect(Uri.parse(targetUrl));
      await channel.ready.timeout(const Duration(seconds: 4));
      _channel = channel;
      _url = targetUrl;
      _connected = true;
      _sub = channel.stream.listen(
        _onData,
        onDone: _onDone,
        onError: _onError,
        cancelOnError: true,
      );
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _connected = false;
      _channel = null;
      notifyListeners();
      rethrow;
    }
  }

  void _onData(dynamic raw) {
    try {
      final decoded = jsonDecode(raw as String);
      if (decoded is! Map<String, dynamic>) return;
      final type = decoded['type'] as String?;
      if (type == 'snapshot') {
        _snapshot = GameSnapshot.fromJson(decoded);
        notifyListeners();
      } else if (type == 'error') {
        _error = (decoded['message'] as String?) ?? 'server error';
        notifyListeners();
      }
    } catch (e) {
      _error = 'parse: $e';
      notifyListeners();
    }
  }

  void _onDone() {
    _connected = false;
    notifyListeners();
  }

  void _onError(Object e) {
    _error = e.toString();
    _connected = false;
    notifyListeners();
  }

  @override
  Future<void> disconnect() async {
    await _sub?.cancel();
    _sub = null;
    try {
      await _channel?.sink.close();
    } catch (_) {}
    _channel = null;
    _connected = false;
    notifyListeners();
  }

  void _send(Map<String, dynamic> cmd) {
    final ch = _channel;
    if (ch == null || !_connected) return;
    ch.sink.add(jsonEncode(cmd));
  }

  @override
  void start() => _send({'cmd': 'start'});
  @override
  void pause() => _send({'cmd': 'pause'});
  @override
  void togglePause() => _send({'cmd': 'toggle_pause'});
  @override
  void reset() => _send({'cmd': 'reset'});
  @override
  void press(int player) => _send({'cmd': 'press', 'player': player});
  @override
  void setNames(String p1, String p2) =>
      _send({'cmd': 'set_names', 'p1': p1, 'p2': p2});
  @override
  void setTimeControlPreset(String preset) =>
      _send({'cmd': 'set_time_control', 'preset': preset});
  @override
  void declareWinner(int winner) =>
      _send({'cmd': 'declare_winner', 'winner': winner});
  @override
  void resetScores() => _send({'cmd': 'reset_scores'});
  @override
  void requestSnapshot() => _send({'cmd': 'get_snapshot'});

  @override
  void dispose() {
    _sub?.cancel();
    _sub = null;
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;
    _connected = false;
    super.dispose();
  }
}
