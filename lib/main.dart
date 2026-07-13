import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/router.dart';
import 'app/theme.dart';
import 'shared/services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [
        storageProvider.overrideWithValue(StorageService(prefs)),
      ],
      child: const GameApp(),
    ),
  );
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
