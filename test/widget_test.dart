// Basic Flutter widget test for Monarch Command.

import 'package:flutter_test/flutter_test.dart';

import 'package:monarch_command/app.dart';

void main() {
  testWidgets('App loads and shows Monarch Command title',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MonarchCommandApp());

    expect(find.text('Monarch Command'), findsOneWidget);
  });
}
