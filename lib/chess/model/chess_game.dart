import 'package:chess/chess.dart' as ch;

/// Thin, UCI-friendly wrapper over the `chess` package.
/// UCI move format: from+to+optional promotion, e.g. 'e2e4', 'e7e8q'.
class ChessGame {
  final ch.Chess _engine;

  ChessGame() : _engine = ch.Chess();
  ChessGame.fromFen(String fen) : _engine = ch.Chess.fromFEN(fen);

  String get fen => _engine.fen;
  bool get isGameOver => _engine.game_over;
  bool get isCheckmate => _engine.in_checkmate;
  bool get isStalemate => _engine.in_stalemate;
  bool get isDraw => _engine.in_draw;
  bool get isCheck => _engine.in_check;
  bool get isWhiteToMove => _engine.turn == ch.Color.WHITE;

  List<String> legalMoves() {
    // The `chess` package's verbose move map does not expose a `promotion`
    // key, so we request the raw Move objects instead. Each Move carries the
    // from/to squares and an optional promotion PieceType, which we render as
    // the UCI suffix (e.g. 'e7e8q').
    final moves = _engine.moves({'asObjects': true});
    return moves.map<String>((m) {
      final move = m as ch.Move;
      final promo = move.promotion;
      return '${move.fromAlgebraic}${move.toAlgebraic}${promo?.name ?? ''}';
    }).toList();
  }

  /// Returns true if the move was legal and applied.
  bool makeUciMove(String uci) {
    if (!legalMoves().contains(uci)) return false;
    final move = <String, String>{
      'from': uci.substring(0, 2),
      'to': uci.substring(2, 4),
    };
    if (uci.length > 4) move['promotion'] = uci.substring(4, 5);
    _engine.move(move);
    return true;
  }

  /// True if the given square (e.g. 'e2') holds a white piece.
  bool isWhitePieceAt(String square) {
    final piece = _engine.get(square);
    return piece != null && piece.color == ch.Color.WHITE;
  }

  /// True if the square currently holds any piece (used to detect captures
  /// before a move is applied, so a distinct capture sound can play).
  bool isOccupied(String square) => _engine.get(square) != null;

  ChessGame copy() => ChessGame.fromFen(fen);
}
