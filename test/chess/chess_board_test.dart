import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_mobile_app/chess/ui/chess_board.dart';

void main() {
  // Board size 400, insetFraction 0.10 -> inset 40, grid 320, square 40.
  // Square center = inset + index*40 + 20, rank measured from bottom.
  Offset center(String square) {
    final file = square.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final rank = int.parse(square[1]);
    final x = 40 + file * 40 + 20;
    final y = 40 + (8 - rank) * 40 + 20;
    return Offset(x.toDouble(), y.toDouble());
  }

  testWidgets('tapping source then destination emits the correct UCI move',
      (tester) async {
    String? emitted;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 400,
              height: 400,
              child: ChessBoard(
                fen: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
                enabled: true,
                onMove: (uci) => emitted = uci,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tapAt(center('e2')); // select pawn
    await tester.pump();
    await tester.tapAt(center('e4')); // move destination
    await tester.pump();

    expect(emitted, 'e2e4');
  });

  testWidgets('disabled board ignores taps', (tester) async {
    String? emitted;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 400,
              height: 400,
              child: ChessBoard(
                fen: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
                enabled: false,
                onMove: (uci) => emitted = uci,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tapAt(center('e2'));
    await tester.pump();
    await tester.tapAt(center('e4'));
    await tester.pump();

    expect(emitted, isNull);
  });
}
