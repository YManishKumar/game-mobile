import 'package:flutter_test/flutter_test.dart';
import 'package:game_mobile_app/chess/ui/board_geometry.dart';

void main() {
  // 800px image, playable area inset 10% on each side -> 640px grid, 80px/square.
  final geo = BoardGeometry(imageSize: 800, insetFraction: 0.10);

  test('a1 maps to bottom-left square top-left corner', () {
    // file a = 0, rank 1 = bottom row. inset = 80px. square = 80px.
    // rank 1 top edge is at inset + 7*square = 80 + 560 = 640.
    expect(geo.topLeftOf('a1'), const Offset(80, 640));
  });

  test('h8 maps to top-right square top-left corner', () {
    // file h = 7 -> x = 80 + 7*80 = 640. rank 8 top row -> y = inset = 80.
    expect(geo.topLeftOf('h8'), const Offset(640, 80));
  });

  test('square size derives from inset', () {
    expect(geo.squareSize, 80);
  });

  test('centerOf a1 is square center', () {
    expect(geo.centerOf('a1'), const Offset(120, 680));
  });
}
