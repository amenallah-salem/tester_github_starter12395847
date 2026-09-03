import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:gym_app/core/widgets/common.dart';

/// Bottom tab host for the post-plan app. Three tabs per TES-6 §2:
/// Today (plan) / Progress / You. The Plan Runner and Exercise Detail are
/// full-screen routes outside this shell, so the tab bar is hidden there.
class HomePage extends StatelessWidget {
  const HomePage({required this.child, required this.location, super.key});

  final Widget child;
  final String location;

  static const _tabs = [
    _Tab('/', Icons.today_outlined, 'Today'),
    _Tab('/progress', Icons.show_chart_outlined, 'Progress'),
    _Tab('/you', Icons.person_outline, 'You'),
  ];

  int _indexFor(String location) {
    final idx = _tabs.indexWhere((t) => t.path == location);
    return idx == -1 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    final current = _indexFor(location);
    return Scaffold(
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: current,
        onTap: (i) => context.go(_tabs[i].path),
        items: _tabs
            .map(
              (t) => BottomNavigationBarItem(
                icon: Icon(t.icon),
                label: t.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _Tab {
  const _Tab(this.path, this.icon, this.label);
  final String path;
  final IconData icon;
  final String label;
}
