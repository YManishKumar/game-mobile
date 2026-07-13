import 'package:flutter/painting.dart';

/// Maps chess squares (e.g. 'e4') to pixel offsets inside the marble area of a
/// square board image. The playable 8x8 grid is inset from every edge by
/// [insetFraction] of the image size (the gold frame). White is at the bottom.
class BoardGeometry {
  BoardGeometry({required this.imageSize, required this.insetFraction});

  final double imageSize;
  final double insetFraction;

  double get inset => imageSize * insetFraction;
  double get gridSize => imageSize - inset * 2;
  double get squareSize => gridSize / 8;

  /// Top-left pixel of the given square.
  Offset topLeftOf(String square) {
    final file = square.codeUnitAt(0) - 'a'.codeUnitAt(0); // 0..7 (a..h)
    final rank = int.parse(square[1]); // 1..8
    final x = inset + file * squareSize;
    final y = inset + (8 - rank) * squareSize; // rank 1 at bottom
    return Offset(x, y);
  }

  /// Center pixel of the given square.
  Offset centerOf(String square) {
    final tl = topLeftOf(square);
    return Offset(tl.dx + squareSize / 2, tl.dy + squareSize / 2);
  }
}
