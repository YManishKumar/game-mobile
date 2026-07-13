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
