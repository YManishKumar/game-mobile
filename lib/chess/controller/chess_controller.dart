import 'package:flutter_riverpod/legacy.dart';
import '../ai/chess_ai.dart';
// Platform-aware AI factory: the native build (dart:library.io) uses Stockfish;
// the web/default build falls back to a pure-Dart AI so `dart:ffi` never enters
// the web bundle. This must be a compile-time switch — a runtime `kIsWeb` guard
// cannot help because `package:stockfish` fails to compile for web at all.
import '../ai/strong_chess_ai.dart'
    if (dart.library.io) '../ai/strong_chess_ai_native.dart';
import '../model/chess_game.dart';
import '../model/chess_state.dart';
import '../../shared/services/feedback_service.dart';
import '../../shared/services/storage_service.dart';

class ChessController extends StateNotifier<ChessState> {
  ChessController(this._ai, {FeedbackService? feedback, StorageService? storage})
      : _feedback = feedback ?? FeedbackService(),
        _storage = storage,
        _game = _restore(storage),
        super(const ChessState(
          fen: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
          isGameOver: false,
          isWhiteToMove: true,
          status: 'Your move',
        )) {
    // When a saved FEN was restored, this immediately overwrites the fresh
    // initial state above with the persisted position.
    _sync();
  }

  final ChessAi _ai;
  final FeedbackService _feedback;
  final StorageService? _storage;
  ChessGame _game;

  static ChessGame _restore(StorageService? storage) {
    final fen = storage?.loadChessFen();
    if (fen == null) return ChessGame();
    return ChessGame.fromFen(fen);
  }

  /// Human plays white. Applies the move, then lets the AI (black) reply.
  Future<void> playHumanMove(String uci) async {
    if (_game.isGameOver || !state.isWhiteToMove) return;
    final humanCaptures = _game.isOccupied(uci.substring(2, 4));
    if (!_game.makeUciMove(uci)) return; // ignore illegal taps
    _feedback.impact();
    _feedback.play(humanCaptures ? GameSound.capture : GameSound.move);
    _sync(from: uci.substring(0, 2), to: uci.substring(2, 4));
    if (_game.isGameOver) {
      _feedback.play(GameSound.win);
      return;
    }

    state = state.copyWith(thinking: true, status: 'AI thinking…');
    final aiMove = await _ai.bestMove(_game.fen);
    final aiCaptures = _game.isOccupied(aiMove.substring(2, 4));
    _game.makeUciMove(aiMove);
    _feedback.play(aiCaptures ? GameSound.capture : GameSound.move);
    _sync(from: aiMove.substring(0, 2), to: aiMove.substring(2, 4));
    state = state.copyWith(thinking: false);
    if (_game.isGameOver) _feedback.play(GameSound.win);
  }

  void newGame() {
    _game = ChessGame();
    _storage?.clearChessFen();
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
    _storage?.saveChessFen(_game.fen);
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
    _feedback.dispose();
    super.dispose();
  }
}

/// App wiring: real games use Stockfish. Tests construct ChessController
/// directly with RandomChessAi, so this provider is UI-only.
final chessControllerProvider =
    StateNotifierProvider.autoDispose<ChessController, ChessState>((ref) {
  final ChessAi ai = createStrongChessAi(skill: 5, moveTimeMs: 800);
  ref.onDispose(ai.dispose);
  return ChessController(ai, storage: ref.watch(storageProvider));
});
