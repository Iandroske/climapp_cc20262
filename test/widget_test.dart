import 'package:climapp_cc20262/src/screens/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('WelcomeScreen renderiza título e botão de entrar', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: WelcomeScreen(),
      ),
    );

    expect(find.text('Boas-vindas!'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });
}
