import 'package:flutter_test/flutter_test.dart';
import 'package:beast_physique/main.dart';

void main() {
  testWidgets('Smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const BeastPhysicalAlkalmazas());

    // Egyszerű ellenőrzés, hogy az app elindul-e
    expect(find.byType(BeastPhysicalAlkalmazas), findsOneWidget);
  });
}
