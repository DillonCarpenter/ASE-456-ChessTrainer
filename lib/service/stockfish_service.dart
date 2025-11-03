import 'dart:async';
import 'package:multistockfish/multistockfish.dart';
import 'package:flutter/foundation.dart';

class StockfishHelper {
  late final Stockfish _engine;
  final ValueNotifier<bool> isReady = ValueNotifier(false);

  Future<void> initialize() async {
    _engine = Stockfish(flavor: StockfishFlavor.sf16);

    // Log stdout for debugging
    _engine.stdout.listen((line) {
      debugPrint('[Stockfish] $line');
    });

    // Listen for engine state changes
    _engine.state.addListener(() {
      final state = _engine.state.value;
      debugPrint('Stockfish state: $state');

      if (state == StockfishState.ready) {
        isReady.value = true;
        // Basic UCI handshake
        _engine.stdin = 'uci';
        _engine.stdin = 'isready';
      }
    });
  }

  Future<String?> analyzeFen(String fen, {int depth = 15}) async {
    if (!isReady.value) {
      debugPrint('Engine not ready yet.');
      return null;
    }

    final completer = Completer<String?>();

    late StreamSubscription sub;
    sub = _engine.stdout.listen((line) {
      if (line.startsWith('bestmove')) {
        final parts = line.split(' ');
        final bestMove = parts.length > 1 ? parts[1] : null;
        sub.cancel();
        completer.complete(bestMove);
      }
    });

    // Send UCI commands
    _engine.stdin = 'ucinewgame';
    _engine.stdin = 'position fen $fen';
    _engine.stdin = 'go depth $depth';

    return completer.future;
  }

  void dispose() {
    _engine.dispose();
  }
}
