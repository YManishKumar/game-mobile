import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_mobile_app/chess/ai/random_chess_ai.dart';
import 'package:game_mobile_app/chess/controller/chess_controller.dart';

void main() {
  test('human move triggers a legal AI reply and returns turn to white',
      () async {
    final controller = ChessController(RandomChessAi(Random(1)));

    expect(controller.state.isWhiteToMove, isTrue);

    await controller.playHumanMove('e2e4');

    // After the human move AND the AI reply, it is white to move again.
    expect(controller.state.isWhiteToMove, isTrue);
    expect(controller.state.isGameOver, isFalse);
    // The AI's move is recorded as the last move.
    expect(controller.state.lastFrom, isNotNull);
    expect(controller.state.lastTo, isNotNull);
    expect(controller.state.thinking, isFalse);
  });

  test('rejects an illegal human move without changing turn', () async {
    final controller = ChessController(RandomChessAi(Random(1)));
    await controller.playHumanMove('e2e5'); // illegal
    expect(controller.state.isWhiteToMove, isTrue);
    expect(controller.state.lastFrom, isNull);
  });
}
