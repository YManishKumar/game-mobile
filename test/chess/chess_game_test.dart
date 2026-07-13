import 'package:flutter_test/flutter_test.dart';
import 'package:game_mobile_app/chess/model/chess_game.dart';

void main() {
  test('new game has 20 legal opening moves and white to move', () {
    final game = ChessGame();
    expect(game.isWhiteToMove, isTrue);
    expect(game.isGameOver, isFalse);
    expect(game.legalMoves().length, 20);
    expect(game.legalMoves(), contains('e2e4'));
  });

  test('makeUciMove applies a legal move and rejects an illegal one', () {
    final game = ChessGame();
    expect(game.makeUciMove('e2e4'), isTrue);
    expect(game.isWhiteToMove, isFalse); // black to move now
    expect(game.makeUciMove('e2e5'), isFalse); // no piece there -> illegal
  });

  test('detects fools-mate checkmate', () {
    final game = ChessGame();
    for (final m in ['f2f3', 'e7e5', 'g2g4', 'd8h4']) {
      expect(game.makeUciMove(m), isTrue);
    }
    expect(game.isGameOver, isTrue);
    expect(game.isCheckmate, isTrue);
  });
}
