import 'package:flutter/material.dart';
import 'package:dartchess/dartchess.dart'; //FEN to PGN and vise versa
import 'package:chessground/chessground.dart'; //UI
import 'dart:async';
import 'package:chess_trainer/service/stockfish_service.dart'; // gives us Stockfish, StockfishFlavor, StockfishState through abstraction
import 'package:chess_trainer/view/chess_board_widget.dart';

void main() => runApp(const ChessApp());

class ChessApp extends StatefulWidget {
  const ChessApp({super.key});

  @override
  State<ChessApp> createState() => _ChessAppState();
}

class _ChessAppState extends State<ChessApp> {
  //Stockfish? _engine;
  final StockfishHelper _engine = StockfishHelper();
  //bool _engineReady = false;

  final TextEditingController _fenController = TextEditingController();
  final TextEditingController _pgnController = TextEditingController();
  String? _userFen;
  String? _userPgn;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  
  @override
  void initState() {
    super.initState();
    _engine.initialize();
  }
  
  @override
  void dispose() {
    _engine.dispose();
    _fenController.dispose();
    _pgnController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stockfish FEN Demo',
      home: Scaffold(
        appBar: AppBar(title: const Text('Stockfish FEN Input')),
        body: ValueListenableBuilder(valueListenable: _engine.isReady, builder:(context, ready, _) {
          return !ready 
          ? const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Starting Stockfish engine...'),
                ],
            )
          :SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey, // define GlobalKey<FormState> _formKey = GlobalKey<FormState>();
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Enter a FEN or PGN string:',
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _fenController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'FEN',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _pgnController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'PGN',
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        final fen = _fenController.text.trim();
                        final pgn = _pgnController.text.trim();

                        if (fen.isEmpty && pgn.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter either a FEN or PGN.')),
                          );
                          return;
                        }

                        if (fen.isNotEmpty) {
                          if (_engine.isReady.value) {
                            setState(() {
                              _userFen = fen;
                              _userPgn = ''; // clear PGN if FEN entered
                            });
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Engine is not ready yet.')),
                            );
                          }
                        } else if (pgn.isNotEmpty) {
                          setState(() {
                            _userPgn = pgn;
                            _userFen = ''; // clear FEN if PGN entered
                          });
                        }
                      },
                      child: const Text('Submit Position'),
                    ),
                    const SizedBox(height: 20),
                    ChessGUI(stockfish: _engine, fen: _userFen, pgn: _userPgn),
                  ],
                ),
              )
            )
          );
        }) 
      ),
    );
  }
}

