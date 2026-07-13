import 'package:flutter/material.dart';
import 'package:chess/chess.dart' as ch;
import '../../app/theme.dart';
import 'board_geometry.dart';

/// Photoreal board: marble+frame background image, glossy piece sprites over it,
/// tap-to-move, and eased glide on move. `enabled` blocks input while AI thinks.
/// Set [insetFraction] to match the frame thickness of `frame_marble.png`.
class ChessBoard extends StatefulWidget {
  const ChessBoard({
    super.key,
    required this.fen,
    required this.enabled,
    required this.onMove,
    this.lastFrom,
    this.lastTo,
    this.insetFraction = 0.10,
  });

  final String fen;
  final bool enabled;
  final String? lastFrom;
  final String? lastTo;
  final double insetFraction;
  final void Function(String uci) onMove; // 'e2e4'

  @override
  State<ChessBoard> createState() => _ChessBoardState();
}

class _ChessBoardState extends State<ChessBoard> {
  String? _selected;

  static const _assetKeys = {
    'wp': 'wp', 'wn': 'wn', 'wb': 'wb', 'wr': 'wr', 'wq': 'wq', 'wk': 'wk',
    'bp': 'bp', 'bn': 'bn', 'bb': 'bb', 'br': 'br', 'bq': 'bq', 'bk': 'bk',
  };

  String _keyFor(ch.Piece piece) =>
      (piece.color == ch.Color.WHITE ? 'w' : 'b') + piece.type.name;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth;
        final geo = BoardGeometry(
            imageSize: size, insetFraction: widget.insetFraction);
        final engine = ch.Chess.fromFEN(widget.fen);

        final children = <Widget>[
          // Board background (gold frame + marble grid).
          Positioned.fill(
            child: Image.asset('assets/images/board/frame_marble.png',
                fit: BoxFit.fill),
          ),
          // Last-move highlight squares.
          for (final s in [widget.lastFrom, widget.lastTo])
            if (s != null) _highlight(s, geo),
          // Piece sprites — pieces float slightly above their square so the
          // baked-in shadow reads as sitting on the board.
          for (var rank = 1; rank <= 8; rank++)
            for (var file = 0; file < 8; file++)
              ..._maybePiece(engine, file, rank, geo),
          // Selection ring.
          if (_selected != null) _selectionRing(_selected!, geo),
          // Invisible tap layer (64 cells).
          for (var rank = 1; rank <= 8; rank++)
            for (var file = 0; file < 8; file++)
              _tapCell(_square(file, rank), geo),
        ];

        return SizedBox(
          width: size,
          height: size,
          child: Stack(children: children),
        );
      },
    );
  }

  List<Widget> _maybePiece(
      ch.Chess engine, int file, int rank, BoardGeometry geo) {
    final square = _square(file, rank);
    final piece = engine.get(square);
    if (piece == null) return const [];
    final tl = geo.topLeftOf(square);
    final sq = geo.squareSize;
    return [
      AnimatedPositioned(
        key: ValueKey('piece_$square'),
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        left: tl.dx,
        top: tl.dy - sq * 0.28, // lift so the piece "stands" on the square
        width: sq,
        height: sq * 1.4,
        child: IgnorePointer(
          child: Image.asset(
            'assets/images/pieces/${_assetKeys[_keyFor(piece)]}.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    ];
  }

  Widget _highlight(String square, BoardGeometry geo) {
    final tl = geo.topLeftOf(square);
    return Positioned(
      left: tl.dx,
      top: tl.dy,
      width: geo.squareSize,
      height: geo.squareSize,
      child: IgnorePointer(
        child: Container(color: AppTheme.accent.withValues(alpha: 0.30)),
      ),
    );
  }

  Widget _selectionRing(String square, BoardGeometry geo) {
    final tl = geo.topLeftOf(square);
    return Positioned(
      left: tl.dx,
      top: tl.dy,
      width: geo.squareSize,
      height: geo.squareSize,
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.accentGlow, width: 3),
            boxShadow: [
              BoxShadow(
                  color: AppTheme.accentGlow.withValues(alpha: 0.6),
                  blurRadius: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tapCell(String square, BoardGeometry geo) {
    final tl = geo.topLeftOf(square);
    return Positioned(
      left: tl.dx,
      top: tl.dy,
      width: geo.squareSize,
      height: geo.squareSize,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.enabled ? () => _onTapSquare(square) : null,
      ),
    );
  }

  void _onTapSquare(String square) {
    if (_selected == null) {
      setState(() => _selected = square);
      return;
    }
    if (_selected == square) {
      setState(() => _selected = null);
      return;
    }
    var uci = '$_selected$square';
    if (_isPromotion(_selected!, square)) uci += 'q'; // auto-queen in v1
    widget.onMove(uci);
    setState(() => _selected = null);
  }

  bool _isPromotion(String from, String to) {
    final piece = ch.Chess.fromFEN(widget.fen).get(from);
    if (piece == null || piece.type != ch.PieceType.PAWN) return false;
    return to.endsWith('8') || to.endsWith('1');
  }

  String _square(int file, int rank) =>
      '${String.fromCharCode('a'.codeUnitAt(0) + file)}$rank';
}
