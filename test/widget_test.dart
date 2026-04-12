import 'package:cotimax/app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('Cotimax login renders', (WidgetTester tester) async {
    await tester.pumpWidget( ProviderScope(child: CotimaxApp()));
    await tester.pumpAndSettle();

    expect(find.text('Cotimax'), findsOneWidget);
    expect(find.text('Ingresar'), findsOneWidget);
  });
}
