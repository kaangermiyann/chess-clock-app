import 'package:flutter_test/flutter_test.dart';

import 'package:chess_clock_app/main.dart';

void main() {
  testWidgets('App boots to Connect screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ChessClockApp());
    expect(find.text('Chess Clock'), findsWidgets);
    expect(find.text('Bağlan'), findsOneWidget);
  });
}
