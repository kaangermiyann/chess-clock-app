import 'package:flutter/material.dart';

import '../models/snapshot.dart';

class PlayerCard extends StatelessWidget {
  final PlayerSnapshot player;
  final bool isActive;
  final bool isRunning;
  final bool isFlagged;
  final VoidCallback onTap;
  final Color accent;

  const PlayerCard({
    super.key,
    required this.player,
    required this.isActive,
    required this.isRunning,
    required this.isFlagged,
    required this.onTap,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final highlighted = isActive && isRunning;
    final bgColor = highlighted ? accent.withValues(alpha: 0.22) : Colors.white.withValues(alpha: 0.04);
    final borderColor = highlighted
        ? accent
        : (isFlagged ? Colors.redAccent.withValues(alpha: 0.6) : Colors.white24);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: highlighted ? 2.5 : 1.2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        player.name,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      'score ${formatScore(player.score)}',
                      style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.6)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.contain,
                    alignment: Alignment.center,
                    child: Text(
                      formatTime(player.timeMs),
                      style: TextStyle(
                        fontSize: 110,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        fontWeight: FontWeight.w300,
                        letterSpacing: -2,
                        color: isFlagged
                            ? Colors.redAccent
                            : (highlighted ? accent : Colors.white),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'moves ${player.moves}',
                      style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.6)),
                    ),
                    if (highlighted)
                      Text(
                        'ON MOVE',
                        style: TextStyle(
                          fontSize: 12,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w700,
                          color: accent,
                        ),
                      )
                    else if (isFlagged)
                      const Text(
                        'FLAG',
                        style: TextStyle(
                          fontSize: 12,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.redAccent,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
