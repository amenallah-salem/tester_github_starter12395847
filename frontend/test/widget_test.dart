import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gym_app/app.dart';

void main() {
  setUp(() {
    // GymApp's startup bootstrap (authBootstrapProvider) reads
    // SharedPreferences and flutter_secure_storage before rendering any
    // route. Neither plugin has a real platform implementation under
    // `flutter test`, and unlike a plain Dart `test()`, a MissingPluginException
    // thrown here never propagates out to settle the bootstrap FutureProvider
    // as an error — it leaves it stuck in AsyncLoading forever, so the app
    // never gets past the boot spinner and pumpAndSettle times out. Mocking
    // both channels lets bootstrap actually resolve.
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (call) async {
        switch (call.method) {
          case 'read':
            return null;
          case 'readAll':
            return <String, String>{};
          default:
            return null;
        }
      },
    );
  });

  testWidgets('app boots into sign in', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: GymApp()));
    await tester.pumpAndSettle();
    expect(find.text('Welcome'), findsOneWidget);
  });
}
