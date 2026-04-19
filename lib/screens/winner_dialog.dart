import 'package:flutter/material.dart';

import '../models/snapshot.dart';
import '../services/clock_client.dart';

/// Manual match-end dialog: checkmate, resignation, agreed draw.
/// Caller should only open this when state is RUNNING or PAUSED
/// (flag fall is handled automatically server-side).
Future<void> showMatchEndDialog(
  BuildContext context,
  ClockClient client,
  GameSnapshot snap,
) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Maç sonucu'),
        content: const Text('Nasıl bitti?'),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () {
              client.declareWinner(1);
              Navigator.of(dialogContext).pop();
            },
            child: Text('${snap.p1.name} kazandı'),
          ),
          TextButton(
            onPressed: () {
              client.declareWinner(2);
              Navigator.of(dialogContext).pop();
            },
            child: Text('${snap.p2.name} kazandı'),
          ),
          TextButton(
            onPressed: () {
              client.declareWinner(0);
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Beraberlik'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('İptal'),
          ),
        ],
      );
    },
  );
}
