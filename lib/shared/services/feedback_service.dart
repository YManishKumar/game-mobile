import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

enum GameSound { move, capture, win }

/// Plays short SFX and fires haptics. Safe to call anywhere; failures are
/// swallowed so audio/haptic issues never break gameplay.
///
/// Audio and haptics both talk to platform channels, which require an
/// initialized Flutter binding. That binding exists in the running app and in
/// widget tests, but NOT in plain unit tests — where the `audioplayers` and
/// `HapticFeedback` channels are unavailable and would raise an unhandled
/// error (the `AudioPlayer` constructor's async `_create` throws a
/// `FlutterError`, which is an `Error`, so it slips past a normal try/catch).
/// We therefore skip both entirely when the binding is absent, and build the
/// player lazily so it is never constructed in that case.
class FeedbackService {
  AudioPlayer? _player;

  static const _files = {
    GameSound.move: 'sounds/move.wav',
    GameSound.capture: 'sounds/capture.wav',
    GameSound.win: 'sounds/win.wav',
  };

  /// True only when a Flutter binding is initialized. Accessing `.instance`
  /// throws when it is not, which is exactly the case we need to detect.
  bool get _pluginsAvailable {
    try {
      ServicesBinding.instance;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> play(GameSound sound) async {
    if (!_pluginsAvailable) return;
    try {
      final player = _player ??= AudioPlayer();
      await player.play(AssetSource(_files[sound]!));
    } catch (_) {
      // ignore missing/failed audio
    }
  }

  void tap() {
    if (!_pluginsAvailable) return;
    try {
      HapticFeedback.selectionClick();
    } catch (_) {
      // ignore unavailable haptics
    }
  }

  void impact() {
    if (!_pluginsAvailable) return;
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {
      // ignore unavailable haptics
    }
  }

  void dispose() {
    try {
      _player?.dispose();
    } catch (_) {
      // ignore
    }
  }
}
