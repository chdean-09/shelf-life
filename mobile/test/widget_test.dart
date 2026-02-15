import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/main.dart';

void main() {
  testWidgets('ShelfLife app renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: ShelfLifeApp()),
    );
    // Verify the app title appears
    expect(find.text('ShelfLife'), findsOneWidget);
  });
}
