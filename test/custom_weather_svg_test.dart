import 'package:climapp_cc20262/src/widgets/custom_weather_svg.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CustomWeatherSvg exibe errorWidget (Icons.cloud_off) quando a URL for vazia ou inválida', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CustomWeatherSvg(
            imageUrl: '',
            height: 40,
            width: 40,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.cloud_off), findsOneWidget);
  });
}
