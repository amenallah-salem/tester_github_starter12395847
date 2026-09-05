import 'package:flutter_test/flutter_test.dart';

import 'package:gym_app/core/router/redirect.dart';

void main() {
  group('resolveRedirect', () {
    test('regression: signed out with onboarding done stays on /sign-in', () {
      // This exact state used to loop: /sign-in => / => /sign-in => ...
      expect(
        resolveRedirect(
          location: '/sign-in',
          signedIn: false,
          onboardingDone: true,
        ),
        isNull,
      );
    });

    test('signed out is sent to /sign-in from anywhere', () {
      for (final done in [true, false]) {
        for (final loc in ['/', '/onboarding', '/explorer', '/you']) {
          expect(
            resolveRedirect(
              location: loc,
              signedIn: false,
              onboardingDone: done,
            ),
            '/sign-in',
            reason: '$loc (done=$done)',
          );
        }
      }
    });

    test('signed in leaves /sign-in for onboarding or home', () {
      expect(
        resolveRedirect(
          location: '/sign-in',
          signedIn: true,
          onboardingDone: false,
        ),
        '/onboarding',
      );
      expect(
        resolveRedirect(
          location: '/sign-in',
          signedIn: true,
          onboardingDone: true,
        ),
        '/',
      );
    });

    test('signed in with onboarding pending is kept on /onboarding', () {
      expect(
        resolveRedirect(
          location: '/',
          signedIn: true,
          onboardingDone: false,
        ),
        '/onboarding',
      );
      expect(
        resolveRedirect(
          location: '/onboarding',
          signedIn: true,
          onboardingDone: false,
        ),
        isNull,
      );
    });

    test('signed in with onboarding done can reach every page', () {
      for (final loc in ['/', '/explorer', '/progress', '/coach', '/you']) {
        expect(
          resolveRedirect(
            location: loc,
            signedIn: true,
            onboardingDone: true,
          ),
          isNull,
          reason: loc,
        );
      }
    });

    test('no state combination can produce a redirect loop', () {
      const locations = [
        '/sign-in',
        '/onboarding',
        '/',
        '/explorer',
        '/progress',
        '/coach',
        '/you',
      ];
      for (final signedIn in [true, false]) {
        for (final done in [true, false]) {
          for (final start in locations) {
            var loc = start;
            for (var hop = 0; hop < 5; hop++) {
              final next = resolveRedirect(
                location: loc,
                signedIn: signedIn,
                onboardingDone: done,
              );
              if (next == null) break;
              expect(next, isNot(loc), reason: 'self-redirect at $loc');
              loc = next;
            }
            expect(
              resolveRedirect(
                location: loc,
                signedIn: signedIn,
                onboardingDone: done,
              ),
              isNull,
              reason:
                  'redirect chain from $start never settles '
                  '(signedIn=$signedIn, done=$done)',
            );
          }
        }
      }
    });
  });
}
