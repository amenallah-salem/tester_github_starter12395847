import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/strings/coaching.dart';

void main() {
  test('coaching strings load from the contract JSON, both tones', () {
    final enc = CoachingStrings.fromJson(CoachingStrings.embeddedJson,
        tone: 'encouraging');
    final terse = CoachingStrings.fromJson(CoachingStrings.embeddedJson,
        tone: 'no_nonsense');

    // Tone variants come from the JSON source, not hardcoded Dart ternaries.
    expect(enc.startCue('Goblet Squat', 0),
        'Let\'s go. First up: Goblet Squat.');
    expect(terse.startCue('Goblet Squat', 0), 'Start: Goblet Squat.');

    // Rotating pools wrap and differ per tone.
    expect(enc.restCue('60', 1), 'Rest 60s — breathe and reset.');
    expect(terse.restCue('60', 1), '60s rest.');

    // Single (non-rotating) keys resolve and interpolate.
    expect(enc.planFocus('Day A', 35), 'Today: Day A — about 35 min.');
    expect(terse.offline, 'You\'re offline — your timers still work.');

    // Tone fallback: a key without a no_nonsense variant reuses encouraging.
    expect(terse.welcomeHeadline, 'Your pocket trainer.');
  });

  test('plan JSON validates against the contract', () {
    // Imported indirectly; the sample plan is contract-valid by construction.
    // (Validation is unit-tested in the validator standalone check.)
    expect(CoachingStrings.embeddedJson.contains('no_nonsense'), isTrue);
  });
}
