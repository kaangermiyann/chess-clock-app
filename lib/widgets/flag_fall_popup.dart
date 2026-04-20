import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void showFlagFallPopup(
  BuildContext context, {
  required String loserName,
  required String winnerName,
  VoidCallback? onNewMatch,
}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _FlagFallPopup(
      loserName: loserName,
      winnerName: winnerName,
      onNewMatch: onNewMatch,
      onDone: () {
        if (entry.mounted) entry.remove();
      },
    ),
  );
  overlay.insert(entry);
}

class _FlagFallPopup extends StatefulWidget {
  final String loserName;
  final String winnerName;
  final VoidCallback? onNewMatch;
  final VoidCallback onDone;

  const _FlagFallPopup({
    required this.loserName,
    required this.winnerName,
    required this.onDone,
    this.onNewMatch,
  });

  @override
  State<_FlagFallPopup> createState() => _FlagFallPopupState();
}

class _FlagFallPopupState extends State<_FlagFallPopup>
    with TickerProviderStateMixin {
  late final AnimationController _entry;
  late final AnimationController _glow;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  Timer? _dismissTimer;
  bool _closing = false;

  static const _autoDismiss = Duration(milliseconds: 6000);
  static const _entryDuration = Duration(milliseconds: 520);

  @override
  void initState() {
    super.initState();
    _entry = AnimationController(vsync: this, duration: _entryDuration);
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _fade = CurvedAnimation(parent: _entry, curve: Curves.easeOut);
    _scale = CurvedAnimation(parent: _entry, curve: Curves.easeOutBack);
    _entry.forward();
    HapticFeedback.heavyImpact();
    _dismissTimer = Timer(_autoDismiss, _close);
  }

  Future<void> _close() async {
    if (_closing) return;
    _closing = true;
    _dismissTimer?.cancel();
    _glow.stop();
    if (mounted) {
      await _entry.reverse();
    }
    widget.onDone();
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _entry.dispose();
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFFFB86B);
    const danger = Color(0xFFFF5C5C);
    const bg = Color(0xFF0B0D10);

    return Positioned.fill(
      child: AnimatedBuilder(
        animation: Listenable.merge([_entry, _glow]),
        builder: (context, _) {
          final fade = _fade.value;
          final glow = _glow.value;
          return Stack(
            children: [
              Opacity(
                opacity: fade,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _close,
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.55),
                    ),
                  ),
                ),
              ),
              Center(
                child: FadeTransition(
                  opacity: _fade,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.82, end: 1.0).animate(_scale),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: _Card(
                          loserName: widget.loserName,
                          winnerName: widget.winnerName,
                          accent: accent,
                          danger: danger,
                          bg: bg,
                          glow: glow,
                          onClose: _close,
                          onNewMatch: widget.onNewMatch == null
                              ? null
                              : () {
                                  HapticFeedback.selectionClick();
                                  widget.onNewMatch!();
                                  _close();
                                },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String loserName;
  final String winnerName;
  final Color accent;
  final Color danger;
  final Color bg;
  final double glow;
  final VoidCallback onClose;
  final VoidCallback? onNewMatch;

  const _Card({
    required this.loserName,
    required this.winnerName,
    required this.accent,
    required this.danger,
    required this.bg,
    required this.glow,
    required this.onClose,
    this.onNewMatch,
  });

  @override
  Widget build(BuildContext context) {
    final glowAlpha = 0.30 + 0.45 * glow;
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: accent, width: 3),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: glowAlpha),
              blurRadius: 48,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: danger.withValues(alpha: 0.18 + 0.22 * glow),
              blurRadius: 70,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 20, 26, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _TitleStripe(accent: accent, danger: danger, glow: glow),
              const SizedBox(height: 22),
              Icon(
                Icons.flag_rounded,
                size: 72,
                color: danger,
                shadows: [
                  Shadow(
                    color: danger.withValues(alpha: 0.4 + 0.4 * glow),
                    blurRadius: 28,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                loserName.toUpperCase(),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 4,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '· süresi bitti ·',
                style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.55),
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 22),
              _Divider(accent: accent),
              const SizedBox(height: 18),
              _WinnerRow(winnerName: winnerName, accent: accent, bg: bg),
              const SizedBox(height: 24),
              Row(
                children: [
                  if (onNewMatch != null) ...[
                    Expanded(
                      child: _PixelButton(
                        label: 'YENİ MAÇ',
                        color: accent,
                        filled: true,
                        onTap: onNewMatch!,
                        bg: bg,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: _PixelButton(
                      label: 'KAPAT',
                      color: Colors.white70,
                      filled: false,
                      onTap: onClose,
                      bg: bg,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TitleStripe extends StatelessWidget {
  final Color accent;
  final Color danger;
  final double glow;
  const _TitleStripe({
    required this.accent,
    required this.danger,
    required this.glow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        border: Border.all(
          color: accent.withValues(alpha: 0.7),
          width: 1.5,
        ),
      ),
      child: Text(
        '◆  FLAG  FALLEN  ◆',
        style: TextStyle(
          fontFamily: 'Courier',
          fontSize: 13,
          fontWeight: FontWeight.w900,
          color: accent,
          letterSpacing: 4,
          shadows: [
            Shadow(
              color: accent.withValues(alpha: 0.5 + 0.4 * glow),
              blurRadius: 14,
            ),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final Color accent;
  const _Divider({required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 2,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            accent.withValues(alpha: 0.7),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

class _WinnerRow extends StatelessWidget {
  final String winnerName;
  final Color accent;
  final Color bg;
  const _WinnerRow({
    required this.winnerName,
    required this.accent,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.emoji_events_rounded, color: accent, size: 26),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            winnerName.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Courier',
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: accent,
              letterSpacing: 3,
              shadows: [
                Shadow(
                  color: accent.withValues(alpha: 0.6),
                  blurRadius: 12,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: accent),
          child: Text(
            '+1',
            style: TextStyle(
              fontFamily: 'Courier',
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: bg,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }
}

class _PixelButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool filled;
  final Color bg;
  final VoidCallback onTap;

  const _PixelButton({
    required this.label,
    required this.color,
    required this.filled,
    required this.bg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final background = filled ? color : Colors.transparent;
    final foreground = filled ? bg : color;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: background,
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: foreground,
                letterSpacing: 3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
