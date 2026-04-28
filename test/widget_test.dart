import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:networth_cockpit/app.dart';

void main() {
  testWidgets('app boots with a router MaterialApp', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: NetWorthCockpitApp()));

    expect(find.text('NetWorth Cockpit'), findsOneWidget);
    expect(find.byType(ProviderScope), findsOneWidget);
  });
}
