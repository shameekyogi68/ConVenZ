// This is a basic Flutter widget test for Convenz Customer App.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:convenz_customer_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    dotenv.testLoad(
      fileInput: 'API_BASE_URL=https://convenz.onrender.com/api/v1\n',
    );

    // Build our app and trigger a frame.
    //
    // IMPORTANT: This app uses tall, scroll-less onboarding layouts which can
    // overflow the default test viewport. For this smoke test, we only verify
    // that the widget tree builds without throwing.
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    // If the app builds, MaterialApp.router should exist.
    expect(find.byType(MaterialApp), findsOneWidget);

    // Dispose to avoid pending animation timers (splash/onboarding).
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
