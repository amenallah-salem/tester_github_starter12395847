import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pages/onboarding.dart';
import 'pages/plan.dart';
import 'pages/workout.dart';
import 'pages/stats.dart';
import 'services/api_client.dart';

void main() {
  runApp(const GymPlannerApp());
}

class GymPlannerApp extends StatelessWidget {
  const GymPlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiClient>(
          create: (_) => ApiClient(baseUrl: 'http://localhost:8080'),
        ),
      ],
      child: MaterialApp(
        title: 'Gym Planner (T-17)',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
          ),
        ),
        home: const MainNavigation(),
      ),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _index = 0;
  final _pages = [
    const OnboardingPage(),
    const PlanPage(),
    const WorkoutPage(),
    const StatsPage(),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.flag), label: 'Onboarding'),
          NavigationDestination(icon: Icon(Icons.list), label: 'Plan'),
          NavigationDestination(icon: Icon(Icons.fitness_center), label: 'Workout'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Stats'),
        ],
      ),
    );
  }
}
