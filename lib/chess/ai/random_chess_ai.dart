import 'dart:math';
import '../model/chess_game.dart';
import 'chess_ai.dart';

/// Picks a uniformly random legal move. Pure Dart — used in tests and as an
/// offline fallback when Stockfish is unavailable.
class RandomChessAi implements ChessAi {
  RandomChessAi([Random? random]) : _random = random ?? Random();
  final Random _random;

  @override
  Future<String> bestMove(String fen) async {
    final moves = ChessGame.fromFen(fen).legalMoves();
    return moves[_random.nextInt(moves.length)];
  }

  @override
  void dispose() {}
}
