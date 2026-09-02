import 'package:flutter/material.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Onboarding')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Welcome to AIGym',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text(
              'Set your fitness goals, build weekly plans, log workouts, and track progress.',
              style: TextStyle(fontSize: 16),
            ),
            const Spacer(),
            const Center(child: Text('Use the bottom navigation to explore.')),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
