# Foundation + Chess Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship a polished, offline Flutter app with an animated home menu and a fully playable Chess game against an on-device AI, ready for a Play Store release build.

**Architecture:** Single Flutter app. A shared layer (theme, sound/haptics, animated widgets, persistence) is consumed by an animated home menu and a self-contained Chess module. Chess logic is pure Dart (the `chess` package) behind a `ChessGame` wrapper; the AI sits behind a `ChessAi` interface with a pure-Dart `RandomChessAi` (testable, offline fallback) and a `StockfishChessAi` (strong, native). Riverpod holds game state. The board UI is **photoreal, image-based** — a marble board texture inside a gold ornate frame, with pre-rendered glossy piece sprites (PNG) composited in perspective (fixed camera angle) with drop shadows and a subtle floor reflection, matching the user's reference image. Pieces glide on move. (True live 3D rotation is out of scope for v1; the fixed-angle composite reproduces the reference look while staying smooth and free.)

**Tech Stack:** Flutter, Dart, `flutter_riverpod`, `chess`, `stockfish`, `flutter_animate`, `audioplayers`, `shared_preferences`, `google_fonts`, `flutter_test`.

**Scope:** This plan covers Slice 0 (Foundation) and Slice 1 (Chess) from the design spec. Dugna (Dominoes) is a **separate plan** written after this one ships.

---

## File Structure

```
lib/
├── main.dart                         # App entry: ProviderScope + MaterialApp + routes
├── app/
│   ├── theme.dart                    # Design tokens: colors, gradients, text, spacing
│   └── router.dart                   # Route names + onGenerateRoute
├── shared/
│   ├── services/
│   │   ├── feedback_service.dart     # Sound + haptic wrapper
│   │   └── storage_service.dart      # shared_preferences wrapper
│   └── widgets/
│       └── game_card.dart            # Animated menu card (parallax/tilt)
├── home/
│   └── home_screen.dart              # Animated menu -> game routes
└── chess/
    ├── model/
    │   ├── chess_game.dart           # Wrapper over `chess` package (pure Dart)
    │   └── chess_state.dart          # Immutable UI state
    ├── ai/
    │   ├── chess_ai.dart             # ChessAi interface
    │   ├── random_chess_ai.dart      # Pure-Dart legal-move AI (testable/fallback)
    │   └── stockfish_chess_ai.dart   # UCI engine AI (native, strong)
    ├── controller/
    │   └── chess_controller.dart     # StateNotifier + providers
    └── ui/
        ├── chess_screen.dart         # Screen scaffold + status + game-over overlay
        ├── chess_board.dart          # Photoreal board frame + marble + animated piece sprites
        └── board_geometry.dart       # square <-> pixel mapping inside the marble area

test/
├── chess/
│   ├── chess_game_test.dart
│   ├── random_chess_ai_test.dart
│   ├── board_geometry_test.dart
│   └── chess_controller_test.dart
├── shared/
│   └── storage_service_test.dart
└── home/
    └── home_screen_test.dart

assets/
├── sounds/                           # move.mp3, capture.mp3, win.mp3
└── images/
    ├── board/                        # frame_marble.png (gold frame + marble squares, one image)
    └── pieces/                       # wp.png wn.png wb.png wr.png wq.png wk.png + b* (12 total)
```

Split rationale: logic (`model`, `ai`, `controller`) is pure Dart and unit-tested in isolation; UI (`ui`) is verified on device. The `ChessAi` interface lets tests use the deterministic `RandomChessAi` while the app uses Stockfish — neither knows about the other. `board_geometry.dart` is pure math (square ↔ pixel), so it is unit-tested even though the rest of the board UI is visual.

---

## Slice 0 — Foundation

### Task 1: Install Flutter SDK

**Files:** none (environment setup)

- [ ] **Step 1: Install Flutter via the official archive (macOS)**

```bash
# Install once. If Homebrew is present, `brew install --cask flutter` also works.
cd ~/development 2>/dev/null || (mkdir -p ~/development && cd ~/development)
FLUTTER_VERSION=stable
git clone https://github.com/flutter/flutter.git -b stable ~/development/flutter
echo 'export PATH="$PATH:$HOME/development/flutter/bin"' >> ~/.zshrc
export PATH="$PATH:$HOME/development/flutter/bin"
```

- [ ] **Step 2: Verify the toolchain**

Run: `flutter doctor -v`
Expected: Flutter shows a version; at least one target (Android toolchain / Chrome) is checked. Android Studio + an Android SDK are required for a Play Store build; note any `[✗]` lines to resolve before Task 26. Chrome alone is enough to run/verify earlier tasks.

- [ ] **Step 3: Confirm Dart is available**

