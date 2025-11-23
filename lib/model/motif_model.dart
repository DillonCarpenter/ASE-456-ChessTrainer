class Motif {
  final String fen;
  final int whitePawnIslands;
  final int blackPawnIslands;
  final int whiteQueensideMajority;
  final int blackQueensideMajority;
  final Map<String, int> whitePawnStructure;
  final Map<String, int> blackPawnStructure;
  final String endgameType;
  // Add more motifs as needed

  Motif({
    required this.fen,
    required this.whitePawnIslands,
    required this.blackPawnIslands,
    required this.whiteQueensideMajority,
    required this.blackQueensideMajority,
    required this.whitePawnStructure,
    required this.blackPawnStructure,
    required this.endgameType,
  });

  @override
  String toString() {
    return 'Motif(fen: $fen, whitePawnIslands: $whitePawnIslands, blackPawnIslands: $blackPawnIslands, endgameType: $endgameType)';
  }
}
