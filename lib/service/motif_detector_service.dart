import 'package:chess_trainer/model/stockfish_data_model.dart';
import 'package:chess/chess.dart';
class MotifDetector {
  final EngineAnalysis analysis;

  MotifDetector(this.analysis);

  void detectMotifs() {
    final fensPerPv = getFensFromAllPvs(analysis);

    fensPerPv.forEach((pvIndex, fens) {
      for (final fen in fens) {
        detectMotifsInFen(fen); // placeholder for your motif functions
      }
    });
  }

  void detectMotifsInFen(String fen) {
    // TODO: implement actual motif detection per FEN
    print('Detecting motifs in FEN: $fen');
  }
  /// Returns a list of FENs along a single PV line
  List<String> getFensFromPv(String startingFen, List<String> pv) {
    final chess = Chess();
    chess.load(startingFen);

    final fens = <String>[];
    for (final move in pv) {
      chess.move(move); // permissive parser handles UCI moves
      fens.add(chess.fen); // save the FEN after the move
    }

    return fens;
  }

  Map<int, List<String>> getFensFromAllPvs(EngineAnalysis analysis) {
    final result = <int, List<String>>{};

    for (final entry in analysis.lines.entries) {
      final multipv = entry.key;
      final pvLine = entry.value.pv;
      final fens = getFensFromPv(analysis.fen, pvLine);
      result[multipv] = fens;
    }

    return result;
  }
}