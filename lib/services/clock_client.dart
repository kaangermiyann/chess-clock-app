import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/snapshot.dart';

class ClockClient extends ChangeNotifier {
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;

  GameSnapshot? snapshot;
  bool connected = false;
  String? error;
  String? url;

  bool get hasSnapshot => snapshot != null;

  Future<void> connect(String targetUrl) async {
    await disconnect();
    error = null;
    notifyListeners();
    try {
      final channel = WebSocketChannel.connect(Uri.parse(targetUrl));
      await channel.ready.timeout(const Duration(seconds: 4));
      _channel = channel;
      url = targetUrl;
      connected = true;
      _sub = channel.stream.listen(
        _onData,
        onDone: _onDone,
        onError: _onError,
        cancelOnError: true,
      );
      notifyListeners();
    } catch (e) {
      error = e.toString();
      connected = false;
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
        snapshot = GameSnapshot.fromJson(decoded);
        notifyListeners();
      } else if (type == 'error') {
        error = (decoded['message'] as String?) ?? 'server error';
        notifyListeners();
      }
    } catch (e) {
      error = 'parse: $e';
      notifyListeners();
    }
  }

  void _onDone() {
    connected = false;
    notifyListeners();
  }

  void _onError(Object e) {
    error = e.toString();
    connected = false;
    notifyListeners();
  }

  Future<void> disconnect() async {
    await _sub?.cancel();
    _sub = null;
    try {
      await _channel?.sink.close();
    } catch (_) {}
    _channel = null;
    connected = false;
    notifyListeners();
  }

  void _send(Map<String, dynamic> cmd) {
    final ch = _channel;
    if (ch == null || !connected) return;
    ch.sink.add(jsonEncode(cmd));
  }

  void start() => _send({'cmd': 'start'});
  void pause() => _send({'cmd': 'pause'});
  void togglePause() => _send({'cmd': 'toggle_pause'});
  void reset() => _send({'cmd': 'reset'});
  void press(int player) => _send({'cmd': 'press', 'player': player});
  void setNames(String p1, String p2) =>
      _send({'cmd': 'set_names', 'p1': p1, 'p2': p2});
  void setTimeControlPreset(String preset) =>
      _send({'cmd': 'set_time_control', 'preset': preset});
  void declareWinner(int winner) =>
      _send({'cmd': 'declare_winner', 'winner': winner});
  void resetScores() => _send({'cmd': 'reset_scores'});
  void requestSnapshot() => _send({'cmd': 'get_snapshot'});

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
