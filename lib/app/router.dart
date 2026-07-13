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
      pageBuilder: (_, _, _) => child,
      transitionsBuilder: (_, anim, _, c) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
        child: c,
      ),
    );
