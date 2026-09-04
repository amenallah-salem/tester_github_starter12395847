import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Coaching tone. The "You" tab lets the user opt between the default
/// Encouraging voice and a terser No-nonsense variant (TES-6 §5 / coaching-voice).
enum CoachingTone { encouraging, noNonsense }

final coachingToneProvider =
    StateProvider<CoachingTone>((ref) => CoachingTone.encouraging);

/// Single source of truth for all user-facing copy in Milestone 1.
///
/// Every string lives in the coaching-voice contract JSON
/// (`assets/coaching/coaching_strings.json`, delivered by the AI Coach Engineer
/// on TES-13). The app never hardcodes tone: both the `encouraging` and
/// `no_nonsense` variants ship in that one file and the active tone is selected
/// at runtime by [coachingToneProvider]. When a key has no `no_nonsense`
/// variant, the `encouraging` variant is returned (per the contract's
/// tone-fallback rule).
///
/// The same catalog is embedded below ([embeddedJson]) so the app is
/// self-contained even before the asset bundle loads; once the asset is read
/// it takes precedence. The two must stay byte-identical.
class CoachingStrings {
  CoachingStrings(this._data, {this.tone = 'encouraging'})
      : assert(
          _data['tones'] is List && (_data['tones'] as List).contains(tone),
          'Unknown tone: $tone',
        );

