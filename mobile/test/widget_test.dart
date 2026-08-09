// This is a basic Flutter widget test.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mobile/main.dart';
import 'package:mobile/providers/app_state.dart';

void main() {
  testWidgets('AegisApp landing screen test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const AegisApp(),
      ),
    );

    // Verify that landing screen elements render.
    expect(find.text('Aegis AI'), findsOneWidget);
    expect(find.text('Launch Security Console  →'), findsOneWidget);
  });
}
