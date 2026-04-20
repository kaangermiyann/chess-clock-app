import 'package:flutter_test/flutter_test.dart';

import 'package:chess_clock_app/main.dart';

void main() {
  testWidgets('App boots directly to Home in offline mode',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ChessClockApp());
    await tester.pump();
    expect(find.text('Chess Clock'), findsWidgets);
    expect(find.text('White'), findsOneWidget);
    expect(find.text('Black'), findsOneWidget);
  });
}
