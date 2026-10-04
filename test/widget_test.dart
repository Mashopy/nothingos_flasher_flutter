// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nothingos_flasher/main.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.byType(MyApp), findsOneWidget);
  });

  test('NDot57Caps font asset loads successfully', () async {
    final fontFile = File('assets/fonts/NDot57Caps.otf');
    expect(fontFile.existsSync(), isTrue, reason: 'Font file missing on disk');

    final bytes = await rootBundle.load('assets/fonts/NDot57Caps.otf');
    expect(bytes.lengthInBytes, greaterThan(0));

    final fontLoader = FontLoader('NDot57Caps');
    fontLoader.addFont(Future.value(bytes));
    await fontLoader.load();
  });
}
