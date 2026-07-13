import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_mobile_app/chess/model/chess_game.dart';
import 'package:game_mobile_app/chess/ai/random_chess_ai.dart';

void main() {
  test('random AI returns a legal move for the opening position', () async {
    final game = ChessGame();
    final ai = RandomChessAi(Random(42)); // seeded -> deterministic
    final move = await ai.bestMove(game.fen);
    expect(game.legalMoves(), contains(move));
  });
}
