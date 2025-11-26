import 'package:test/test.dart';
import 'package:chess_trainer/model/motif_model.dart';
import 'package:chess_trainer/model/stockfish_data_model.dart';
import 'package:chess_trainer/service/motif_detector_service.dart';

void main() {
  group('MotifDetector', () {
    late EngineAnalysis analysis;
    late MotifDetector detector;

    setUp(() {
      // Example starting position (FEN for standard chess start)
      const startingFen = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';

      // Mock PV lines
      analysis = EngineAnalysis(
        bestMove: 'e2e4',
        ponder: 'e7e5',
        fen: startingFen,
        lines: {
          1: PvLine(
            multipv: 1,
            depth: 20,
            seldepth: 22,
            scoreType: 'cp',
            score: 34,
            pv: ['e2e4', 'e7e5', 'g1f3']
          ),
          2: PvLine(
            multipv: 2,
            depth: 18,
            seldepth: 20,
            scoreType: 'cp',
            score: 20,
            pv: ['d2d4', 'd7d5', 'c1f4']
          ),
        },
      );

      detector = MotifDetector(analysis);
    });

    test('detectMotifs returns correct map structure', () {
      final result = detector.detectMotifs();

      expect(result, isA<Map<int, List<Motif>>>());
      expect(result.length, 2);
      expect(result[1]![0].fen, 'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1');
      expect(result[2]![0].fen, 'rnbqkbnr/pppppppp/8/8/3P4/8/PPP1PPPP/RNBQKBNR b KQkq d3 0 1');
    });

    test('pawn islands and pawn structure are detected correctly', () {
      final result = detector.detectMotifs();
      final motif = result[1]!.first;

      expect(motif.whitePawnIslands, greaterThan(0));
      expect(motif.blackPawnIslands, greaterThan(0));
      expect(motif.whitePawnStructure.containsKey('isolated'), isTrue);
      expect(motif.blackPawnStructure.containsKey('doubled'), isTrue);
    });

    test('endgame type is correct for starting position', () {
      final result = detector.detectMotifs();
      final motif = result[1]!.first;

      // Starting position is definitely "Not endgame"
      expect(motif.endgameType, 'Not endgame');
    });
  });
}
