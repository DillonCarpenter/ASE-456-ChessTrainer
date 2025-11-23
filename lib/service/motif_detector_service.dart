import 'package:chess_trainer/model/stockfish_data_model.dart';
import 'package:chess/chess.dart';
import 'package:chess_trainer/model/motif_model.dart';
class MotifDetector {
  final EngineAnalysis analysis;

  MotifDetector(this.analysis);

  Map<int, List<Motif>> detectMotifs() {
    final fensPerPv = getFensFromAllPvs(analysis);
    final result = <int, List<Motif>>{};

    fensPerPv.forEach((pvIndex, fens) {
      final motifsForPv = <Motif>[];

      for (final fen in fens) {
        final motif = detectMotifsInFen(fen); // returns a Motif object
        motifsForPv.add(motif);
      }

      result[pvIndex] = motifsForPv;
    });

    return result;
  }
  Motif detectMotifsInFen(String fen) {
    final board = parseFEN(fen);

    return Motif(
      fen: fen,
      whitePawnIslands: pawnIslands(board, 'P'),
      blackPawnIslands: pawnIslands(board, 'p'),
      whiteQueensideMajority: pawnMajority(board, 'P', 'queen'),
      blackQueensideMajority: pawnMajority(board, 'p', 'queen'),
      whitePawnStructure: pawnStructure(board, 'P'),
      blackPawnStructure: pawnStructure(board, 'p'),
      endgameType: endgameType(board),
    );
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
  ///Returns a board position that's a 2d array.
  List<List<String>> parseFEN(String fen) {
    List<List<String>> board = [];
    List<String> ranks = fen.split(' ')[0].split('/');
    
    for (var rank in ranks) {
      List<String> row = [];
      for (var char in rank.split('')) {
        if (int.tryParse(char) != null) {
          row.addAll(List.filled(int.parse(char), '')); // empty squares
        } else {
          row.add(char);
        }
      }
      board.add(row);
    }
    
    return board;
  }
  int pawnIslands(List<List<String>> board, String color) {
    List<bool> filesWithPawn = List.filled(8, false);

    // Mark files that contain a pawn of the given color
    for (var rank in board) {
      for (int col = 0; col < 8; col++) {
        if (rank[col] == color) {
          filesWithPawn[col] = true;
        }
      }
    }

    // Count contiguous blocks (pawn islands)
    int islands = 0;
    int i = 0;
    while (i < 8) {
      if (filesWithPawn[i]) {
        islands++;
        while (i < 8 && filesWithPawn[i]) {
          i++;
        }
      } else {
        i++;
      }
    }

    return islands;
  }
  int pawnMajority(List<List<String>> board, String color, String side) {
    int startFile = (side == 'queen') ? 0 : 4;
    int endFile = (side == 'queen') ? 3 : 7;
    
    int count = 0;
    for (var rank in board) {
      for (int file = startFile; file <= endFile; file++) {
        if (rank[file] == color) {
          count++;
        }
      }
    }
    return count;
  }
  Map<String, int> pawnStructure(List<List<String>> board, String color) {
    // Step 1: Count pawns per file
    List<int> pawnsPerFile = List.filled(8, 0);
    for (var rank in board) {
      for (int file = 0; file < 8; file++) {
        if (rank[file] == color) pawnsPerFile[file]++;
      }
    }

    int isolated = 0;
    int doubled = 0;
    int tripled = 0;

    for (int file = 0; file < 8; file++) {
      int count = pawnsPerFile[file];

      // Doubled/tripled
      if (count == 2) doubled += 2;
      if (count >= 3) tripled += count;

      // Isolated: no pawns on adjacent files
      bool leftEmpty = (file == 0) || (pawnsPerFile[file - 1] == 0);
      bool rightEmpty = (file == 7) || (pawnsPerFile[file + 1] == 0);
      if (count > 0 && leftEmpty && rightEmpty) {
        isolated += count;
      }
    }

    return {
      'isolated': isolated,
      'doubled': doubled,
      'tripled': tripled,
    };
  }
  bool isBackwardPawn(List<List<String>> board, int rank, int file, String color) {
    if (board[rank][file] != color) return false;

    int direction = (color == 'P') ? -1 : 1; // white moves up, black moves down
    String enemy = (color == 'P') ? 'p' : 'P';
    
    // 1. Check if pawn is isolated
    bool hasNeighbor = false;
    if (file > 0) {
      for (var r = 0; r < 8; r++) {
        if (board[r][file - 1] == color) hasNeighbor = true;
      }
    }
    if (file < 7) {
      for (var r = 0; r < 8; r++) {
        if (board[r][file + 1] == color) hasNeighbor = true;
      }
    }
    if (!hasNeighbor) return false; // isolated pawns are not backward

    // 2. Check if square in front is controlled by enemy pawn
    int frontRank = rank + direction;
    if (frontRank < 0 || frontRank > 7) return false; // pawn at edge cannot be backward
    bool controlled = false;
    if (file > 0 && board[frontRank][file - 1] == enemy) controlled = true;
    if (file < 7 && board[frontRank][file + 1] == enemy) controlled = true;
    if (!controlled) return false;

    // 3. Check if adjacent friendly pawns are further advanced
    bool neighborAdvanced = false;
    if (file > 0) {
      for (var r = 0; r < 8; r++) {
        if (board[r][file - 1] == color) {
          if ((color == 'P' && r < rank) || (color == 'p' && r > rank)) {
            neighborAdvanced = true;
          }
        }
      }
    }
    if (file < 7) {
      for (var r = 0; r < 8; r++) {
        if (board[r][file + 1] == color) {
          if ((color == 'P' && r < rank) || (color == 'p' && r > rank)) {
            neighborAdvanced = true;
          }
        }
      }
    }
    return neighborAdvanced;
  }
  String endgameType(List<List<String>> board) {
    // Piece counts per side
    int whiteMajor = 0;
    int blackMajor = 0;
    int whiteMinor = 0;
    int blackMinor = 0;
    int whitePawns = 0;
    int blackPawns = 0;

    int whiteBishops = 0;
    int blackBishops = 0;
    int whiteKnights = 0;
    int blackKnights = 0;

    for (var rank in board) {
      for (var piece in rank) {
        switch (piece) {
          case 'Q':
            whiteMajor++;
            break;
          case 'R':
            whiteMajor++;
            break;
          case 'B':
            whiteMinor++;
            whiteBishops++;
            break;
          case 'N':
            whiteMinor++;
            whiteKnights++;
            break;
          case 'P':
            whitePawns++;
            break;
          case 'q':
            blackMajor++;
            break;
          case 'r':
            blackMajor++;
            break;
          case 'b':
            blackMinor++;
            blackBishops++;
            break;
          case 'n':
            blackMinor++;
            blackKnights++;
            break;
          case 'p':
            blackPawns++;
            break;
        }
      }
    }

    // Criterion 1: each side has at most 1 major or 2 minor pieces
    bool whiteOk = (whiteMajor <= 1 && whiteMinor <= 2);
    bool blackOk = (blackMajor <= 1 && blackMinor <= 2);
    if (!(whiteOk && blackOk)) return "Not endgame";

    // Criterion 2: if both sides only have at most 1 minor piece and 0 major pieces
    if (whiteMajor == 0 && blackMajor == 0 &&
        whiteMinor <= 1 && blackMinor <= 1) {
      // There must be at least 1 pawn on the board
      if (whitePawns + blackPawns == 0) return "Not endgame";
    }

    // Determine type of endgame
    // 1. King + pawn endgame
    if (whiteMajor == 0 && blackMajor == 0 &&
        whiteMinor == 0 && blackMinor == 0) {
      return "King + pawns endgame";
    }

    // 2. Minor piece endgames
    if (whiteMajor == 0 && blackMajor == 0) {
      if (whiteMinor == 1 && blackMinor == 1) {
        String whitePiece = whiteBishops == 1 ? "Bishop" : "Knight";
        String blackPiece = blackBishops == 1 ? "Bishop" : "Knight";
        return "$whitePiece vs $blackPiece endgame";
      }
      if (whiteMinor == 2 && blackMinor <= 2) {
        return "Two minor pieces vs minor pieces endgame";
      }
      if (whiteMinor == 1 && blackMinor <= 2) {
        return "Minor piece vs minor pieces endgame";
      }
    }

    // 3. Major piece endgames
    if (whiteMajor == 1 || blackMajor == 1) {
      return "Major piece endgame";
    }

    // Default fallback
    return "Endgame";
  }
}