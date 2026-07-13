/// Strategy interface for a chess opponent.
/// Given a FEN, returns a UCI move string (e.g. 'e2e4').
abstract class ChessAi {
  Future<String> bestMove(String fen);

  /// Free native resources if any. No-op by default.
  void dispose() {}
}
