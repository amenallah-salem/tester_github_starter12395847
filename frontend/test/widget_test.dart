import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gym_app/app.dart';

void main() {
  testWidgets('app boots into sign in', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: GymApp()));
    await tester.pumpAndSettle();
    expect(find.text('Welcome'), findsOneWidget);
  });
}
