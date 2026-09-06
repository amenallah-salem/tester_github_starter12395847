import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:gym_app/core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:gym_app/core/strings/coaching.dart';
import 'package:gym_app/core/widgets/common.dart';
import 'package:gym_app/features/plan/data/sample_plan.dart';
import 'package:gym_app/features/plan/domain/plan_contract.dart';
import 'package:gym_app/features/plan/state/plan_notifier.dart';
import 'package:gym_app/features/progress/domain/workout_session.dart';
import 'package:gym_app/features/progress/state/workout_sessions.dart';
import 'package:gym_app/features/plan_runner/presentation/timer_widget.dart';
import 'package:gym_app/services/api_client.dart';

enum _Phase { work, rest, finished }

/// Full-screen modal Plan Runner with set/rest timers (TES-6 §3.3).
/// Hides the tab bar (it is a top-level route) and disables system back
/// mid-set to avoid accidental exits.
class PlanRunnerPage extends ConsumerStatefulWidget {
  const PlanRunnerPage({this.scheduledDate, this.initialExercises, super.key});

  final DateTime? scheduledDate;
  final List<PlanExercise>? initialExercises;

  @override
  ConsumerState<PlanRunnerPage> createState() => _PlanRunnerPageState();
}

class _PlanRunnerPageState extends ConsumerState<PlanRunnerPage> {
  late List<PlanExercise> _exercises;
  int _exIndex = 0;
  int _setIndex = 0; // 0-based current set within the exercise
  _Phase _phase = _Phase.work;
  int _workRemaining = 0;
  int _restRemaining = 0;
  int _repsAdj = 0;
  bool _running = false;
  Timer? _timer;
  String _coach = '';
  bool _finished = false;
  final List<Map<String, Object?>> _loggedSets = [];
  final _weightController = TextEditingController();
  final _durationController = TextEditingController();
  late final DateTime _sessionStartedAt;
  String? _remoteSessionId;
  bool _loggingSet = false;

  PlanExercise get _ex => _exercises[_exIndex];

  static int _workSeconds(PlanExercise e) =>
      (_parseReps(e.reps) * 4).clamp(15, 90).toInt();

  /// The contract stores reps as a display string (e.g. "8-10", "12"). For the
  /// work-phase countdown we take the leading integer target.
  static int _parseReps(String reps) {
    final m = RegExp(r'\d+').firstMatch(reps);
    return m == null ? 10 : int.parse(m.group(0)!);
  }

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    final plan = ref.read(planNotifierProvider).value ?? samplePlan;
    _exercises = widget.initialExercises ?? plan.todaySession.exercises;
    _sessionStartedAt = DateTime.now();
    _enterExercise(announce: true);
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WakelockPlus.disable();
    _weightController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _enterExercise({bool announce = false}) {
    _setIndex = 0;
    _phase = _Phase.work;
    _workRemaining = _workSeconds(_ex);
    _repsAdj = _parseReps(_ex.reps);
    _weightController.clear();
    _durationController.clear();
    _prefillWeight();
    if (announce) {
      _coach = ref.read(coachingStringsProvider).startCue(_ex.name, _setIndex);
    }
  }

  Future<void> _prefillWeight() async {
    if (ApiClient.I.accessToken == null || _ex.exerciseId.isEmpty) return;
    try {
      final metric =
          await ApiClient.I.fetchLastMetricForExercise(_ex.exerciseId);
      if (!mounted || metric == null) return;
      final weight = metric['weight_kg'];
      if (weight != null) {
        _weightController.text = weight.toString();
      }
    } on ApiException catch (error) {
      debugPrint('Unable to prefill last set: $error');
    }
  }

