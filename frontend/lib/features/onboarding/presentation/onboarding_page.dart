import 'package:flutter/material.dart';
import 'package:gym_app/core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:gym_app/core/strings/coaching.dart';
import 'package:gym_app/core/state/app_state.dart';
import 'package:gym_app/core/widgets/common.dart';
import 'package:gym_app/features/plan/state/plan_notifier.dart';

/// Full-screen, no-chrome onboarding flow (TES-6 §3.1).
/// Collects just enough to generate a first plan, then routes to Today.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  int _step = 0; // 0 welcome, 1 goal, 2 experience, 3 weight, 4 muscle, 5 kit, 6 generating
  String? _goal;
  String? _experience;
  String? _weight;
  final Set<String> _muscles = {};
  int _days = 3;
  String _kit = 'Both';

  void _next() => setState(() => _step++);
  void _back() => setState(() => _step--);

  void _finishLater() {
    ref.read(onboardingDoneProvider.notifier).state = true;
    context.go('/');
  }

  void _buildPlan() {
    ref.read(onboardingDoneProvider.notifier).state = true;
    ref.read(planNotifierProvider.notifier).generatePlan();
    setState(() => _step = 6);
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(coachingStringsProvider);

    // When generation completes, leave onboarding for Today.
    ref.listen(planNotifierProvider, (_, next) {
      if (next is AsyncData && next.value != null && _step == 6) {
        context.go('/');
      }
    });

    switch (_step) {
      case 0:
        return _Welcome(
          strings: strings,
          onStart: _next,
          onLater: _finishLater,
        );
      case 1:
        return _ChoiceStep(
          title: strings.goalTitle,
          helper: strings.goalHelper,
          options: strings.goals,
          selected: _goal,
          onSelect: (v) => setState(() => _goal = v),
          onBack: _back,
          onNext: _next,
        );
      case 2:
        return _ChoiceStep(
          title: strings.experienceTitle,
          options: strings.experiences,
          selected: _experience,
          onSelect: (v) => setState(() => _experience = v),
          onBack: _back,
          onNext: _next,
        );
      case 3:
        return _ChoiceStep(
          title: strings.weightTitle,
          helper: strings.weightHelper,
          options: strings.weightOptions,
          selected: _weight,
          onSelect: (v) => setState(() => _weight = v),
          onBack: _back,
          onNext: _next,
        );
      case 4:
        return _MultiChoiceStep(
          title: strings.muscleTitle,
          helper: strings.muscleHelper,
          options: strings.muscleOptions,
          selected: _muscles,
          onToggle: (v) => setState(() {
            if (_muscles.contains(v)) {
              _muscles.remove(v);
            } else {
              _muscles.add(v);
            }
          }),
          onBack: _back,
          onNext: _next,
        );
      case 5:
        return _KitStep(
          strings: strings,
          days: _days,
          kit: _kit,
          onDays: (v) => setState(() => _days = v),
          onKit: (v) => setState(() => _kit = v),
          onBack: _back,
          onBuild: _buildPlan,
        );
      default:
        return _Generating(strings: strings);
    }
  }
}

class _Welcome extends StatelessWidget {
  const _Welcome({
    required this.strings,
    required this.onStart,
    required this.onLater,
  });

  final CoachingStrings strings;
  final VoidCallback onStart;
  final VoidCallback onLater;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Scaffold(
      backgroundColor: AppTheme.bg,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Spacer(flex: 2),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Train in the Gym — Your Pocket Trainer',
                style: TextStyle(color: Color(0xFFE8C547), fontSize: 13, letterSpacing: 1.5, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                strings.welcomeHeadline,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                strings.welcomeSub,
                style: const TextStyle(color: AppTheme.mut, fontSize: 15),
              ),
            ),
            const Spacer(flex: 3),
            FilledButton(
              onPressed: onStart,
              child: Text(strings.welcomeCta),
            ),
            TextButton(
              onPressed: onLater,
              child: Text(strings.welcomeLater),
            ),
          ],
        ),
      ),
        ),
      ),
    );
  }
}

