class ChessState {
  const ChessState({
    required this.fen,
    required this.isGameOver,
    required this.isWhiteToMove,
    required this.status,
    this.lastFrom,
    this.lastTo,
    this.thinking = false,
  });

  final String fen;
  final bool isGameOver;
  final bool isWhiteToMove;
  final String status;       // human-readable, e.g. "Your move", "Checkmate — you win"
  final String? lastFrom;    // last move origin square, e.g. 'e2'
  final String? lastTo;      // last move destination square, e.g. 'e4'
  final bool thinking;       // AI is computing

  ChessState copyWith({
    String? fen,
    bool? isGameOver,
    bool? isWhiteToMove,
    String? status,
    String? lastFrom,
    String? lastTo,
    bool? thinking,
  }) {
    return ChessState(
      fen: fen ?? this.fen,
      isGameOver: isGameOver ?? this.isGameOver,
      isWhiteToMove: isWhiteToMove ?? this.isWhiteToMove,
      status: status ?? this.status,
      lastFrom: lastFrom ?? this.lastFrom,
      lastTo: lastTo ?? this.lastTo,
      thinking: thinking ?? this.thinking,
    );
  }
}