  void _startTimer() {
    if (_running || _finished) return;
    setState(() => _running = true);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  void _pause() {
    _timer?.cancel();
    setState(() {
      _running = false;
      _coach = ref.read(coachingStringsProvider).pausedCue;
    });
  }

  void _onTick() {
    if (!mounted) return;
    setState(() {
      if (_phase == _Phase.work) {
        if (_workRemaining > 1) {
          _workRemaining--;
          if (_workRemaining == _workSeconds(_ex) - 1) {
            final s = ref.read(coachingStringsProvider);
            _coach = _setIndex == _ex.sets - 1
                ? s.lastSetCue
                : s.workCue(_ex.reps, _setIndex);
          }
        } else {
          _enterRest();
        }
      } else if (_phase == _Phase.rest) {
        if (_restRemaining > 1) {
          _restRemaining--;
        } else {
          _enterNextSetOrExercise();
        }
      }
    });
  }

  void _enterRest() {
    _phase = _Phase.rest;
    _restRemaining = _ex.restSec;
    _coach =
        ref.read(coachingStringsProvider).restCue('${_ex.restSec}', _setIndex);
  }

  void _enterNextSetOrExercise() {
    if (_setIndex < _ex.sets - 1) {
      _setIndex++;
      _phase = _Phase.work;
      _workRemaining = _workSeconds(_ex);
      _repsAdj = _parseReps(_ex.reps);
      _weightController.clear();
      final s = ref.read(coachingStringsProvider);
      _coach = _setIndex == _ex.sets - 1
          ? s.lastSetCue
          : s.workCue(_ex.reps, _setIndex);
    } else if (_exIndex < _exercises.length - 1) {
      _exIndex++;
      _enterExercise(announce: true);
    } else {
      _finish();
    }
  }

  Future<void> _doneSet() async {
    if (_finished) return;
    final completedSet = _setIndex + 1;
    final weight = double.tryParse(_weightController.text.trim());
    final duration = int.tryParse(_durationController.text.trim());
    if (_ex.isTimed && (duration == null || duration <= 0)) return;
    if (weight != null && weight < 0) return;
    final completed = <String, Object?>{
      'exercise': _ex.name,
      'set': completedSet,
      'reps': _repsAdj,
      'weight': weight,
      'duration': _ex.isTimed ? duration : null,
    };
    setState(() => _loggingSet = true);
    try {
      await _logSetRemotely(completed);
    } finally {
      if (mounted) setState(() => _loggingSet = false);
    }
    if (!mounted) return;
    _loggedSets.add(completed);
    setState(() {
      if (_phase == _Phase.work) {
        _enterRest();
      } else {
        _enterNextSetOrExercise();
      }
    });
    final s = ref.read(coachingStringsProvider);
    _coach = s.setDoneCue(completedSet, _setIndex);
  }

  Future<void> _logSetRemotely(Map<String, Object?> set) async {
    if (ApiClient.I.accessToken == null) return;
    try {
      _remoteSessionId ??= (await ApiClient.I.createWorkout(
        name: (ref.read(planNotifierProvider).value ?? samplePlan)
            .todaySession
            .dayLabel,
        notes: 'Workout in progress.',
        scheduledFor: widget.scheduledDate,
      ))['id']
          ?.toString();
      final sessionId = _remoteSessionId;
      if (sessionId == null) {
        throw StateError('The workout session could not be created.');
      }
      final result = await ApiClient.I.logWorkoutMetric(
        sessionId: sessionId,
        exerciseName: set['exercise']! as String,
        setNumber: set['set']! as int,
        reps: set['reps']! as int,
        weightKg: set['weight'] as double?,
        durationSeconds: set['duration'] as int?,
      );
      if (result?['is_new_personal_record'] == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('New personal record!')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Set was not saved: $error')),
        );
      }
      rethrow;
    }
  }

