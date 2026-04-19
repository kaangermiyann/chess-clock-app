import 'dart:async';

import 'package:flutter/material.dart';

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
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  Timer? _dismissTimer;
  bool _closing = false;

  static const _showDuration = Duration(milliseconds: 3200);
  static const _animDuration = Duration(milliseconds: 260);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _animDuration);
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, -0.4), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
    _dismissTimer = Timer(_showDuration, _close);
  }

  Future<void> _close() async {
    if (_closing) return;
    _closing = true;
    _dismissTimer?.cancel();
    if (_controller.isAnimating || _controller.status == AnimationStatus.completed) {
      await _controller.reverse();
    }
    widget.onDone();
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: topPadding + kToolbarHeight + 8,
      left: 12,
      right: 12,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _slide,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B1E24),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.35),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.45),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.flag_rounded, color: accent, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${widget.loserName} bayrağını düşürdü',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: widget.winnerName,
                                    style: TextStyle(
                                      color: accent,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const TextSpan(
                                    text: '  +1 puan',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.onNewMatch != null)
                        TextButton(
                          onPressed: () {
                            widget.onNewMatch!();
                            _close();
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: accent,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            minimumSize: const Size(0, 32),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Yeni maç',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        color: Colors.white54,
                        splashRadius: 18,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(width: 28, height: 28),
                        onPressed: _close,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
