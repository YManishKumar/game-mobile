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
