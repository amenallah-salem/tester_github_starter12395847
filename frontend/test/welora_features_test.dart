import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gym_app/core/theme/app_theme.dart';
import 'package:gym_app/features/recovery/presentation/breathwork_page.dart';

void main() {
  testWidgets('breathwork starts and pauses its guided timer', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const BreathworkPage(),
      ),
    );

    expect(find.text('1:00'), findsOneWidget);
    await tester.tap(find.text('Begin'));
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Pause'), findsOneWidget);
    expect(find.text('0:58'), findsOneWidget);

    await tester.tap(find.text('Pause'));
    await tester.pump();
    expect(find.text('Begin'), findsOneWidget);
  });
}
