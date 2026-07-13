import 'dart:async';
import 'package:stockfish/stockfish.dart';
import 'chess_ai.dart';
import 'random_chess_ai.dart';

/// Strong offline AI backed by the Stockfish UCI engine.
/// `skill` maps to Stockfish "Skill Level" (0-20). `moveTimeMs` bounds thinking.
class StockfishChessAi implements ChessAi {
  StockfishChessAi({this.skill = 5, this.moveTimeMs = 800}) {
    _stockfish = Stockfish();
    _readySub = _stockfish.stdout.listen(_onLine);
    _sendWhenReady('setoption name Skill Level value $skill');
  }

  final int skill;
  final int moveTimeMs;
  late final Stockfish _stockfish;
  late final StreamSubscription<String> _readySub;
  Completer<String>? _pending;
  final _fallback = RandomChessAi();

  void _onLine(String line) {
    if (line.startsWith('bestmove')) {
      final parts = line.split(' ');
      if (parts.length >= 2 && _pending != null && !_pending!.isCompleted) {
        _pending!.complete(parts[1]); // e.g. 'e2e4' or 'e7e8q'
      }
    }
  }

  Future<void> _sendWhenReady(String cmd) async {
    // Wait until the engine reports ready before sending options.
    while (_stockfish.state.value != StockfishState.ready) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    _stockfish.stdin = cmd;
  }

  @override
  Future<String> bestMove(String fen) async {
    if (_stockfish.state.value != StockfishState.ready) {
      return _fallback.bestMove(fen); // engine failed to start -> stay playable
    }
    final completer = Completer<String>();
    _pending = completer;
    _stockfish.stdin = 'position fen $fen';
    _stockfish.stdin = 'go movetime $moveTimeMs';
    return completer.future.timeout(
      Duration(milliseconds: moveTimeMs + 1500),
      onTimeout: () => _fallback.bestMove(fen),
    );
  }

  @override
  void dispose() {
    _readySub.cancel();
    _stockfish.dispose();
  }
}
