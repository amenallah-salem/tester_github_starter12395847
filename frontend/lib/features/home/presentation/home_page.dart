import 'package:flutter/material.dart';
import 'package:gym_app/core/theme/app_theme.dart';
import 'package:go_router/go_router.dart';

import 'package:gym_app/core/widgets/common.dart';

/// Welora's five-destination app shell.
class HomePage extends StatelessWidget {
  const HomePage({required this.child, required this.location, super.key});

  final Widget child;
  final String location;

  static const _tabs = [
    _Tab('/', Icons.home_outlined, 'Home'),
    _Tab('/explorer', Icons.fitness_center_outlined, 'Workouts'),
    _Tab('/coach', Icons.groups_outlined, 'Train'),
    _Tab('/progress', Icons.show_chart_outlined, 'Progress'),
    _Tab('/you', Icons.person_outline, 'More'),
  ];

  int _indexFor(String location) {
    final idx = _tabs.indexWhere((t) => location == t.path || location.startsWith('${t.path}/'));
    return idx == -1 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    final current = _indexFor(location);
    return mobileWrap(Scaffold(
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              boxShadow: AppTheme.cardShadow,
            ),
            child: NavigationBar(
              selectedIndex: current,
              onDestinationSelected: (i) => context.go(_tabs[i].path),
              height: 68,
              backgroundColor: Colors.transparent,
              indicatorColor: AppTheme.primaryContainer,
              destinations: _tabs
                  .map(
                    (t) => NavigationDestination(
                      icon: Icon(t.icon),
                      selectedIcon: Icon(t.icon),
                      label: t.label,
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
    ));
  }
}

class _Tab {
  const _Tab(this.path, this.icon, this.label);
  final String path;
  final IconData icon;
  final String label;
}