class _ChoiceStep extends StatelessWidget {
  const _ChoiceStep({
    required this.title,
    this.helper,
    required this.options,
    required this.selected,
    required this.onSelect,
    required this.onBack,
    required this.onNext,
  });

  final String title;
  final String? helper;
  final List<String> options;
  final String? selected;
  final ValueChanged<String> onSelect;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            if (helper != null) ...[
              const SizedBox(height: 6),
              Text(helper!, style: const TextStyle(color: AppTheme.mut)),
            ],
            const SizedBox(height: 20),
            for (final opt in options) ...[
              SelectionChip(
                label: opt,
                selected: selected == opt,
                onTap: () => onSelect(opt),
              ),
              const SizedBox(height: 10),
            ],
            const Spacer(),
            FilledButton(
              onPressed: selected == null ? null : onNext,
              child: const Text('Next'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MultiChoiceStep extends StatelessWidget {
  const _MultiChoiceStep({
    required this.title,
    this.helper,
    required this.options,
    required this.selected,
    required this.onToggle,
    required this.onBack,
    required this.onNext,
  });

  final String title;
  final String? helper;
  final List<String> options;
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            if (helper != null) ...[
              const SizedBox(height: 6),
              Text(helper!, style: const TextStyle(color: AppTheme.mut)),
            ],
            const SizedBox(height: 20),
            for (final opt in options) ...[
              SelectionChip(
                label: opt,
                selected: selected.contains(opt),
                onTap: () => onToggle(opt),
              ),
              const SizedBox(height: 10),
            ],
            const Spacer(),
            FilledButton(
              onPressed: selected.isEmpty ? null : onNext,
              child: const Text('Next'),
            ),
          ],
        ),
      ),
    );
  }
}

class _KitStep extends StatelessWidget {
  const _KitStep({
    required this.strings,
    required this.days,
    required this.kit,
    required this.onDays,
    required this.onKit,
    required this.onBack,
    required this.onBuild,
  });

  final CoachingStrings strings;
  final int days;
  final String kit;
  final ValueChanged<int> onDays;
  final ValueChanged<String> onKit;
  final VoidCallback onBack;
  final VoidCallback onBuild;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: onBack),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(strings.kitTitle, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 24),
            Text(strings.daysQuestion,
                style: const TextStyle(fontSize: 15)),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: days.toDouble(),
                    min: 2,
                    max: 6,
                    divisions: 4,
                    label: '$days',
                    onChanged: (v) => onDays(v.round()),
                  ),
                ),
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.outlineVariant),
                  ),
                  child: Text('$days', style: const TextStyle(fontSize: 18)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            for (final opt in strings.kitOptions) ...[
              SelectionChip(
                label: opt,
                selected: kit == opt,
                onTap: () => onKit(opt),
              ),
              const SizedBox(height: 10),
            ],
            const Spacer(),
            FilledButton(
              onPressed: onBuild,
              child: const Text('Build my plan'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Generating extends StatelessWidget {
  const _Generating({required this.strings});

  final CoachingStrings strings;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              strings.generatingTitle,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            const LoadingShimmer(height: 56),
            const LoadingShimmer(height: 56),
            const LoadingShimmer(height: 56),
            const SizedBox(height: 24),
            _RotatingLine(strings: strings),
          ],
        ),
      ),
    );
  }
}

class _RotatingLine extends StatefulWidget {
  const _RotatingLine({required this.strings});

  final CoachingStrings strings;

  @override
  State<_RotatingLine> createState() => _RotatingLineState();
}

class _RotatingLineState extends State<_RotatingLine> {
  late int _idx = 0;
  late final List<String> _lines = widget.strings.generatingLines;

  @override
  void initState() {
    super.initState();
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return false;
      setState(() => _idx = (_idx + 1) % _lines.length);
      return true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _lines[_idx],
      style: const TextStyle(color: AppTheme.mut),
      textAlign: TextAlign.center,
    );
  }
}
