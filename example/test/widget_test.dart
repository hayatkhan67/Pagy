// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pagy/pagy.dart';
import '../lib/main.dart';

void main() {
  setUpAll(() {
    // Initialize Pagy for tests
    PagyConfig().initialize(
      baseUrl: "https://api.jikan.moe/v4/",
      enableLogs: false,
    );
  });

  testWidgets('Pagy example app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const PagyExampleApp());

    // Wait for the app to settle
    await tester.pumpAndSettle();

    // Verify the app title appears
    expect(find.text('PAGY'), findsOneWidget);

    // Verify navigation bar exists
    expect(find.byType(BottomNavigationBar), findsOneWidget);
  });
}
