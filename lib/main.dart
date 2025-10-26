import 'package:flutter/material.dart';
import 'package:multistockfish/multistockfish.dart'; // gives us Stockfish, StockfishFlavor, StockfishState
import 'package:dartchess/dartchess.dart';
import 'package:chessground/chessground.dart'; //UI
import 'dart:async';

void main() => runApp(const ChessApp());

class ChessApp extends StatefulWidget {
  const ChessApp({super.key});

  @override
  State<ChessApp> createState() => _ChessAppState();
}

class _ChessAppState extends State<ChessApp> {
  Stockfish? _engine;
  bool _engineReady = false;

  final TextEditingController _fenController = TextEditingController();
  String? _userFen;
  String? _bestMove;

  @override
  void initState() {
    super.initState();
    _initEngine();
  }

  Future<void> _initEngine() async {
    // Create the engine (only one allowed)
    final engine = Stockfish(flavor: StockfishFlavor.sf16);

    // Listen to stdout for debugging
    engine.stdout.listen((line) {
      debugPrint('[Stockfish] $line');
    });

    // React to state changes
    engine.state.addListener(() {
      final state = engine.state.value;
      debugPrint('Stockfish state: $state');

      if (state == StockfishState.ready) {
        setState(() => _engineReady = true);

        // Basic UCI handshake
        engine.stdin = 'uci';
        engine.stdin = 'isready';
      }
    });

    _engine = engine;
  }

  @override
  void dispose() {
    _engine?.dispose();
    _fenController.dispose();
    super.dispose();
  }

  Future<String?> analyzeFen(String fen, {int depth = 15}) async {
    if (!_engineReady) {
      debugPrint('Engine not ready');
      return null;
    }

    // Clear previous output (optional, for clarity)
    debugPrint('--- Analyzing FEN ---');
    debugPrint(fen);

    final completer = Completer<String?>();
    String? bestMove;

    // Listen for Stockfish output
    late final StreamSubscription sub;
    sub = _engine!.stdout.listen((line) {
      debugPrint('[Stockfish] $line');

      // Check for the bestmove line
      if (line.startsWith('bestmove')) {
        final parts = line.split(' ');
        if (parts.length >= 2) {
          bestMove = parts[1];
          completer.complete(bestMove);
        } else {
          completer.complete(null);
        }
        sub.cancel(); // Stop listening once bestmove is found
      }
    });

    // Send FEN and start analysis
    _engine!.stdin = 'position fen $fen';
    _engine!.stdin = 'go depth $depth';

    // Wait for Stockfish to respond with bestmove
    final result = await completer.future;
    debugPrint('Best move: $result');
    return result;
  }
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stockfish FEN Demo',
      home: Scaffold(
        appBar: AppBar(title: const Text('Stockfish FEN Input')),
        body: Center(
          child: !_engineReady
              ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Starting Stockfish engine...'),
                  ],
                )
              : Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Enter a FEN string:',
                        style: TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _fenController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText:
                              'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () async {
                          final fen = _fenController.text.trim();
                          debugPrint(_engineReady.toString());

                          if (_engineReady) {
                            final bestMove = await analyzeFen(fen);

                            setState(() {
                              _userFen = fen;
                              _bestMove = bestMove;
                            });
                          }
                        },
                        child: const Text('Submit FEN'),
                      ),
                      const SizedBox(height: 20),
                      if (_userFen != null && _userFen!.isNotEmpty)
                        Text('Received FEN:\n$_userFen',
                            textAlign: TextAlign.center)
                      ,
                      if (_userFen != null && _userFen!.isNotEmpty)
                        Chessboard.fixed(size: 200, orientation: Side.white, fen: _userFen!)
                      ,
                      if (_bestMove != null)
                        Text('Best move: $_bestMove', textAlign: TextAlign.center)      
                      ,
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