  /// The canonical JSON, embedded so the package is self-contained. Must stay
  /// in sync with `assets/coaching/coaching_strings.json`.
  static const String embeddedJson = '''
{
  "version": "1.0.0",
  "sourceOfTruth": "TES-6 / coaching-voice",
  "tones": ["encouraging", "no_nonsense"],
  "defaultTone": "encouraging",
  "interpolation": "{key}",
  "rules": {
    "toneFallback": "If a string has no no_nonsense variant, the encouraging variant is used for both tones.",
    "rotation": "For keys marked 'rotating', the consumer picks an index (e.g. by set/exercise counter) and wraps modulo the pool length."
  },
  "screens": {
    "welcome": {
      "headline": {"encouraging": "Your pocket trainer."},
      "sub": {"encouraging": "Tell us a little about you, and we'll build your first plan."},
      "cta_get_started": {"encouraging": "Get started"},
      "skip_later": {"encouraging": "I'll do this later"}
    },
    "goal_question": {
      "title": {"encouraging": "What are we training for?"},
      "options": {"encouraging": ["Build strength", "Get toned", "Feel healthier", "Train for an event"]},
      "helper": {"encouraging": "No wrong answer — we can change this later."}
    },
    "experience_question": {
      "title": {"encouraging": "How often do you train?"},
      "options": {"encouraging": ["New to this", "Now and then", "Pretty regular"]}
    },
    "weight_question": {
      "title": {"encouraging": "What is your current weight (approx)?"},
      "helper": {"encouraging": "Just an estimate so we can calibrate loads."},
      "options": {"encouraging": ["Under 60kg", "60-75kg", "75-90kg", "Over 90kg"]}
    },
    "muscle_question": {
      "title": {"encouraging": "Which muscle groups do you want to focus on?"},
      "helper": {"encouraging": "Select all that apply — we will balance your plan around them."},
      "options": {"encouraging": ["Upper body", "Lower body", "Core / abs", "Full body"]}
    },
    "schedule_kit": {
      "days_title": {"encouraging": "How many days a week feels right?"},
      "kit_title": {"encouraging": "What will you train with?"},
      "kit_options": {"encouraging": ["Bodyweight", "Gym", "Both"]}
    },
    "generating": {
      "primary": {"encouraging": "Mixing your plan…"},
      "rotating": {"encouraging": ["Finding the right rep ranges.", "Balancing rest and effort.", "Almost there — tailoring it to you."]}
    },
    "today": {
      "greeting_morning": {"encouraging": "Morning, {name}"},
      "greeting_welcome_back": {"encouraging": "Welcome back, {name}"},
      "plan_focus": {"encouraging": "Today: {sessionName} — about {mins} min."},
      "cta_start_workout": {"encouraging": "Start workout"},
      "secondary_regenerate": {"encouraging": "Regenerate plan"},
      "secondary_do_it_later": {"encouraging": "Do it later"},
      "do_it_later_confirm": {"encouraging": "No rush — we'll save this for tonight."}
    },
    "plan_runner": {
      "start": {
        "rotating": {
          "encouraging": ["Let's go. First up: {exercise}.", "Ready when you are. First up: {exercise}.", "Here we go — {exercise} to open the session."],
          "no_nonsense": ["Start: {exercise}.", "Begin: {exercise}.", "First: {exercise}."]
        }
      },
      "work_countdown": {
        "rotating": {
          "encouraging": ["You've got this — {reps} reps.", "Strong start — {reps} reps, own it.", "Nice and controlled — {reps} reps."],
          "no_nonsense": ["Do {reps} reps.", "{reps} reps.", "Reps: {reps}."]
        }
      },
      "rest": {
        "rotating": {
          "encouraging": ["Rest {secs}s. Shake it out.", "Rest {secs}s — breathe and reset.", "Quick {secs}s. Sip some water."],
          "no_nonsense": ["Rest {secs}s.", "{secs}s rest.", "Recover {secs}s."]
        }
      },
      "last_set": {"encouraging": "Last set — give it your all.", "no_nonsense": "Last set."},
      "set_done": {
        "rotating": {
          "encouraging": ["Set done. Breathe.", "That's {n} sets — nice.", "Set {n} in the bag. Keep going."],
          "no_nonsense": ["Set {n} complete.", "Done: set {n}.", "Set {n} logged."]
        }
      },
      "skip_confirm": {"encouraging": "Skip this one? We'll log it later.", "no_nonsense": "Skip this set? Logged later."},
      "pause": {"encouraging": "Paused. Take your time.", "no_nonsense": "Paused."}
    },
    "session_complete": {
      "headline": {"encouraging": "Done! That's a full session in the books."},
      "summary_line": {"encouraging": "{exercises} exercises · {sets} sets · {mins} min."},
      "cta_see_progress": {"encouraging": "See your progress"},
      "cta_done": {"encouraging": "Done"}
    },
    "exercise_detail": {
      "tip_label": {"encouraging": "Coach tip"},
      "example_tip": {"encouraging": "Keep your core tight and move with control — quality over speed."},
      "log_set": {"encouraging": "Log a set"},
      "rep_plus_one": {"encouraging": "+1 rep"},
      "done_set": {"encouraging": "Done set"}
    },
    "progress": {
      "empty": {"encouraging": "No sessions yet — your story starts with one workout."},
      "cta_start_today": {"encouraging": "Start today's plan"},
      "streak": {
        "rotating": {
          "encouraging": ["{n}-day streak. Momentum is real.", "{n} days running — that's the habit forming.", "Look at you: {n} days straight. Keep it."],
          "no_nonsense": ["{n}-day streak.", "{n} days. Consistent.", "{n} in a row."]
        }
      },
      "zero_streak": {"encouraging": "Every streak starts at one. Today's a good day."},
      "personal_best": {"encouraging": "New personal best: {exercise} {value}!"}
    },
    "errors": {
      "generation_failed": {"encouraging": "Something tripped up building your plan. Retry?"},
      "offline": {"encouraging": "You're offline — your timers still work."},
      "missing_exercise": {"encouraging": "We'll skip this set and fix it later."}
    }
  }
}
  ''';

  factory CoachingStrings.fromJson(String json, {String tone = 'encouraging'}) =>
      CoachingStrings(jsonDecode(json) as Map<String, dynamic>, tone: tone);

  factory CoachingStrings.fromMap(Map<String, dynamic> data,
          {String tone = 'encouraging'}) =>
      CoachingStrings(data, tone: tone);

