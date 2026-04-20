import 'package:flutter/material.dart';

import '../services/remote_clock_client.dart';

class ConnectScreen extends StatefulWidget {
  final void Function(RemoteClockClient client) onConnected;
  final String? initialUrl;

  const ConnectScreen({
    super.key,
    required this.onConnected,
    this.initialUrl,
  });

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  late final TextEditingController _urlController;
  bool _connecting = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(
      text: widget.initialUrl ?? 'ws://localhost:8765',
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() => _errorText = 'URL gerekli');
      return;
    }
    setState(() {
      _connecting = true;
      _errorText = null;
    });
    final client = RemoteClockClient();
    try {
      await client.connect(url);
      if (!mounted) {
        client.dispose();
        return;
      }
      widget.onConnected(client);
      Navigator.of(context).pop();
    } catch (e) {
      client.dispose();
      if (!mounted) return;
      setState(() {
        _errorText = 'Bağlanılamadı: $e';
        _connecting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saate bağlan')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Fiziksel saate bağlan',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _urlController,
                  enabled: !_connecting,
                  decoration: InputDecoration(
                    labelText: 'WebSocket URL',
                    hintText: 'ws://localhost:8765',
                    border: const OutlineInputBorder(),
                    errorText: _errorText,
                  ),
                  onSubmitted: (_) => _connect(),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _connecting ? null : _connect,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: _connecting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Bağlan', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _connecting ? null : () => Navigator.of(context).pop(),
                  child: const Text('İptal, offline devam et'),
                ),
                const SizedBox(height: 16),
                Text(
                  'Telefondan bağlanıyorsan Mac\'in yerel IP\'sini kullan.\n'
                  'ipconfig getifaddr en0 ile öğrenebilirsin.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
