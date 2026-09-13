import 'package:flutter/material.dart';

class MeditationSession {
  MeditationSession({
    this.id,
    required this.category,
    required this.durationMinutes,
    required this.completedAt,
  });

  final String? id;
  final String category;
  final int durationMinutes;
  final DateTime completedAt;

  factory MeditationSession.fromJson(Map<String, dynamic> json) {
    return MeditationSession(
      id: json['id']?.toString(),
      category: (json['category'] ?? '') as String,
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 0,
      completedAt: DateTime.tryParse(json['completed_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

/// A guided-meditation category shown on the Meditation section. Matches
/// `MeditationSession.CATEGORY_CHOICES` in the backend (`gym_api/models.py`)
/// — keep the `key` values in sync with that list.
class MeditationCategory {
  const MeditationCategory({
    required this.key,
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
  });

  final String key;
  final String label;
  final String description;
  final IconData icon;
  final Color color;
}

const meditationCategories = [
  MeditationCategory(
    key: 'sleep',
    label: 'Sleep',
    description: 'Wind down before bed',
    icon: Icons.bedtime_outlined,
    color: Color(0xFFE8EAF6),
  ),
  MeditationCategory(
    key: 'stress_relief',
    label: 'Stress relief',
    description: 'Release tension',
    icon: Icons.spa_outlined,
    color: Color(0xFFE0F2F1),
  ),
  MeditationCategory(
    key: 'focus',
    label: 'Focus',
    description: 'Sharpen concentration',
    icon: Icons.center_focus_strong_outlined,
    color: Color(0xFFFFF8E1),
  ),
  MeditationCategory(
    key: 'body_scan',
    label: 'Body scan',
    description: 'Notice and release',
    icon: Icons.accessibility_new_outlined,
    color: Color(0xFFFCE4EC),
  ),
  MeditationCategory(
    key: 'breathing',
    label: 'Breathing',
    description: 'Guided breath work',
    icon: Icons.air_outlined,
    color: Color(0xFFE8F5F5),
  ),
];

const meditationDurationOptionsMinutes = [5, 10, 15, 20];
