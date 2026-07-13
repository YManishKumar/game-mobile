# Design: Dugna + Chess — Offline Game App

**Date:** 2026-07-13
**Status:** Approved (brainstorming), pending spec review

## 1. Overview

A cross-platform mobile game app built with **Flutter**, shipping to Google Play
(and iOS-capable from the same codebase). It contains two offline board games —
**Chess** and **Dugna** (Dominoes, double-six draw variant) — played against an
on-device AI opponent. No network, no accounts, no backend. The differentiator
is a **premium, cinematic UI**: layered depth (2.5D), smooth motion, particles,
haptics, and sound.

### Non-goals (v1)

- No online multiplayer, matchmaking, or lobbies.
- No voice chat.
- No user accounts / cloud sync.
- No real-time 3D model rendering (depth is faked via 2.5D — tilt, shadow, parallax).
- No in-app purchases / ads.

These are explicitly deferred. The screenshot the user shared (4-player online
dominoes with "Hold to talk" voice) is the long-term vision; v1 is the offline
single-player foundation that vision will later build on.

## 2. Platform decision

**Flutter**, chosen over native Kotlin because:

- User writes no code; a single codebase yields both Android and iOS apps.
- Best-in-class animation tooling (`flutter_animate`, Rive, Lottie, custom painters)
  serves the "top-notch cinematic UI" requirement with less effort.
- Large free package ecosystem (chess engine, board widgets) reduces custom work.
- Compiles to a real native app accepted by Google Play.

Kotlin was rejected: Android-only, more code, no upside for this use case.

## 3. Cost reality

- Flutter, Dart, all packages, and build tooling: **free**.
- **Google Play Developer account: one-time US$25 fee** — the only unavoidable cost
  to publish on the Play Store. Not free, no workaround.
- Free distribution alternatives if the $25 is a blocker: direct APK sideload,
  F-Droid, or a PWA web build. (Play Store remains the recommended target.)

## 4. Architecture

```
App
├── Home screen        (animated menu: "Chess" / "Dugna" cards)
├── Chess module       (board + rules + AI opponent + animated board UI)
├── Dugna module       (tiles + draw-variant rules + AI + felt-table UI)
└── Shared layer       (theme, animation system, sound, haptics, settings, local save)
```

Each game module is self-contained: its own game-state model, rules engine, AI,
and UI, communicating with the rest of the app only through the shared layer and a
common "game screen" contract. This keeps each game independently understandable
and testable, and lets the second game be added without touching the first.

### Module boundaries

- **Shared layer** — theme tokens, reusable animated widgets, sound/haptic
  services, settings, `shared_preferences` persistence. Depends on nothing
  game-specific. Consumed by both games and the home screen.
- **Chess module** — pure Dart rules/state (`chess` package) + AI (`stockfish`)
  behind a thin interface, plus the board/piece UI. Depends only on the shared
  layer. No knowledge of Dugna.
- **Dugna module** — custom rules/state + custom AI behind the same interface
  shape, plus the table/tile UI. Depends only on the shared layer. No knowledge
  of Chess.
- **Home screen** — navigates to a game module; depends on the shared layer.

## 5. Tech stack (all free)

| Concern            | Choice |
|--------------------|--------|
| State management   | `flutter_riverpod` |
| Chess rules        | `chess` (Dart) |
| Chess board UI     | `flutter_chess_board` or custom painter |
| Chess AI           | `stockfish` package (strong, fully offline) |
| Dominoes rules/AI  | custom (no adequate package exists) |
| Animation          | `flutter_animate` + `rive` / `lottie` |
| Particles          | `confetti` or custom painter |
| Sound              | `audioplayers` |
| Haptics            | `flutter`'s `HapticFeedback` |
| Local persistence  | `shared_preferences` |

## 6. Build order (incremental slices)

Shipped in slices, each leaving the app in a working state.

1. **Slice 0 — Foundation.** Install Flutter, scaffold project, app shell, home
   menu, shared theme + animation system. Not playable, but the polished skeleton.
2. **Slice 1 — Chess.** Full rules, move validation, AI opponent, animated 2.5D
   board. First playable, shippable build. Chosen first because ready-made free
   packages give a strong AI quickly.
3. **Slice 2 — Dugna (Dominoes).** Tiles, double-six draw-variant rules, custom
   AI, felt-table UI matching the reference screenshot. Second because rules and
   AI are hand-written and slower.
4. **Slice 3 — Polish + Play Store build.** Final animation pass, icons, splash,
   signing, release build.

## 7. Cinematic UI approach ("top-notch")

"8D" is not literal (it is an audio marketing term). Delivered as layered depth +
motion + polish:

**Visual style**
- Dark premium theme, deep gradients, glassmorphism panels, glow accents.
- Chess: 2.5D board (perspective tilt, drop shadows, marble/wood textures), pieces
  with depth.
- Dugna: textured green felt table (matching the screenshot), realistic domino
  tiles with shadows.

**Motion (the "cinematic")**
- Animated home menu: parallax background, cards float/tilt on tap.
- Piece/tile moves: smooth eased glide, never teleport.
- Capture/win moments: particle burst, screen flourish, camera-style zoom.
- Micro-interactions: button ripples, haptic feedback, per-action sound.
- Screen transitions: shared-element + fade/slide, "scene"-like.

**Tech for it**
- `flutter_animate` for chained cinematic sequences.
- `rive` for interactive vector animation (logo, win screens).
- Custom painters + `Transform` for the 2.5D board tilt and shadows.
- `confetti`/custom painter for particles.

**Explicit limit:** real rotating 3D models are heavy and out of scope for v1;
depth is faked with 2.5D (tilt + shadow + parallax) — premium look, smooth, free.
Real 3D is a possible later upgrade.

## 8. Dugna (Dominoes) rules — v1

Based on the reference screenshot ("Drew game one round", PASS button, double-six
tiles). Draw/Block variant, adapted to single-player-vs-AI:

- Standard **double-six set** (28 tiles).
- v1 is **1 human vs 3 AI** (or 1 vs 1 — to be finalized in the plan), players take
  turns matching a tile end to an open end of the layout.
- If a player cannot play, they **draw** from the boneyard until they can, or
  **PASS** if the boneyard is empty.
- Round ends when a player is out of tiles (or the game is blocked); scoring by
  remaining pip counts.
- Exact player count, partnership vs free-for-all, and scoring thresholds are
  finalized during the implementation-plan stage.

## 9. Testing strategy

- **Rules engines** (chess via package; Dugna custom) are pure Dart — unit tested
  in isolation: legal-move generation, win/block detection, scoring.
- **AI** tested for "always returns a legal move" and basic quality sanity checks.
- **State management** (Riverpod providers) tested for correct transitions.
- **UI/animation** verified manually on device/emulator (animation quality is
  visual, not unit-testable). Widget tests cover navigation and non-visual state.

## 10. Open items for the plan stage

- Final Dugna player count (1v1 vs 1-vs-3) and scoring rules.
- Chess board: adopt `flutter_chess_board` as-is vs custom painter for the 2.5D look.
- Asset sourcing (piece art, tile art, felt/wood textures, sounds) — all must be
  free / properly licensed.
