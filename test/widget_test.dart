import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_bee/src/app.dart';

void main() {
  testWidgets('HabitBee app loads successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const HabitBeeApp());

    // Verify that the splash screen or app loads
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
