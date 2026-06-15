// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gmb_ai/app/app.dart';

void main() {
  testWidgets('shows login screen when user is signed out', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: GmbAiApp()));
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('Continue with Google'), findsOneWidget);
  });
}