Run: `flutter --version && dart --version`
Expected: both print versions with no error.

---

### Task 2: Scaffold the project and add dependencies

**Files:**
- Create: whole Flutter project in repo root
- Modify: `pubspec.yaml`

- [ ] **Step 1: Create the Flutter project in place**

The repo root already has `docs/` and `.git`. Scaffold into a temp dir and move the app files in so git history is preserved.

```bash
cd "/Users/manishkumar/projects/untitled folder/game-mobile-app"
flutter create --org ai.livsyt --project-name game_mobile_app --platforms=android,ios .
```

Expected: `flutter create` reports "All done!" and creates `lib/`, `android/`, `ios/`, `pubspec.yaml`, `test/`.

- [ ] **Step 2: Add runtime and dev dependencies**

Run:
```bash
flutter pub add flutter_riverpod chess stockfish flutter_animate audioplayers shared_preferences google_fonts
```

- [ ] **Step 3: Declare asset folders in `pubspec.yaml`**

Add under the existing `flutter:` key (keep the existing `uses-material-design: true`):

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/sounds/
    - assets/images/pieces/
```

Create the folders so the build does not fail on empty globs:
```bash
mkdir -p assets/sounds assets/images/pieces
touch assets/sounds/.gitkeep assets/images/pieces/.gitkeep
```

- [ ] **Step 4: Fetch packages and confirm the project builds**

Run: `flutter pub get && flutter analyze`
Expected: `pub get` succeeds; `flutter analyze` prints "No issues found!" (the default scaffold is clean).

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "chore: scaffold Flutter project and add dependencies"
```

---

### Task 3: Design tokens (theme)

**Files:**
- Create: `lib/app/theme.dart`

- [ ] **Step 1: Write the theme (no test — pure config, verified by use)**

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central design tokens for the premium dark theme.
class AppTheme {
  // Palette
  static const Color bg = Color(0xFF0B0F1A);
  static const Color surface = Color(0xFF141B2E);
  static const Color surfaceGlass = Color(0x33FFFFFF);
  static const Color accent = Color(0xFF6C8CFF);
  static const Color accentGlow = Color(0xFF9AB0FF);
  static const Color feltGreen = Color(0xFF1E7A52);
  static const Color textPrimary = Color(0xFFF2F5FF);
  static const Color textMuted = Color(0xFF98A2C0);

  // Board colors (used by chess)
  static const Color boardLight = Color(0xFFE9E2D0);
  static const Color boardDark = Color(0xFF6E4A2E);

  static const LinearGradient bgGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0B0F1A), Color(0xFF1A2138)],
  );

  static const double radius = 20.0;
  static const double gap = 16.0;

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: bg,
      colorScheme: base.colorScheme.copyWith(
        primary: accent,
        surface: surface,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
    );
  }
}
```

- [ ] **Step 2: Verify it compiles**

Run: `flutter analyze lib/app/theme.dart`
Expected: "No issues found!"

- [ ] **Step 3: Commit**

```bash
git add lib/app/theme.dart
git commit -m "feat: add premium dark theme tokens"
```

---

### Task 4: Router and app entry

**Files:**
- Create: `lib/app/router.dart`
- Modify: `lib/main.dart` (replace scaffold contents)

- [ ] **Step 1: Write the router**

```dart
import 'package:flutter/material.dart';
import '../home/home_screen.dart';

class Routes {
  static const home = '/';
  static const chess = '/chess';
}

Route<dynamic> onGenerateRoute(RouteSettings settings) {
  switch (settings.name) {
    case Routes.home:
      return _fade(const HomeScreen());
    case Routes.chess:
      // Chess screen is wired in Task 11; placeholder until then.
      return _fade(const Scaffold(body: Center(child: Text('Chess'))));
    default:
      return _fade(const HomeScreen());
  }
}

PageRouteBuilder _fade(Widget child) => PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 450),
      pageBuilder: (_, __, ___) => child,
      transitionsBuilder: (_, anim, __, c) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
        child: c,
      ),
    );
```

- [ ] **Step 2: Replace `lib/main.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/router.dart';
import 'app/theme.dart';

void main() {
  runApp(const ProviderScope(child: GameApp()));
}

