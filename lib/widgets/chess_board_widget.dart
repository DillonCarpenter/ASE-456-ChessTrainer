import 'package:chess_trainer/model/stockfish_data_model.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:chessground/chessground.dart';
import 'package:chess/chess.dart' as ChessLibrary;
import 'package:chess_trainer/service/stockfish_service.dart';
import 'package:chess_trainer/model/motif_model.dart';
import 'package:chess_trainer/service/motif_detector_service.dart';

class ChessGUI extends StatefulWidget {
  final String? fen;
  final String? pgn;
  final StockfishHelper stockfish;

  const ChessGUI({
    super.key,
    this.fen,
    this.pgn,
    required this.stockfish,
  });

  @override
  State<ChessGUI> createState() => _ChessGUIState();

}

class _ChessGUIState extends State<ChessGUI> {
  late List<String> _fens;
  int _currentIndex = 0;
  Map<int, List<Motif>>? _motifResults;
  EngineAnalysis? _analysis;

  @override
  void initState() {
    super.initState();

    if (widget.pgn != null && widget.pgn!.isNotEmpty) {
      _fens = _createMultipleFENs(widget.pgn!);
    } else if (widget.fen != null && widget.fen!.isNotEmpty) {
      _fens = [widget.fen!];
    } else {
      _fens = ["rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"];
    }

    _analyzeCurrent();
  }

  @override
  void didUpdateWidget(covariant ChessGUI oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.pgn != oldWidget.pgn && widget.pgn != null && widget.pgn!.isNotEmpty) {
      debugPrint('--- PGN START ---');
      debugPrint('[${widget.pgn}]');  // brackets make whitespace/newlines visible
      debugPrint('--- PGN END ---');
      debugPrint('PGN length: ${widget.pgn?.length}');
      _fens = _createMultipleFENs(widget.pgn!);
      debugPrint('FENS after being inserted into _createMultipleFENs');
      for (var f in _fens) debugPrint(f);
      _analyzeCurrent();
    } else if (widget.fen != oldWidget.fen && widget.fen != null && widget.fen!.isNotEmpty) {
      _fens = [widget.fen!];
      _analyzeCurrent();
    }
  }

  Future<void> _analyzeCurrent() async {
    final fen = _fens[_currentIndex];
    final analysis = await widget.stockfish.analyzeFen(fen);

    if (analysis == null) return;

    // 1. Run motif detection
    final detector = MotifDetector(analysis);
    final motifs = detector.detectMotifs(); // returns Map<int, List<Motif>>

    if (!mounted) return;

    // 2. Store everything in state
    setState(() {
      _motifResults = motifs;
      _analysis = analysis; // optional, if not already stored
    });
  }


  void _next() {
    if (_currentIndex < _fens.length - 1) {
      setState(() => _currentIndex++);
      _analyzeCurrent();
    }
  }

  void _prev() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
      _analyzeCurrent();
    }
  }

  Widget _buildPvDisplay(
    PvLine pv,
    List<Motif> motifs,
  ) {
    final finalMotif = motifs.last;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("PV ${pv.multipv} (depth: ${pv.depth})",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                )),
            const SizedBox(height: 8),

            // MOVES
            Text("Moves: ${pv.pv.join(' ')}"),

            const SizedBox(height: 8),

            // EVALUATION
            Text("Eval: ${_evalString(pv)}"),

            const SizedBox(height: 12),

            // MOTIFS
            Text("Motifs (final position):",
                style: const TextStyle(fontWeight: FontWeight.bold)),

            Text("• Pawn Islands (W/B): "
                "${finalMotif.whitePawnIslands} / ${finalMotif.blackPawnIslands}"),

            Text("• Queenside Majority (W/B): "
                "${finalMotif.whiteQueensideMajority} / "
                "${finalMotif.blackQueensideMajority}"),

            Text("• Pawn Structure (White): "
                "iso ${finalMotif.whitePawnStructure['isolated']}, "
                "dbl ${finalMotif.whitePawnStructure['doubled']}, "
                "tri ${finalMotif.whitePawnStructure['tripled']}"),

            Text("• Pawn Structure (Black): "
                "iso ${finalMotif.blackPawnStructure['isolated']}, "
                "dbl ${finalMotif.blackPawnStructure['doubled']}, "
                "tri ${finalMotif.blackPawnStructure['tripled']}"),

            Text("• Endgame Type: ${finalMotif.endgameType}"),
          ],
        ),
      ),
    );
  }

  String _evalString(PvLine pv) {
  if (pv.scoreType == "cp") {
    return (pv.score / 100).toStringAsFixed(2);
  } else {
    return "Mate ${pv.score}";
  }
}
  //Postponed for now
  List<String> _createMultipleFENs(String pgn) {
    final chess = ChessLibrary.Chess();
    //For whatever reason, the chess.dart package has trouble with the PGN's I give it so this feature had to be postponed.
    bool status = chess.load_pgn(pgn);
    final moves = chess.getHistory();
    debugPrint("moves");
    debugPrint(moves.length.toString());
    debugPrint(status.toString());
    final chess1 = ChessLibrary.Chess();

    var FENS = moves.map((move) {
      chess1.move(move);
      return chess1.fen;
    }).toList();
    debugPrint("_createMultipleFENs output: ");

    return FENS;
  }

  @override
  Widget build(BuildContext context) {
    final fen = _fens[_currentIndex];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Chessboard.fixed(
          key: ValueKey(fen),
          size: 300,
          orientation: Side.white,
          fen: fen,
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(onPressed: _prev, icon: const Icon(Icons.arrow_back)),
            Text('${_currentIndex + 1}/${_fens.length}'),
            IconButton(onPressed: _next, icon: const Icon(Icons.arrow_forward)),
          ],
        ),
        if (_motifResults != null)
          ..._analysis!.lines.entries.map((entry) {
            final pvIndex = entry.key;
            final pv = entry.value;

            final motifs = _motifResults![pvIndex]!;
            return _buildPvDisplay(pv, motifs);
          }),
      ],
    );
  }
}
