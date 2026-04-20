import 'package:flutter/material.dart';

import '../engine/game_engine.dart';
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
    if (!tc.isSymmetric) return 'custom';
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
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            leading: Icon(
              currentPreset == 'custom'
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: currentPreset == 'custom'
                  ? Theme.of(context).colorScheme.primary
                  : Colors.white54,
            ),
            title: const Text('Özel tempo'),
            subtitle: currentPreset == 'custom' && snap != null
                ? Text(snap.timeControl.summary)
                : const Text('İki oyuncu için farklı süre / özel süre & increment'),
            trailing: const Icon(Icons.tune),
            onTap: _openCustomTempoDialog,
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

  Future<void> _openCustomTempoDialog() async {
    final tc = widget.client.snapshot?.timeControl;
    final result = await showDialog<_CustomTempoResult>(
      context: context,
      builder: (_) => _CustomTempoDialog(initial: tc),
    );
    if (result == null) return;
    widget.client.setCustomTimeControl(
      p1BaseMs: result.p1BaseMs,
      p2BaseMs: result.p2BaseMs,
      incrementMs: result.incrementMs,
      mode: result.mode,
    );
  }
}

class _CustomTempoResult {
  final int p1BaseMs;
  final int p2BaseMs;
  final int incrementMs;
  final TimeControlMode mode;

  const _CustomTempoResult({
    required this.p1BaseMs,
    required this.p2BaseMs,
    required this.incrementMs,
    required this.mode,
  });
}

class _CustomTempoDialog extends StatefulWidget {
  final TimeControlSnapshot? initial;

  const _CustomTempoDialog({this.initial});

  @override
  State<_CustomTempoDialog> createState() => _CustomTempoDialogState();
}

class _CustomTempoDialogState extends State<_CustomTempoDialog> {
  late bool _symmetric;
  late TextEditingController _p1MinCtl;
  late TextEditingController _p1SecCtl;
  late TextEditingController _p2MinCtl;
  late TextEditingController _p2SecCtl;
  late TextEditingController _incSecCtl;
  TimeControlMode _mode = TimeControlMode.fischer;

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    final p1Base = init?.baseMs ?? 300000;
    final p2Base = init?.p2BaseMs ?? p1Base;
    final inc = init?.incrementMs ?? 0;
    _symmetric = p1Base == p2Base;
    _p1MinCtl = TextEditingController(text: '${p1Base ~/ 60000}');
    _p1SecCtl = TextEditingController(text: '${(p1Base ~/ 1000) % 60}');
    _p2MinCtl = TextEditingController(text: '${p2Base ~/ 60000}');
    _p2SecCtl = TextEditingController(text: '${(p2Base ~/ 1000) % 60}');
    _incSecCtl = TextEditingController(text: '${inc ~/ 1000}');
    switch (init?.mode) {
      case 'fischer':
        _mode = TimeControlMode.fischer;
        break;
      case 'bronstein':
        _mode = TimeControlMode.bronstein;
        break;
      case 'sudden_death':
        _mode = TimeControlMode.suddenDeath;
        break;
      default:
        _mode = inc > 0 ? TimeControlMode.fischer : TimeControlMode.suddenDeath;
    }
  }

  @override
  void dispose() {
    _p1MinCtl.dispose();
    _p1SecCtl.dispose();
    _p2MinCtl.dispose();
    _p2SecCtl.dispose();
    _incSecCtl.dispose();
    super.dispose();
  }

  int _parseMs(TextEditingController minCtl, TextEditingController secCtl) {
    final m = int.tryParse(minCtl.text.trim()) ?? 0;
    final s = int.tryParse(secCtl.text.trim()) ?? 0;
    final total = m * 60 + s;
    return (total < 0 ? 0 : total) * 1000;
  }

  void _submit() {
    final p1 = _parseMs(_p1MinCtl, _p1SecCtl);
    final p2 = _symmetric ? p1 : _parseMs(_p2MinCtl, _p2SecCtl);
    final incSec = int.tryParse(_incSecCtl.text.trim()) ?? 0;
    final inc = (incSec < 0 ? 0 : incSec) * 1000;
    final mode = inc == 0 && _mode != TimeControlMode.suddenDeath
        ? TimeControlMode.suddenDeath
        : _mode;
    if (p1 <= 0 && p2 <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('En az bir oyuncuya süre ver')),
      );
      return;
    }
    Navigator.of(context).pop(_CustomTempoResult(
      p1BaseMs: p1,
      p2BaseMs: p2,
      incrementMs: inc,
      mode: mode,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Özel tempo'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('İki oyuncuya eşit süre'),
              value: _symmetric,
              onChanged: (v) => setState(() => _symmetric = v),
            ),
            const SizedBox(height: 8),
            Text(
              _symmetric ? 'Süre' : 'P1 süresi',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            _MinSecRow(minCtl: _p1MinCtl, secCtl: _p1SecCtl),
            if (!_symmetric) ...[
              const SizedBox(height: 14),
              const Text('P2 süresi',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              _MinSecRow(minCtl: _p2MinCtl, secCtl: _p2SecCtl),
            ],
            const SizedBox(height: 14),
            const Text('Increment (sn)',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: _incSecCtl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 14),
            const Text('Mod', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            DropdownButtonFormField<TimeControlMode>(
              initialValue: _mode,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(
                  value: TimeControlMode.suddenDeath,
                  child: Text('Sudden death'),
                ),
                DropdownMenuItem(
                  value: TimeControlMode.fischer,
                  child: Text('Fischer (+increment her hamlede)'),
                ),
                DropdownMenuItem(
                  value: TimeControlMode.bronstein,
                  child: Text('Bronstein (geri kazanım)'),
                ),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _mode = v);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('İptal'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Uygula')),
      ],
    );
  }
}

class _MinSecRow extends StatelessWidget {
  final TextEditingController minCtl;
  final TextEditingController secCtl;

  const _MinSecRow({required this.minCtl, required this.secCtl});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: minCtl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'dk',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: secCtl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'sn',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
      ],
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
