import 'package:flutter_riverpod/legacy.dart';
import '../ai/chess_ai.dart';
import '../ai/stockfish_chess_ai.dart';
import '../model/chess_game.dart';
import '../model/chess_state.dart';

class ChessController extends StateNotifier<ChessState> {
  ChessController(this._ai)
      : _game = ChessGame(),
        super(const ChessState(
          fen: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
          isGameOver: false,
          isWhiteToMove: true,
          status: 'Your move',
        )) {
    _sync();
  }

  final ChessAi _ai;
  ChessGame _game;

  /// Human plays white. Applies the move, then lets the AI (black) reply.
  Future<void> playHumanMove(String uci) async {
    if (_game.isGameOver || !state.isWhiteToMove) return;
    if (!_game.makeUciMove(uci)) return; // ignore illegal taps
    _sync(from: uci.substring(0, 2), to: uci.substring(2, 4));
    if (_game.isGameOver) return;

    state = state.copyWith(thinking: true, status: 'AI thinking…');
    final aiMove = await _ai.bestMove(_game.fen);
    _game.makeUciMove(aiMove);
    _sync(from: aiMove.substring(0, 2), to: aiMove.substring(2, 4));
    state = state.copyWith(thinking: false);
  }

  void newGame() {
    _game = ChessGame();
    state = const ChessState(
      fen: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
      isGameOver: false,
      isWhiteToMove: true,
      status: 'Your move',
    );
    _sync();
  }

  void _sync({String? from, String? to}) {
    state = state.copyWith(
      fen: _game.fen,
      isGameOver: _game.isGameOver,
      isWhiteToMove: _game.isWhiteToMove,
      status: _statusText(),
      lastFrom: from ?? state.lastFrom,
      lastTo: to ?? state.lastTo,
    );
  }

  String _statusText() {
    if (_game.isCheckmate) {
      // The side to move is the loser.
      return _game.isWhiteToMove ? 'Checkmate — AI wins' : 'Checkmate — you win';
    }
    if (_game.isStalemate) return 'Stalemate — draw';
    if (_game.isDraw) return 'Draw';
    if (_game.isCheck) return _game.isWhiteToMove ? 'You are in check' : 'AI in check';
    return _game.isWhiteToMove ? 'Your move' : 'AI move';
  }

  @override
  void dispose() {
    _ai.dispose();
    super.dispose();
  }
}

/// App wiring: real games use Stockfish. Tests construct ChessController
/// directly with RandomChessAi, so this provider is UI-only.
final chessControllerProvider =
    StateNotifierProvider.autoDispose<ChessController, ChessState>((ref) {
  final ai = StockfishChessAi(skill: 5, moveTimeMs: 800);
  ref.onDispose(ai.dispose);
  return ChessController(ai);
});
