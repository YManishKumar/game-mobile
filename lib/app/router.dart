import 'package:flutter/material.dart';
import '../home/home_screen.dart';
import '../chess/ui/chess_screen.dart';

class Routes {
  static const home = '/';
  static const chess = '/chess';
}

Route<dynamic> onGenerateRoute(RouteSettings settings) {
  switch (settings.name) {
    case Routes.home:
      return _fade(const HomeScreen());
    case Routes.chess:
      return _fade(const ChessScreen());
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