  Future<void> _skip() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Skip this set?'),
        content: Text(ref.read(coachingStringsProvider).skipConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(c).pop(true),
            child: const Text('Skip'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    if (_exIndex < _exercises.length - 1) {
      _exIndex++;
      setState(() => _enterExercise(announce: true));
    } else {
      _finish();
    }
  }

  void _finish() {
    _timer?.cancel();
    WakelockPlus.disable();
    setState(() {
      _finished = true;
      _phase = _Phase.finished;
    });
    final plan = ref.read(planNotifierProvider).value ?? samplePlan;
    final finishedAt = DateTime.now();
    final durationSeconds =
        finishedAt.difference(_sessionStartedAt).inSeconds.clamp(0, 86400);
    final volumeKg = _loggedSets.fold<double>(
      0,
      (sum, set) =>
          sum + ((set['weight'] as double?) ?? 0) * (set['reps'] as int),
    );
    ref.read(workoutSessionsProvider.notifier).add(WorkoutSession(
          date: _sessionStartedAt,
          name: plan.todaySession.dayLabel,
          exerciseCount: _exercises.length,
          setCount: _loggedSets.length,
          minutes: (durationSeconds / 60).ceil(),
          exerciseNames: _exercises.map((e) => e.name).toList(),
          durationSeconds: durationSeconds,
          volumeKg: volumeKg,
          finishedAt: finishedAt,
        ));
    unawaited(_persistWorkout(finishedAt));
    ref.invalidate(progressMetricsProvider);
  }

  Future<void> _persistWorkout(DateTime finishedAt) async {
    if (ApiClient.I.accessToken == null) return;
    try {
      if (_remoteSessionId != null) {
        await ApiClient.I.finishWorkout(
          sessionId: _remoteSessionId!,
          finishedAt: finishedAt,
        );
        return;
      }
      final plan = ref.read(planNotifierProvider).value ?? samplePlan;
      final session = await ApiClient.I.createWorkout(
        name: plan.todaySession.dayLabel,
        notes: 'Completed in the workout runner.',
        scheduledFor: widget.scheduledDate,
      );
      final sessionId = session['id']?.toString();
      if (sessionId == null) return;
      for (final set in _loggedSets) {
        await ApiClient.I.logWorkoutMetric(
          sessionId: sessionId,
          exerciseName: set['exercise']! as String,
          setNumber: set['set']! as int,
          reps: set['reps']! as int,
          weightKg: set['weight'] as double?,
        );
      }
      await ApiClient.I.finishWorkout(
        sessionId: sessionId,
        finishedAt: finishedAt,
      );
    } on ApiException {
      await ApiClient.I.queueWorkout(
        name: (ref.read(planNotifierProvider).value ?? samplePlan)
            .todaySession
            .dayLabel,
        notes: 'Completed offline in the workout runner.',
        metrics: _loggedSets
            .map((set) => {
                  'exercise': set['exercise'],
                  'set': set['set'],
                  'reps': set['reps'],
                  'weight': set['weight'],
                })
            .toList(),
      );
    }
  }

  int get _totalSets => _exercises.fold(0, (sum, e) => sum + e.sets);

  double get _overallProgress {
    int done = 0;
    for (var i = 0; i < _exIndex; i++) {
      done += _exercises[i].sets;
    }
    done += _setIndex;
    return _totalSets == 0 ? 0 : done / _totalSets;
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(coachingStringsProvider);

    if (_finished) {
      return _CompleteScreen(
        strings: strings,
        exerciseCount: _exercises.length,
        setCount: _totalSets,
        minutes: ((DateTime.now().difference(_sessionStartedAt).inSeconds) / 60)
            .ceil(),
      );
    }

    final isWork = _phase == _Phase.work;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, __) {
        // System back disabled mid-set; the Exit button leaves intentionally.
      },
      child: Scaffold(
        backgroundColor: AppTheme.bg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          automaticallyImplyLeading: false,
          title: Text(
            'Set ${_setIndex + 1} of ${_ex.sets} · Ex ${_exIndex + 1} of ${_exercises.length}',
            style: const TextStyle(fontSize: 13, color: AppTheme.mut),
          ),
          actions: [
            TextButton(
              onPressed: () => context.go('/'),
              child: const Text('Exit'),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.outlineVariant),
                ),
                child: Center(
                  child: Text(
                    _ex.name.isNotEmpty ? _ex.name[0] : '?',
                    style: const TextStyle(
                        fontSize: 28, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _ex.name,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            CountdownDial(
              remaining: isWork ? _workRemaining : _restRemaining,
              total: isWork ? _workSeconds(_ex) : _ex.restSec,
              label: isWork ? 'Work' : 'Rest',
            ),
            const SizedBox(height: 14),
            CoachLine(_coach),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: _overallProgress,
              borderRadius: BorderRadius.circular(8),
              minHeight: 8,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => _repsAdj++),
                    icon: const Icon(Icons.add),
                    label: const Text('+1 rep'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() {
                      if (_repsAdj > 0) _repsAdj--;
                    }),
                    icon: const Icon(Icons.remove),
                    label: const Text('−1 rep'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Logged reps: $_repsAdj / ${_ex.reps}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.mut),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _durationController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Duration (seconds)',
                hintText: 'Required for timed exercises',
                prefixIcon: Icon(Icons.timer_outlined),
              ),
              enabled: _ex.isTimed,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _weightController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Weight (kg)',
                hintText: 'Optional',
                prefixIcon: Icon(Icons.fitness_center_outlined),
              ),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: _running ? _pause : _startTimer,
              icon: Icon(_running ? Icons.pause : Icons.play_arrow),
              label: Text(_running ? 'Pause' : 'Start'),
            ),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: _loggingSet ? null : _doneSet,
              child: Text(strings.doneSet),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: _skip,
              child: const Text('Skip'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompleteScreen extends StatelessWidget {
  const _CompleteScreen({
    required this.strings,
    required this.exerciseCount,
    required this.setCount,
    required this.minutes,
  });

  final CoachingStrings strings;
  final int exerciseCount;
  final int setCount;
  final int minutes;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events_outlined,
                size: 64, color: AppTheme.secondary),
            const SizedBox(height: 16),
            Text(
              strings.sessionDone,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              strings.sessionSummary(exerciseCount, setCount, minutes),
              style: const TextStyle(color: AppTheme.mut),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  strings.sessionSummary(exerciseCount, setCount, minutes),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go('/recovery'),
              child: Text(strings.seeProgress),
            ),
            OutlinedButton.icon(
              onPressed: () => context.go('/progress'),
              icon: const Icon(Icons.insights_outlined),
              label: const Text('See progress'),
            ),
            TextButton(
              onPressed: () => context.go('/'),
              child: Text(strings.done),
            ),
          ],
        ),
      ),
    );
  }
}
