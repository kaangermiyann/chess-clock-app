import 'package:flutter/material.dart';

import '../models/snapshot.dart';
import '../services/clock_client.dart';
import '../services/local_clock_client.dart';
import 'connect_screen.dart';

class SettingsScreen extends StatefulWidget {
  final ClockClient client;
  final void Function(ClockClient next)? onSwitchBackend;

  const SettingsScreen({
    super.key,
    required this.client,
    this.onSwitchBackend,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _p1Controller;
  late final TextEditingController _p2Controller;

  @override
  void initState() {
    super.initState();
    final snap = widget.client.snapshot;
    _p1Controller = TextEditingController(text: snap?.p1.name ?? 'White');
    _p2Controller = TextEditingController(text: snap?.p2.name ?? 'Black');
    widget.client.addListener(_onClient);
  }

  @override
  void dispose() {
    widget.client.removeListener(_onClient);
    _p1Controller.dispose();
    _p2Controller.dispose();
    super.dispose();
  }

  void _onClient() {
    if (!mounted) return;
    setState(() {});
  }

  String _currentPresetKey() {
    final tc = widget.client.snapshot?.timeControl;
    if (tc == null) return 'blitz_5_3';
    const presetValues = <String, (int, int, String)>{
      'bullet_1_0': (60000, 0, 'sudden_death'),
      'bullet_2_1': (120000, 1000, 'fischer'),
      'blitz_3_0': (180000, 0, 'sudden_death'),
      'blitz_3_2': (180000, 2000, 'fischer'),
      'blitz_5_0': (300000, 0, 'sudden_death'),
      'blitz_5_3': (300000, 3000, 'fischer'),
      'rapid_10_0': (600000, 0, 'sudden_death'),
      'rapid_15_10': (900000, 10000, 'fischer'),
      'classical_30_0': (1800000, 0, 'sudden_death'),
    };
    for (final entry in presetValues.entries) {
      if (entry.value.$1 == tc.baseMs &&
          entry.value.$2 == tc.incrementMs &&
          entry.value.$3 == tc.mode) {
        return entry.key;
      }
    }
    return 'custom';
  }

  @override
  Widget build(BuildContext context) {
    final snap = widget.client.snapshot;
    final currentPreset = _currentPresetKey();

    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const _SectionTitle('Oyuncu isimleri'),
          const SizedBox(height: 8),
          TextField(
            controller: _p1Controller,
            decoration: const InputDecoration(
              labelText: 'P1 (beyaz)',
              hintText: 'White',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _saveNames(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _p2Controller,
            decoration: const InputDecoration(
              labelText: 'P2 (siyah)',
              hintText: 'Black',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _saveNames(),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonal(
              onPressed: _saveNames,
              child: const Text('İsimleri kaydet'),
            ),
          ),
          const SizedBox(height: 28),
          const _SectionTitle('Zaman kontrolü'),
          const SizedBox(height: 8),
          if (snap != null)
            Text(
              'Aktif: ${snap.timeControl.summary}',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            ),
          const SizedBox(height: 12),
          RadioGroup<String>(
            groupValue: currentPreset,
            onChanged: (v) {
              if (v != null) widget.client.setTimeControlPreset(v);
            },
            child: Column(
              children: [
                for (final e in kTimeControlPresets.entries)
                  RadioListTile<String>(
                    value: e.key,
                    title: Text(e.value),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const _SectionTitle('Skor'),
          const SizedBox(height: 8),
          if (snap != null)
            Text(
              '${snap.p1.name} ${formatScore(snap.p1.score)} — ${formatScore(snap.p2.score)} ${snap.p2.name}',
              style: const TextStyle(fontSize: 16),
            ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const Text('Skoru sıfırla'),
                    content: const Text('Tüm maç skoru sıfırlansın mı?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('İptal')),
                      TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Sıfırla')),
                    ],
                  ),
                );
                if (ok == true) widget.client.resetScores();
              },
              icon: const Icon(Icons.restart_alt),
              label: const Text('Skoru sıfırla'),
            ),
          ),
          const SizedBox(height: 28),
          const _SectionTitle('Bağlantı'),
          const SizedBox(height: 8),
          Text(
            widget.client.isLocal
                ? 'Şu an offline modda, tüm mantık telefonda çalışıyor.'
                : 'Fiziksel saate bağlı: ${widget.client.url ?? "-"}',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: widget.client.isLocal
                ? OutlinedButton.icon(
                    onPressed: widget.onSwitchBackend == null
                        ? null
                        : _openConnect,
                    icon: const Icon(Icons.wifi),
                    label: const Text('Saate bağlan'),
                  )
                : OutlinedButton.icon(
                    onPressed: widget.onSwitchBackend == null
                        ? null
                        : _goOffline,
                    icon: const Icon(Icons.wifi_off),
                    label: const Text('Bağlantıyı kes (offline\'a dön)'),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _openConnect() async {
    final cb = widget.onSwitchBackend;
    if (cb == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ConnectScreen(onConnected: cb),
      ),
    );
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _goOffline() async {
    final cb = widget.onSwitchBackend;
    if (cb == null) return;
    await widget.client.disconnect();
    cb(LocalClockClient());
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void _saveNames() {
    widget.client.setNames(_p1Controller.text.trim(), _p2Controller.text.trim());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('İsimler kaydedildi'), duration: Duration(seconds: 1)),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: Colors.white70,
        ),
      );
}
