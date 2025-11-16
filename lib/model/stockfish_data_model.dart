class PvLine {
  final int multipv;
  final int depth;
  final int seldepth;
  final String scoreType; // "cp" or "mate"
  final int score;
  final List<String> pv;

  PvLine({
    required this.multipv,
    required this.depth,
    required this.seldepth,
    required this.scoreType,
    required this.score,
    required this.pv,
  });

  @override
  String toString() =>
      "PV$multipv depth $depth score $scoreType $score pv $pv";
}

class EngineAnalysis {
  final String bestMove;
  final String? ponder;
  final Map<int, PvLine> lines; // multipv → PvLine
  final String fen;

  EngineAnalysis({
    required this.bestMove,
    required this.ponder,
    required this.lines,
    required this.fen
  });
}