class GameApp extends StatelessWidget {
  const GameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Board Games',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      initialRoute: Routes.home,
      onGenerateRoute: onGenerateRoute,
    );
  }
}
```

- [ ] **Step 3: Verify it compiles**

Run: `flutter analyze`
Expected: "No issues found!" (references `HomeScreen`, created next task — so run this after Task 5. If run now it will error on the missing import; that is expected until Task 5.)

- [ ] **Step 4: Commit**

```bash
git add lib/main.dart lib/app/router.dart
git commit -m "feat: add app entry and fade router"
```

---

### Task 5: Animated home menu

**Files:**
- Create: `lib/shared/widgets/game_card.dart`
- Create: `lib/home/home_screen.dart`
- Test: `test/home/home_screen_test.dart`

- [ ] **Step 1: Write the failing widget test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_mobile_app/home/home_screen.dart';

void main() {
  testWidgets('home screen shows both game cards', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pump(const Duration(seconds: 1)); // let intro animations settle

    expect(find.text('Chess'), findsOneWidget);
    expect(find.text('Dugna'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run it to confirm it fails**

Run: `flutter test test/home/home_screen_test.dart`
Expected: FAIL — `HomeScreen` not defined / import error.

- [ ] **Step 3: Write the game card widget**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app/theme.dart';

class GameCard extends StatefulWidget {
  const GameCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.enabled = true,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  @override
  State<GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<GameCard> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.96),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: widget.enabled ? widget.onTap : null,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        child: Container(
          height: 140,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radius),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.surface, Color(0xFF1D2740)],
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.accent.withOpacity(widget.enabled ? 0.25 : 0.0),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(color: AppTheme.surfaceGlass),
          ),
          padding: const EdgeInsets.all(AppTheme.gap),
          child: Row(
            children: [
              Icon(widget.icon, size: 56, color: AppTheme.accentGlow),
              const SizedBox(width: AppTheme.gap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(widget.title,
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 4),
                    Text(widget.subtitle,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppTheme.textMuted)),
                    if (!widget.enabled)
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Text('Coming soon',
                            style: TextStyle(color: AppTheme.textMuted)),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2, curve: Curves.easeOutCubic),
    );
  }
}
```

