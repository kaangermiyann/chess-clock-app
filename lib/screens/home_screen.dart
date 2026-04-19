import 'package:flutter/material.dart';

import '../models/snapshot.dart';
import '../services/clock_client.dart';
import '../widgets/flag_fall_popup.dart';
import '../widgets/player_card.dart';
import 'connect_screen.dart';
import 'settings_screen.dart';
import 'winner_dialog.dart';

class HomeScreen extends StatefulWidget {
  final ClockClient client;
  const HomeScreen({super.key, required this.client});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GameStateEnum? _lastState;

  @override
  void initState() {
    super.initState();
    widget.client.addListener(_onClient);
    final s = widget.client.snapshot?.state;
    _lastState = s;
  }

  @override
  void dispose() {
    widget.client.removeListener(_onClient);
    super.dispose();
  }

  void _onClient() {
    if (!mounted) return;
    final snap = widget.client.snapshot;
    final newState = snap?.state;

    if (newState == GameStateEnum.flagged &&
        _lastState != GameStateEnum.flagged &&
        snap != null) {
      final loser = snap.flaggedPlayer == 1 ? snap.p1 : snap.p2;
      final winner = snap.flaggedPlayer == 1 ? snap.p2 : snap.p1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showFlagFallPopup(
          context,
          loserName: loser.name,
          winnerName: winner.name,
          onNewMatch: widget.client.reset,
        );
      });
    }
    _lastState = newState;

    if (!widget.client.connected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => ConnectScreen(client: widget.client)),
        );
      });
    }

    setState(() {});
  }

  Future<void> _disconnect() async {
    await widget.client.disconnect();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => ConnectScreen(client: widget.client)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final snap = widget.client.snapshot;
    final isWide = MediaQuery.of(context).size.width > 720;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Chess Clock'),
            const SizedBox(width: 10),
            if (snap != null) _StateChip(state: snap.state),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Ayarlar',
            icon: const Icon(Icons.settings),
            onPressed: snap == null
                ? null
                : () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SettingsScreen(client: widget.client),
                      ),
                    );
                  },
          ),
          IconButton(
            tooltip: 'Bağlantıyı kes',
            icon: const Icon(Icons.logout),
            onPressed: _disconnect,
          ),
        ],
      ),
      body: snap == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        snap.timeControl.summary,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                      ),
                      Text(
                        '${formatScore(snap.p1.score)} — ${formatScore(snap.p2.score)}',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                    child: isWide
                        ? Row(
                            children: [
                              Expanded(child: _buildCard(snap, 1)),
                              const SizedBox(width: 12),
                              Expanded(child: _buildCard(snap, 2)),
                            ],
                          )
                        : Column(
                            children: [
                              Expanded(child: _buildCard(snap, 1)),
                              const SizedBox(height: 12),
                              Expanded(child: _buildCard(snap, 2)),
                            ],
                          ),
                  ),
                ),
                _BottomBar(client: widget.client, snap: snap),
              ],
            ),
    );
  }

  Widget _buildCard(GameSnapshot snap, int playerNum) {
    final player = snap.player(playerNum);
    final isActive = snap.active == playerNum;
    final isRunning = snap.state == GameStateEnum.running;
    final isFlagged = snap.state == GameStateEnum.flagged &&
        snap.flaggedPlayer == playerNum;
    final accent = playerNum == 1 ? const Color(0xFFE3E7EE) : const Color(0xFFFFB86B);
    return PlayerCard(
      player: player,
      isActive: isActive,
      isRunning: isRunning,
      isFlagged: isFlagged,
      accent: accent,
      onTap: () => widget.client.press(playerNum),
    );
  }
}

class _StateChip extends StatelessWidget {
  final GameStateEnum state;
  const _StateChip({required this.state});

  @override
  Widget build(BuildContext context) {
    final label = switch (state) {
      GameStateEnum.idle => 'IDLE',
      GameStateEnum.running => 'RUNNING',
      GameStateEnum.paused => 'PAUSED',
      GameStateEnum.flagged => 'FLAGGED',
      GameStateEnum.unknown => '—',
    };
    final color = switch (state) {
      GameStateEnum.running => Colors.greenAccent,
      GameStateEnum.paused => Colors.amberAccent,
      GameStateEnum.flagged => Colors.redAccent,
      _ => Colors.white54,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color, letterSpacing: 1),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final ClockClient client;
  final GameSnapshot snap;
  const _BottomBar({required this.client, required this.snap});

  @override
  Widget build(BuildContext context) {
    final running = snap.state == GameStateEnum.running;
    final startLabel = running ? 'Durdur' : (snap.state == GameStateEnum.paused ? 'Devam' : 'Başlat');
    final startIcon = running ? Icons.pause : Icons.play_arrow;
    final canDeclare = snap.state == GameStateEnum.running ||
        snap.state == GameStateEnum.paused;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: client.togglePause,
                icon: Icon(startIcon),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(startLabel, style: const TextStyle(fontSize: 15)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: canDeclare
                    ? () => showMatchEndDialog(context, client, snap)
                    : null,
                icon: const Icon(Icons.emoji_events),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Text('Sonuç'),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.outlined(
              tooltip: 'Saatleri sıfırla',
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const Text('Sıfırla'),
                    content: const Text('Saatler sıfırlansın mı? (Skor korunur.)'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('İptal')),
                      TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Sıfırla')),
                    ],
                  ),
                );
                if (ok == true) client.reset();
              },
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
      ),
    );
  }
}
