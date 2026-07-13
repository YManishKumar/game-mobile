import 'package:flutter_riverpod/flutter_riverpod.dart';
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

/// App-wide [StorageService] handle. `SharedPreferences.getInstance()` is async,
/// so this provider is created unimplemented and overridden in `main()` with a
/// real instance once prefs have loaded.
final storageProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('storageProvider must be overridden in main()');
});
