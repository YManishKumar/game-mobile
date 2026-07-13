import 'chess_ai.dart';
import 'stockfish_chess_ai.dart';

/// Native (Android/iOS/desktop) build: uses the real Stockfish UCI engine.
/// Selected over [strong_chess_ai.dart] by the `dart.library.io` conditional
/// import in the chess controller, keeping `dart:ffi` off the web target.
ChessAi createStrongChessAi({int skill = 5, int moveTimeMs = 800}) =>
    StockfishChessAi(skill: skill, moveTimeMs: moveTimeMs);