  final Map<String, dynamic> _data;

  /// Active coaching tone. Flip via [coachingToneProvider] to switch every
  /// string between Encouraging and No-nonsense.
  final String tone;

  static const String defaultTone = 'encouraging';

  Map<String, dynamic> get _screens => _data['screens'] as Map<String, dynamic>;

  // ---- public UI API (kept stable so existing screens compile) ----

  String get welcomeHeadline => _string('welcome', 'headline');
  String get welcomeSub => _string('welcome', 'sub');
  String get welcomeCta => _string('welcome', 'cta_get_started');
  String get welcomeLater => _string('welcome', 'skip_later');

  String get goalTitle => _string('goal_question', 'title');
  String get goalHelper => _string('goal_question', 'helper');
  List<String> get goals => _list('goal_question', 'options');

  String get experienceTitle => _string('experience_question', 'title');
  List<String> get experiences => _list('experience_question', 'options');

  String get weightTitle => _string('weight_question', 'title');
  String get weightHelper => _string('weight_question', 'helper');
  List<String> get weightOptions => _list('weight_question', 'options');

  String get muscleTitle => _string('muscle_question', 'title');
  String get muscleHelper => _string('muscle_question', 'helper');
  List<String> get muscleOptions => _list('muscle_question', 'options');

  String get kitTitle => _string('schedule_kit', 'kit_title');
  String get daysQuestion => _string('schedule_kit', 'days_title');
  List<String> get kitOptions => _list('schedule_kit', 'kit_options');

  String get generatingTitle => _string('generating', 'primary');
  List<String> get generatingLines => _list('generating', 'rotating');

  String greeting(String name) =>
      _string('today', 'greeting_morning', vars: {'name': name});
  String welcomeBack(String name) =>
      _string('today', 'greeting_welcome_back', vars: {'name': name});
  String planFocus(String session, Object mins) => _string('today', 'plan_focus',
      vars: {'sessionName': session, 'mins': '$mins'});
  String get startWorkout => _string('today', 'cta_start_workout');
  String get regenerate => _string('today', 'secondary_regenerate');
  String get doItLater => _string('today', 'secondary_do_it_later');
  String get doItLaterConfirm => _string('today', 'do_it_later_confirm');

  String get noPlan => _string('generating', 'primary');
  String get planFailed => _string('errors', 'generation_failed');
  String get retry => 'Retry';

  String startCue(String exercise, [int index = 0]) =>
      _rotating('plan_runner', 'start', index, vars: {'exercise': exercise});
  String workCue(String reps, [int index = 0]) =>
      _rotating('plan_runner', 'work_countdown', index, vars: {'reps': reps});
  String restCue(String secs, [int index = 0]) =>
      _rotating('plan_runner', 'rest', index, vars: {'secs': secs});
  String get lastSetCue => _string('plan_runner', 'last_set');
  String setDoneCue(int n, [int index = 0]) =>
      _rotating('plan_runner', 'set_done', index, vars: {'n': '$n'});
  String get setDoneBreathe =>
      _rotating('plan_runner', 'set_done', 0);
  String get skipConfirm => _string('plan_runner', 'skip_confirm');
  String get pausedCue => _string('plan_runner', 'pause');

  String get sessionDone => _string('session_complete', 'headline');
  String sessionSummary(int ex, int sets, int mins) => _string(
      'session_complete', 'summary_line',
      vars: {'exercises': '$ex', 'sets': '$sets', 'mins': '$mins'});
  String get seeProgress => _string('session_complete', 'cta_see_progress');
  String get done => _string('session_complete', 'cta_done');

  String get coachTipLabel => _string('exercise_detail', 'tip_label');
  String get logSet => _string('exercise_detail', 'log_set');
  String get plusRep => _string('exercise_detail', 'rep_plus_one');
  String get doneSet => _string('exercise_detail', 'done_set');

