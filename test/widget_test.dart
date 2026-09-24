import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lsupop/main.dart';

void main() {
  testWidgets('home screen shows both tabs and the sell button',
      (WidgetTester tester) async {
    await tester.pumpWidget(const LsuPopApp());

    expect(find.text('Browse'), findsOneWidget);
    expect(find.text('Messages'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('searching filters the browse grid', (WidgetTester tester) async {
    await tester.pumpWidget(const LsuPopApp());

    expect(find.text('Vintage LSU Crewneck'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'mug');
    await tester.pumpAndSettle();

    expect(find.text('Vintage LSU Crewneck'), findsNothing);
    expect(find.text('LSU Mike the Tiger Mug'), findsOneWidget);
  });
}
