// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smart_bin_flutter/main.dart'; // Ensure this matches your package name

void main() {
  testWidgets('Opening screen renders core UI elements', (WidgetTester tester) async {
    // Build our app and trigger a frame using the NEW class name.
    await tester.pumpWidget(const AuthSequenceApp());

    // Wait for any animations/fonts to finish loading
    await tester.pumpAndSettle();

    // Verify that the Opening Screen elements are present.
    expect(find.text('logo'), findsOneWidget);
    expect(find.text('Explore the app'), findsOneWidget);

    // Verify the buttons are present
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
  });
}