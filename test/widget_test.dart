import 'package:flutter_test/flutter_test.dart';
import 'package:nourish_v/main.dart';

void main() {
  testWidgets('App starts and shows splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const NourishVApp());
    expect(find.text('Nourish V'), findsOneWidget);
  });
}