  String get progressEmpty => _string('progress', 'empty');
  String get startTodaysPlan => _string('progress', 'cta_start_today');
  String streak(int n) =>
      _rotating('progress', 'streak', 0, vars: {'n': '$n'});
  String get zeroStreak => _string('progress', 'zero_streak');
  String personalBest(String exercise, String value) => _string('progress',
      'personal_best', vars: {'exercise': exercise, 'value': value});

  String get offline => _string('errors', 'offline');
  String get missingExercise => _string('errors', 'missing_exercise');

  // ---- internals ----

  String _string(String screen, String key, {Map<String, String>? vars}) {
    final node = _node(screen, key);
    final value = _toneValue(node);
    return _interpolate(value, vars);
  }

  String _rotating(String screen, String key, int rotationIndex,
      {Map<String, String>? vars}) {
    final node = _node(screen, key);
    final poolNode = node['rotating'] as Map<String, dynamic>?;
    if (poolNode == null) {
      final value = _toneValue(node);
      return _interpolate(value, vars);
    }
    final pool = _tonePool(poolNode);
    if (pool.isEmpty) return '';
    final idx = rotationIndex % pool.length;
    return _interpolate(pool[idx], vars);
  }

  List<String> _list(String screen, String key) {
    final node = _node(screen, key);
    if (node is List) return List<String>.from(node);
    if (node is Map<String, dynamic>) {
      final pick = node.containsKey(tone)
          ? node[tone]
          : (node.containsKey(defaultTone) ? node[defaultTone] : node.values.first);
      if (pick is String) return [pick];
      if (pick is List) return List<String>.from(pick);
    }
    throw ArgumentError('Not a list-valued string: $screen.$key');
  }

  dynamic _node(String screen, String key) {
    final s = _screens[screen] as Map<String, dynamic>?;
    if (s == null) throw ArgumentError('Unknown screen: $screen');
    final node = s[key];
    if (node == null) throw ArgumentError('Unknown key "$key" on screen "$screen"');
    return node;
  }

  String _toneValue(dynamic node) {
    if (node is String) return node;
    if (node is Map) {
      final map = node as Map<String, dynamic>;
      if (map.containsKey(tone)) return map[tone] as String;
      if (map.containsKey(defaultTone)) return map[defaultTone] as String;
      if (map.isNotEmpty) return map.values.first as String;
    }
    throw ArgumentError('String node is neither a string nor a tone map: $node');
  }

  List<String> _tonePool(Map<String, dynamic> poolNode) {
    if (poolNode.containsKey(tone)) {
      return List<String>.from(poolNode[tone] as List);
    }
    if (poolNode.containsKey(defaultTone)) {
      return List<String>.from(poolNode[defaultTone] as List);
    }
    if (poolNode.isNotEmpty) {
      return List<String>.from(poolNode.values.first as List);
    }
    return const [];
  }

  String _interpolate(String text, Map<String, String>? vars) {
    if (vars == null || vars.isEmpty) return text;
    var out = text;
    for (final e in vars.entries) {
      out = out.replaceAll('{${e.key}}', e.value);
    }
    return out;
  }
}

/// Loads the coaching-voice contract JSON from the app bundle. Once resolved it
/// takes precedence over the embedded copy (they are byte-identical).
final coachingBundleProvider = FutureProvider<String>((ref) async {
  final bundle = await rootBundle.loadString('assets/coaching_voice.json');
  return bundle;
});

/// Resolves [CoachingStrings] for the active tone. Screens consume this — tone
/// is never hardcoded anywhere else in the app.
final coachingStringsProvider = Provider<CoachingStrings>((ref) {
  final tone = ref.watch(coachingToneProvider);
  final bundle =
      ref.watch(coachingBundleProvider).value ?? CoachingStrings.embeddedJson;
  final toneName = tone == CoachingTone.noNonsense ? 'no_nonsense' : 'encouraging';
  return CoachingStrings.fromJson(bundle, tone: toneName);
});
