// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:log_your_dog/main.dart';

void main() {
  testWidgets('App loads with bottom navigation', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const LogYourDogApp());

    // Verify that the app loads with the bottom navigation bar
    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Log Dog'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Collections'), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);

    // Verify that Home Feed screen is initially displayed
    expect(find.text('Home Feed'), findsOneWidget);
  });
}
