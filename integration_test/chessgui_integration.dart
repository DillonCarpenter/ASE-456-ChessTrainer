import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:chess_trainer/widgets/chess_board_widget.dart';
import 'package:chess_trainer/service/stockfish_service.dart';
import 'package:chessground/chessground.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets("ChessGUI full integration test with real Stockfish", (tester) async {
    final stockfish = StockfishHelper();

    // Wait for engine to be ready
    await stockfish.initialize(); // Assuming StockfishHelper has a start() method
    while (!stockfish.isReady.value) {
      await Future.delayed(const Duration(milliseconds: 300));
    }

    // Sample PGN
    const pgn = "1. e4 e5 2. Nf3 Nc6";

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ChessGUI(
            pgn: pgn,
            stockfish: stockfish,
          ),
        )
      ),
    ));

    // Wait for analysis to complete
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Check Chessboard is displayed
    expect(find.byType(Chessboard), findsOneWidget);

    // Check PV lines are displayed
    expect(find.textContaining("PV"), findsWidgets);

    // Check motif info is displayed
    expect(find.textContaining("Motifs (final position):"), findsWidgets);

    // Test navigation
    final nextButton = find.byIcon(Icons.arrow_forward);
    await tester.tap(nextButton);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    final prevButton = find.byIcon(Icons.arrow_back);
    await tester.tap(prevButton);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // After navigating back, Chessboard should still exist
    expect(find.byType(Chessboard), findsOneWidget);
  });
}