- [ ] **Step 4: Write the home screen**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../app/router.dart';
import '../app/theme.dart';
import '../shared/widgets/game_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Text('Board Games',
                        style: Theme.of(context).textTheme.displaySmall)
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .slideX(begin: -0.15, curve: Curves.easeOutCubic),
                const SizedBox(height: 6),
                Text('Play offline. Beat the AI.',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: AppTheme.textMuted)),
                const SizedBox(height: 40),
                GameCard(
                  title: 'Chess',
                  subtitle: 'Classic strategy vs AI',
                  icon: Icons.grid_view_rounded,
                  onTap: () => Navigator.of(context).pushNamed(Routes.chess),
                ),
                const SizedBox(height: AppTheme.gap),
                GameCard(
                  title: 'Dugna',
                  subtitle: 'Dominoes vs AI',
                  icon: Icons.casino_rounded,
                  enabled: false, // wired in the Dugna plan
                  onTap: () {},
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Run the test to confirm it passes**

Run: `flutter test test/home/home_screen_test.dart`
Expected: PASS (both cards found).

- [ ] **Step 6: Run the app once to eyeball the animation (manual)**

Run: `flutter run -d chrome` (or an Android emulator)
Expected: menu fades/slides in; cards scale on tap; "Chess" navigates to the placeholder; "Dugna" is disabled.

- [ ] **Step 7: Commit**

```bash
git add lib/home/ lib/shared/widgets/game_card.dart test/home/
git commit -m "feat: animated home menu with game cards"
```

---

## Slice 1 — Chess

### Task 6: ChessGame wrapper

**Files:**
- Create: `lib/chess/model/chess_game.dart`
- Test: `test/chess/chess_game_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:game_mobile_app/chess/model/chess_game.dart';

void main() {
  test('new game has 20 legal opening moves and white to move', () {
    final game = ChessGame();
    expect(game.isWhiteToMove, isTrue);
    expect(game.isGameOver, isFalse);
    expect(game.legalMoves().length, 20);
    expect(game.legalMoves(), contains('e2e4'));
  });

  test('makeUciMove applies a legal move and rejects an illegal one', () {
    final game = ChessGame();
    expect(game.makeUciMove('e2e4'), isTrue);
    expect(game.isWhiteToMove, isFalse); // black to move now
    expect(game.makeUciMove('e2e5'), isFalse); // no piece there -> illegal
  });

  test('detects fools-mate checkmate', () {
    final game = ChessGame();
    for (final m in ['f2f3', 'e7e5', 'g2g4', 'd8h4']) {
      expect(game.makeUciMove(m), isTrue);
    }
    expect(game.isGameOver, isTrue);
    expect(game.isCheckmate, isTrue);
  });
}
```

- [ ] **Step 2: Run it to confirm it fails**

Run: `flutter test test/chess/chess_game_test.dart`
Expected: FAIL — `ChessGame` not defined.

- [ ] **Step 3: Write the wrapper**

```dart
import 'package:chess/chess.dart' as ch;

/// Thin, UCI-friendly wrapper over the `chess` package.
/// UCI move format: from+to+optional promotion, e.g. 'e2e4', 'e7e8q'.
class ChessGame {
  ch.Chess _engine;

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
    final moves = _engine.moves({'verbose': true}) as List;
    return moves.map<String>((m) {
      final map = m as Map;
      final promo = map['promotion'];
      return '${map['from']}${map['to']}${promo ?? ''}';
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
```

- [ ] **Step 4: Run the test to confirm it passes**

Run: `flutter test test/chess/chess_game_test.dart`
Expected: PASS (all 3 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/chess/model/chess_game.dart test/chess/chess_game_test.dart
git commit -m "feat: add ChessGame wrapper over chess package"
```

---

### Task 7: ChessAi interface + RandomChessAi

**Files:**
- Create: `lib/chess/ai/chess_ai.dart`
- Create: `lib/chess/ai/random_chess_ai.dart`
- Test: `test/chess/random_chess_ai_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_mobile_app/chess/model/chess_game.dart';
import 'package:game_mobile_app/chess/ai/random_chess_ai.dart';

void main() {
  test('random AI returns a legal move for the opening position', () async {
    final game = ChessGame();
    final ai = RandomChessAi(Random(42)); // seeded -> deterministic
    final move = await ai.bestMove(game.fen);
    expect(game.legalMoves(), contains(move));
  });
}
```

- [ ] **Step 2: Run it to confirm it fails**

Run: `flutter test test/chess/random_chess_ai_test.dart`
Expected: FAIL — `RandomChessAi` not defined.

- [ ] **Step 3: Write the interface**

`lib/chess/ai/chess_ai.dart`:
```dart
/// Strategy interface for a chess opponent.
/// Given a FEN, returns a UCI move string (e.g. 'e2e4').
abstract class ChessAi {
  Future<String> bestMove(String fen);

  /// Free native resources if any. No-op by default.
  void dispose() {}
}
```

- [ ] **Step 4: Write RandomChessAi**

`lib/chess/ai/random_chess_ai.dart`:
```dart
import 'dart:math';
import '../model/chess_game.dart';
import 'chess_ai.dart';

/// Picks a uniformly random legal move. Pure Dart — used in tests and as an
/// offline fallback when Stockfish is unavailable.
class RandomChessAi implements ChessAi {
  RandomChessAi([Random? random]) : _random = random ?? Random();
  final Random _random;

  @override
  Future<String> bestMove(String fen) async {
    final moves = ChessGame.fromFen(fen).legalMoves();
    return moves[_random.nextInt(moves.length)];
  }

  @override
  void dispose() {}
}
```

- [ ] **Step 5: Run the test to confirm it passes**

Run: `flutter test test/chess/random_chess_ai_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/chess/ai/chess_ai.dart lib/chess/ai/random_chess_ai.dart test/chess/random_chess_ai_test.dart
git commit -m "feat: add ChessAi interface and random fallback AI"
```

---

### Task 8: StockfishChessAi (native engine)

**Files:**
- Create: `lib/chess/ai/stockfish_chess_ai.dart`

Not unit-tested — requires the native binary; verified during the manual run in Task 11. It implements the same `ChessAi` interface, so all logic tests keep using `RandomChessAi`.

- [ ] **Step 1: Write the Stockfish AI**

```dart
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
```

- [ ] **Step 2: Verify it compiles**

Run: `flutter analyze lib/chess/ai/stockfish_chess_ai.dart`
Expected: "No issues found!"

- [ ] **Step 3: Commit**

```bash
git add lib/chess/ai/stockfish_chess_ai.dart
git commit -m "feat: add Stockfish-backed chess AI with random fallback"
```

---

### Task 9: Chess state + controller (Riverpod)

**Files:**
- Create: `lib/chess/model/chess_state.dart`
- Create: `lib/chess/controller/chess_controller.dart`
- Test: `test/chess/chess_controller_test.dart`

- [ ] **Step 1: Write the immutable state**

`lib/chess/model/chess_state.dart`:
```dart
class ChessState {
  const ChessState({
    required this.fen,
    required this.isGameOver,
    required this.isWhiteToMove,
    required this.status,
    this.lastFrom,
    this.lastTo,
    this.thinking = false,
  });

  final String fen;
  final bool isGameOver;
  final bool isWhiteToMove;
  final String status;       // human-readable, e.g. "Your move", "Checkmate — you win"
  final String? lastFrom;    // last move origin square, e.g. 'e2'
  final String? lastTo;      // last move destination square, e.g. 'e4'
  final bool thinking;       // AI is computing

  ChessState copyWith({
    String? fen,
    bool? isGameOver,
    bool? isWhiteToMove,
    String? status,
    String? lastFrom,
    String? lastTo,
    bool? thinking,
  }) {
    return ChessState(
      fen: fen ?? this.fen,
      isGameOver: isGameOver ?? this.isGameOver,
      isWhiteToMove: isWhiteToMove ?? this.isWhiteToMove,
      status: status ?? this.status,
      lastFrom: lastFrom ?? this.lastFrom,
      lastTo: lastTo ?? this.lastTo,
      thinking: thinking ?? this.thinking,
    );
  }
}
```

- [ ] **Step 2: Write the failing controller test**

`test/chess/chess_controller_test.dart`:
```dart
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_mobile_app/chess/ai/random_chess_ai.dart';
import 'package:game_mobile_app/chess/controller/chess_controller.dart';

void main() {
  test('human move triggers a legal AI reply and returns turn to white',
      () async {
    final controller = ChessController(RandomChessAi(Random(1)));

    expect(controller.state.isWhiteToMove, isTrue);

    await controller.playHumanMove('e2e4');

    // After the human move AND the AI reply, it is white to move again.
    expect(controller.state.isWhiteToMove, isTrue);
    expect(controller.state.isGameOver, isFalse);
    // The AI's move is recorded as the last move.
    expect(controller.state.lastFrom, isNotNull);
    expect(controller.state.lastTo, isNotNull);
    expect(controller.state.thinking, isFalse);
  });

  test('rejects an illegal human move without changing turn', () async {
    final controller = ChessController(RandomChessAi(Random(1)));
    await controller.playHumanMove('e2e5'); // illegal
    expect(controller.state.isWhiteToMove, isTrue);
    expect(controller.state.lastFrom, isNull);
  });
}
```

- [ ] **Step 3: Run it to confirm it fails**

Run: `flutter test test/chess/chess_controller_test.dart`
Expected: FAIL — `ChessController` not defined.

- [ ] **Step 4: Write the controller**

`lib/chess/controller/chess_controller.dart`:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
```

- [ ] **Step 5: Run the test to confirm it passes**

Run: `flutter test test/chess/chess_controller_test.dart`
Expected: PASS (both tests).

- [ ] **Step 6: Commit**

```bash
git add lib/chess/model/chess_state.dart lib/chess/controller/chess_controller.dart test/chess/chess_controller_test.dart
git commit -m "feat: add chess state and Riverpod controller"
```

---

### Task 10: Photoreal image-based board + animated piece sprites

**Files:**
- Add assets: `assets/images/board/frame_marble.png`, `assets/images/pieces/{wp,wn,wb,wr,wq,wk,bp,bn,bb,br,bq,bk}.png`
- Create: `lib/chess/ui/board_geometry.dart`
- Test: `test/chess/board_geometry_test.dart`
- Create: `lib/chess/ui/chess_board.dart`

Goal: reproduce the user's reference — gold ornate frame, marble squares, glossy 3D-look pieces at a fixed camera angle with shadows and a soft floor reflection. The board frame + squares are ONE background image; pieces are individual PNG sprites positioned over it and animated on move. The square↔pixel math lives in `board_geometry.dart` (pure, unit-tested); the widget stays thin.

- [ ] **Step 1: Source the art assets (free / CC0 or generated)**

Acquire, matching the reference (cream + black glossy set, gold-trimmed marble frame):
- `frame_marble.png` — square image: gold ornate border enclosing an 8×8 marble grid (light = cream marble, dark = black marble). The playable 8×8 area must be centered; note its inset ratio (border thickness ÷ image width) for Step 3.
- 12 transparent-background piece PNGs, pre-rendered with their own soft drop shadow baked in, tall aspect (~1:1.4) so they sit "standing" on a square.

Free sources: OpenGameArt (filter CC0), Kenney.nl, or generate a consistent set with an image tool (Fable/DALL·E-class) — one prompt per piece, transparent background, identical camera/lighting. **Confirm every asset is CC0 or properly licensed for Play Store distribution** before committing.

If art is not ready when implementing, ship a solid-color placeholder set (a colored rounded rectangle with the piece letter) so the code path is exercised; swap real art in later without code changes. Do NOT block the build on art.

- [ ] **Step 2: Declare the assets**

They live under the already-declared `assets/images/` glob (Task 2), so no `pubspec.yaml` change is needed. Confirm the files exist:
```bash
ls assets/images/board/frame_marble.png assets/images/pieces/wp.png
```

- [ ] **Step 3: Write the failing geometry test**

`test/chess/board_geometry_test.dart`:
```dart
import 'package:flutter/painting.dart';
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
```

- [ ] **Step 4: Run it to confirm it fails**

Run: `flutter test test/chess/board_geometry_test.dart`
Expected: FAIL — `BoardGeometry` not defined.

- [ ] **Step 5: Write the geometry**

`lib/chess/ui/board_geometry.dart`:
```dart
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
    final rank = int.parse(square[1]);                      // 1..8
    final x = inset + file * squareSize;
    final y = inset + (8 - rank) * squareSize;              // rank 1 at bottom
    return Offset(x, y);
  }

  /// Center pixel of the given square.
  Offset centerOf(String square) {
    final tl = topLeftOf(square);
    return Offset(tl.dx + squareSize / 2, tl.dy + squareSize / 2);
  }
}
```

- [ ] **Step 6: Run the test to confirm it passes**

Run: `flutter test test/chess/board_geometry_test.dart`
Expected: PASS (all 4 tests).

- [ ] **Step 7: Write the photoreal board widget**

`lib/chess/ui/chess_board.dart`:
```dart
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
        child: Container(color: AppTheme.accent.withOpacity(0.30)),
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
              BoxShadow(color: AppTheme.accentGlow.withOpacity(0.6), blurRadius: 12),
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
```

> The reference's dramatic perspective can be added later by wrapping the `Stack` in a `Transform` with a perspective matrix (as in the design spec's 2.5D note). v1 ships the flat-but-photoreal composite first — it already matches the marble/gold/glossy look — and the tilt is a low-risk polish add in Task 14.

- [ ] **Step 8: Analyze**

Run: `flutter analyze lib/chess/ui/`
Expected: "No issues found!"

- [ ] **Step 9: Commit**

```bash
git add lib/chess/ui/board_geometry.dart lib/chess/ui/chess_board.dart test/chess/board_geometry_test.dart assets/images/
git commit -m "feat: photoreal image-based chess board with animated sprites"
```

---

### Task 11: Chess screen + wire into router + manual play

**Files:**
- Create: `lib/chess/ui/chess_screen.dart`
- Modify: `lib/app/router.dart` (replace the chess placeholder)

- [ ] **Step 1: Write the chess screen**

`lib/chess/ui/chess_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../controller/chess_controller.dart';
import 'chess_board.dart';

class ChessScreen extends ConsumerWidget {
  const ChessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(chessControllerProvider);
    final controller = ref.read(chessControllerProvider.notifier);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppTheme.gap),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Text(state.status,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded),
                      onPressed: controller.newGame,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.gap),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: ChessBoard(
                        fen: state.fen,
                        enabled: !state.thinking &&
                            !state.isGameOver &&
                            state.isWhiteToMove,
                        lastFrom: state.lastFrom,
                        lastTo: state.lastTo,
                        onMove: controller.playHumanMove,
                      ),
                    ),
                  ),
                ),
              ),
              if (state.isGameOver)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(state.status,
                              style: Theme.of(context).textTheme.headlineMedium)
                          .animate()
                          .fadeIn()
                          .scale(begin: const Offset(0.8, 0.8)),
                      const SizedBox(height: AppTheme.gap),
                      FilledButton(
                        onPressed: controller.newGame,
                        child: const Text('New game'),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Wire the route**

In `lib/app/router.dart`, replace the chess case body:
```dart
    case Routes.chess:
      return _fade(const ChessScreen());
```
And add the import at the top:
```dart
import '../chess/ui/chess_screen.dart';
```

- [ ] **Step 3: Analyze the whole project**

Run: `flutter analyze`
Expected: "No issues found!"

- [ ] **Step 4: Run the full test suite**

Run: `flutter test`
Expected: all tests PASS (home, chess_game, random_chess_ai, chess_controller).

- [ ] **Step 5: Manual play verification (device/emulator — Stockfish needs native)**

Run: `flutter run` on an Android emulator or physical device (NOT web — Stockfish native binary is Android/iOS only; on web it falls back to random).
Verify: marble board + gold frame render; tap a white piece → glowing selection ring; tap a destination → sprite glides; status shows "AI thinking…" then the AI replies; last-move squares highlighted; checkmate shows the game-over overlay; "New game" resets.
(At this task the board uses placeholder art if final assets are not in yet — the layout and play loop are what you are verifying.)

- [ ] **Step 6: Commit**

```bash
git add lib/chess/ui/chess_screen.dart lib/app/router.dart
git commit -m "feat: wire chess screen into app with full play loop"
```

---

### Task 12: Feedback service (sound + haptics)

**Files:**
- Create: `lib/shared/services/feedback_service.dart`
- Modify: `lib/chess/controller/chess_controller.dart` (fire feedback on moves)
- Add assets: `assets/sounds/move.mp3`, `capture.mp3`, `win.mp3`

- [ ] **Step 1: Source three free sound files**

Download CC0 sounds (e.g. from freesound.org / mixkit) into `assets/sounds/` named exactly `move.mp3`, `capture.mp3`, `win.mp3`. Keep them short (<1s for move/capture).

- [ ] **Step 2: Write the feedback service**

`lib/shared/services/feedback_service.dart`:
```dart
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

enum GameSound { move, capture, win }

/// Plays short SFX and fires haptics. Safe to call anywhere; failures are
/// swallowed so audio issues never break gameplay.
class FeedbackService {
  final AudioPlayer _player = AudioPlayer();

  static const _files = {
    GameSound.move: 'sounds/move.mp3',
    GameSound.capture: 'sounds/capture.mp3',
    GameSound.win: 'sounds/win.mp3',
  };

  Future<void> play(GameSound sound) async {
    try {
      await _player.play(AssetSource(_files[sound]!));
    } catch (_) {
      // ignore missing/failed audio
    }
  }

  void tap() => HapticFeedback.selectionClick();
  void impact() => HapticFeedback.mediumImpact();

  void dispose() => _player.dispose();
}
```

- [ ] **Step 3: Fire feedback from the controller**

In `chess_controller.dart`, add a `FeedbackService` field and call it. Add the import:
```dart
import '../../shared/services/feedback_service.dart';
```
Change the constructor and `playHumanMove` so that after each successful move it plays a sound. Full replacement of the constructor + `playHumanMove`:
```dart
  ChessController(this._ai, {FeedbackService? feedback})
      : _feedback = feedback ?? FeedbackService(),
        _game = ChessGame(),
        super(const ChessState(
          fen: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
          isGameOver: false,
          isWhiteToMove: true,
          status: 'Your move',
        )) {
    _sync();
  }

  final ChessAi _ai;
  final FeedbackService _feedback;
  ChessGame _game;

  Future<void> playHumanMove(String uci) async {
    if (_game.isGameOver || !state.isWhiteToMove) return;
    final humanCaptures = _game.isOccupied(uci.substring(2, 4));
    if (!_game.makeUciMove(uci)) return;
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
```
Also update `dispose`:
```dart
  @override
  void dispose() {
    _ai.dispose();
    _feedback.dispose();
    super.dispose();
  }
```

The controller test still constructs `ChessController(RandomChessAi(...))`; the default `FeedbackService` swallows audio errors in the test environment, so tests are unaffected. (Optionally pass a no-op feedback in tests, but not required.)

- [ ] **Step 4: Run the test suite**

Run: `flutter test`
Expected: all tests still PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/shared/services/feedback_service.dart lib/chess/controller/chess_controller.dart assets/sounds/
git commit -m "feat: add sound and haptic feedback to chess moves"
```

---

### Task 13: Persist and restore the game

**Files:**
- Create: `lib/shared/services/storage_service.dart`
- Test: `test/shared/storage_service_test.dart`
- Modify: `lib/chess/controller/chess_controller.dart` (save on move, restore on start)

- [ ] **Step 1: Write the failing test**

`test/shared/storage_service_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:game_mobile_app/shared/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('saves and loads the chess FEN', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = StorageService(await SharedPreferences.getInstance());

    expect(storage.loadChessFen(), isNull);

    const fen = 'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq - 0 1';
    await storage.saveChessFen(fen);

    expect(storage.loadChessFen(), fen);

    await storage.clearChessFen();
    expect(storage.loadChessFen(), isNull);
  });
}
```

- [ ] **Step 2: Run it to confirm it fails**

Run: `flutter test test/shared/storage_service_test.dart`
Expected: FAIL — `StorageService` not defined.

- [ ] **Step 3: Write the storage service**

`lib/shared/services/storage_service.dart`:
```dart
import 'package:shared_preferences/shared_preferences.dart';

/// Thin typed wrapper over shared_preferences for local game persistence.
class StorageService {
  StorageService(this._prefs);
  final SharedPreferences _prefs;

  static const _chessFenKey = 'chess.fen';

  String? loadChessFen() => _prefs.getString(_chessFenKey);
  Future<void> saveChessFen(String fen) => _prefs.setString(_chessFenKey, fen);
  Future<void> clearChessFen() => _prefs.remove(_chessFenKey);
}
```

- [ ] **Step 4: Run the test to confirm it passes**

Run: `flutter test test/shared/storage_service_test.dart`
Expected: PASS.

- [ ] **Step 5: Wire persistence into the controller and provider**

In `chess_controller.dart`, add an optional `StorageService` and a `ChessGame.fromFen` restore path. Add the import:
```dart
import '../../shared/services/storage_service.dart';
```
Add a field and optional constructor arg (extend the constructor from Task 12):
```dart
  ChessController(this._ai, {FeedbackService? feedback, StorageService? storage})
      : _feedback = feedback ?? FeedbackService(),
        _storage = storage,
        _game = _restore(storage),
        super(...unchanged initial state...) {
    _sync();
  }

  final StorageService? _storage;

  static ChessGame _restore(StorageService? storage) {
    final fen = storage?.loadChessFen();
    if (fen == null) return ChessGame();
    return ChessGame.fromFen(fen);
  }
```
> Note: the `super(...)` initial state is only correct for a fresh game. When restoring, `_sync()` in the constructor body immediately overwrites `state` from the restored `_game`, so the placeholder initial FEN is replaced. Keep the `super(...)` block exactly as in Task 12.

After every `_sync(...)`-producing move in `playHumanMove`, persist the FEN. Simplest: save inside `_sync`:
```dart
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
```
And in `newGame()`, clear the save:
```dart
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
```

- [ ] **Step 6: Provide StorageService to the provider**

Since `SharedPreferences.getInstance()` is async, expose it via a provider initialized in `main`. In `main.dart`, load prefs before `runApp` and override the provider:
```dart
import 'package:shared_preferences/shared_preferences.dart';
import 'shared/services/storage_service.dart';

final storageProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('overridden in main');
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(ProviderScope(
    overrides: [
      storageProvider.overrideWithValue(StorageService(prefs)),
    ],
    child: const GameApp(),
  ));
}
```
(Add `import 'package:flutter_riverpod/flutter_riverpod.dart';` if not present.) Then in `chess_controller.dart`, update `chessControllerProvider` to read it:
```dart
final chessControllerProvider =
    StateNotifierProvider.autoDispose<ChessController, ChessState>((ref) {
  final ai = StockfishChessAi(skill: 5, moveTimeMs: 800);
  ref.onDispose(ai.dispose);
  return ChessController(ai, storage: ref.watch(storageProvider));
});
```
Add `import '../../main.dart';` to reach `storageProvider`, or (cleaner) move `storageProvider` into `storage_service.dart` and import that in both places. Prefer moving it into `storage_service.dart`.

- [ ] **Step 7: Run the whole suite + analyze**

Run: `flutter test && flutter analyze`
Expected: all PASS; "No issues found!"

- [ ] **Step 8: Commit**

```bash
git add lib/shared/services/storage_service.dart test/shared/storage_service_test.dart lib/chess/controller/chess_controller.dart lib/main.dart
git commit -m "feat: persist and restore chess game locally"
```

---

### Task 14: Release polish + Play Store build

**Files:**
- Modify: `lib/chess/ui/chess_board.dart` (optional perspective tilt), `android/app/build.gradle`, app icons, splash

- [ ] **Step 1 (optional): Add the reference's angled perspective**

To match the reference's dramatic camera angle, wrap the board `Stack` returned by `ChessBoard.build` in a perspective `Transform`:
```dart
        return Transform(
          alignment: Alignment.topCenter,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0012) // perspective depth
            ..rotateX(0.35),         // tilt back so far rank recedes
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(children: children),
          ),
        );
```
Then re-run on device and tune `rotateX` until it reads like the reference without distorting taps too much. If tap accuracy suffers, keep the flat composite (it already matches the marble/gold/glossy look) and skip the tilt. Verify play still works, then commit.

- [ ] **Step 2: Set the app name and icon**

Add `flutter_launcher_icons` and a 1024x1024 `assets/images/icon.png`, then:
```bash
flutter pub add --dev flutter_launcher_icons
```
Create `flutter_launcher_icons.yaml`:
```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/images/icon.png"
```
Run: `dart run flutter_launcher_icons`
Expected: launcher icons generated for Android/iOS.

- [ ] **Step 3: Build a release APK to confirm it compiles for Android**

Run: `flutter build apk --release`
Expected: "Built build/app/outputs/flutter-apk/app-release.apk".

- [ ] **Step 4: Build an app bundle (Play Store format)**

Run: `flutter build appbundle --release`
Expected: "Built build/app/outputs/bundle/release/app-release.aab".

> Signing note: a release upload to Play needs an upload keystore configured in
> `android/key.properties` + `android/app/build.gradle`. This is a one-time
> account/signing setup done alongside the US$25 Play Console registration —
> out of scope for code, tracked as a release checklist item.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "chore: app icon and release build config"
```

---

## Definition of Done (this plan)

- `flutter test` — all tests pass.
- `flutter analyze` — no issues.
- App runs on an Android device: animated menu → Chess playable end-to-end vs Stockfish AI, with move animation, sound, haptics, game-over overlay, resume-after-restart, and a "New game" reset.
- `flutter build appbundle --release` produces a `.aab`.
- Dugna card is present but disabled ("Coming soon") — implemented in the next plan.
