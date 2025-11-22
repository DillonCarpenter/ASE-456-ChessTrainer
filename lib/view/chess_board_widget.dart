import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:chessground/chessground.dart';
import 'package:chess/chess.dart' as ChessLibrary;
import 'package:chess_trainer/service/stockfish_service.dart';

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
  String? _bestMove;

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
      _fens = _createMultipleFENs(widget.pgn!);
      _analyzeCurrent();
    } else if (widget.fen != oldWidget.fen && widget.fen != null && widget.fen!.isNotEmpty) {
      _fens = [widget.fen!];
      _analyzeCurrent();
    }
  }

  Future<void> _analyzeCurrent() async {
    final fen = _fens[_currentIndex];
    final analysis = await widget.stockfish.analyzeFen(fen);
    if (mounted) {
      setState(() => _bestMove = analysis!.bestMove);
    }
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

  List<String> _createMultipleFENs(String pgn) {
    final chess = ChessLibrary.Chess();
    chess.load_pgn(pgn);
    final moves = chess.history;
    final chess1 = ChessLibrary.Chess();

    var FENS = moves.map((move) {
      chess1.move(move);
      return chess1.fen;
    }).toList();
    debugPrint("_createMultipleFENs output: ");
    for (var f in FENS) debugPrint(f);
    debugPrint("Inserted PGN:");
    debugPrint(pgn);
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
        if (_bestMove != null)
          Text('Best move: $_bestMove', style: const TextStyle(fontSize: 14)),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(onPressed: _prev, icon: const Icon(Icons.arrow_back)),
            Text('${_currentIndex + 1}/${_fens.length}'),
            IconButton(onPressed: _next, icon: const Icon(Icons.arrow_forward)),
          ],
        ),
      ],
    );
  }
}
