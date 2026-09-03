import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gym_app/app.dart';

void main() {
  testWidgets('app boots into onboarding', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: GymApp()));
    await tester.pumpAndSettle();
    // Canonical onboarding brand header.
    expect(find.text('tes2 — Train in the Gym'), findsWidgets);
  });
}
