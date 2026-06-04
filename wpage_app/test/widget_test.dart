import 'package:flutter_test/flutter_test.dart';

import 'package:wpage_app/main.dart';

void main() {
  testWidgets('App launches purpose screen', (WidgetTester tester) async {
    await tester.pumpWidget(const WPageApp());
    expect(find.text('What kind of page do you need?'), findsOneWidget);
  });
}
