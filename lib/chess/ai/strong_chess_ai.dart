import 'chess_ai.dart';
import 'random_chess_ai.dart';

/// Web / default build: the native Stockfish engine relies on `dart:ffi`, which
/// is unavailable on the web target (it fails to even compile there). On these
/// platforms the "strong" AI degrades to the pure-Dart random opponent so the
/// app still builds and plays everywhere.
///
/// The native build swaps this out for [strong_chess_ai_native.dart] via a
/// `dart.library.io` conditional import, so `package:stockfish` (and its
/// `dart:ffi` dependency) is never pulled into a web bundle.
ChessAi createStrongChessAi({int skill = 5, int moveTimeMs = 800}) =>
    RandomChessAi();
