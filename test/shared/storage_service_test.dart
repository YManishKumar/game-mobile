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
