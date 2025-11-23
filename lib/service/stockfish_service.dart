import 'dart:async';
import 'package:multistockfish/multistockfish.dart';
import 'package:flutter/foundation.dart';
import 'package:chess_trainer/model/stockfish_data_model.dart';

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

  Future<EngineAnalysis?> analyzeFen(
    String fen, {
    int depth = 3,
    int pv = 3,
  }) async {
    if (!isReady.value) {
      debugPrint('Engine not ready yet.');
      return null;
    }

    final completer = Completer<EngineAnalysis?>();
    final Map<int, PvLine> pvLines = {};

    late StreamSubscription sub;
    sub = _engine.stdout.listen((line) {
      // --- Parse "info depth ..." lines ---
      if (line.startsWith('info')) {
        final parts = line.split(' ');

        int? depthVal;
        int? seldepthVal;
        int? multipvVal;
        int? score;
        String? scoreType;
        List<String> pv = [];

        for (int i = 0; i < parts.length; i++) {
          switch (parts[i]) {
            case "depth":
              if (i + 1 < parts.length) depthVal = int.tryParse(parts[i + 1]);
              break;

            case "seldepth":
              if (i + 1 < parts.length) seldepthVal = int.tryParse(parts[i + 1]);
              break;

            case "multipv":
              if (i + 1 < parts.length) multipvVal = int.tryParse(parts[i + 1]);
              break;

            case "score":
              if (i + 2 < parts.length) {
                scoreType = parts[i + 1];       // cp / mate
                score = int.tryParse(parts[i + 2]);
              }
              break;

            case "pv":
              pv = parts.sublist(i + 1);
              i = parts.length; // Done
              break;
          }
        }

        if (multipvVal != null &&
            depthVal != null &&
            seldepthVal != null &&
            score != null &&
            scoreType != null) {
          pvLines[multipvVal] = PvLine(
            multipv: multipvVal,
            depth: depthVal,
            seldepth: seldepthVal,
            scoreType: scoreType,
            score: score,
            pv: pv,
          );
        }
      }

      // --- Parse final "bestmove" ---
      if (line.startsWith('bestmove')) {
        final parts = line.split(' ');

        final bestMove = parts.length > 1 ? parts[1] : "";
        final ponder =
            parts.length > 3 && parts[2] == "ponder" ? parts[3] : null;

        sub.cancel();
        completer.complete(
          EngineAnalysis(
            bestMove: bestMove,
            ponder: ponder,
            lines: pvLines,
            fen: fen
          ),
        );
      }
    });

    // Send UCI commands
    _engine.stdin = 'ucinewgame';
    _engine.stdin = 'position fen $fen';
    _engine.stdin = 'setoption name MultiPV value $pv';
    _engine.stdin = 'go depth $depth';

    return completer.future;
  }


  void dispose() {
    _engine.dispose();
  }
}
