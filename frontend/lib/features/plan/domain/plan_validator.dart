import 'dart:convert';

import 'package:gym_app/features/plan/domain/plan_contract.dart';

/// Validates a raw plan JSON blob against the AI Coach contract
/// (`assets/plan_contract.schema.json`, JSON Schema 2020-12).
///
/// The Flutter app performs this check before rendering a plan so a malformed
/// or version-mismatched payload from the coach can never reach the UI. It is a
/// focused, dependency-free validation of the structural rules the schema
/// encodes (required keys, types, enum membership, ranges, and the mandatory
/// "not medical advice" disclaimer). A full JSON-Schema engine is intentionally
/// avoided to keep Milestone 1 dependency-light.
class PlanValidationException implements Exception {
  PlanValidationException(this.message);
  final String message;
  @override
  String toString() => 'PlanValidationException: $message';
}

/// Validates a JSON string and returns a parsed [WorkoutPlan], or throws
/// [PlanValidationException] describing the first failure.
WorkoutPlan validatePlanJson(String raw) {
  final dynamic decoded;
  try {
    decoded = jsonDecode(raw);
  } on FormatException catch (e) {
    throw PlanValidationException('Plan is not valid JSON: $e');
  }
  if (decoded is! Map<String, dynamic>) {
    throw PlanValidationException('Plan root must be a JSON object.');
  }
  _validate(decoded);
  return WorkoutPlan.fromJson(decoded);
}

void _validate(Map<String, dynamic> json) {
  const requiredTop = {
    'schemaVersion',
    'planId',
    'generatedAt',
    'model',
    'profile',
    'summary',
    'weeklySplit',
    'days',
    'progression',
    'safetyNotes',
    'disclaimer',
  };
  for (final key in requiredTop) {
    if (!json.containsKey(key)) {
      throw PlanValidationException('Missing required top-level field: $key');
    }
  }

  if (json['schemaVersion'] != '1.0') {
    throw PlanValidationException(
        'Unsupported schemaVersion: ${json['schemaVersion']} (expected "1.0").');
  }

  _requireType<String>(json, 'planId');
  _requireType<String>(json, 'model');
  _requireType<String>(json, 'summary');
  _requireType<String>(json, 'progression');
  _requireType<String>(json, 'disclaimer');

  // Disclaimer must include the medical-advice guardrail.
  final disclaimer = json['disclaimer'] as String;
  if (!_contains(disclaimer, 'not medical advice')) {
    throw PlanValidationException(
        'disclaimer must include "not medical advice".');
  }

  _requireType<List>(json, 'safetyNotes');
  _requireListOf<String>(json, 'safetyNotes');

  // generatedAt must parse as ISO-8601.
  try {
    DateTime.parse(json['generatedAt'] as String);
  } on FormatException {
    throw PlanValidationException('generatedAt is not a valid ISO-8601 date.');
  }

  _validateEnum<WeeklySplit>(json['weeklySplit'] as String, WeeklySplit.values,
      'weeklySplit');

  _validateProfile(json['profile'] as Object?);

  final days = json['days'];
  if (days is! List || days.isEmpty || days.length > 14) {
    throw PlanValidationException(
        'days must be a non-empty array of 1..14 items.');
  }
  for (var i = 0; i < days.length; i++) {
    _validateDay(days[i] as Object?, i);
  }
}

void _validateProfile(Object? raw) {
  if (raw is! Map<String, dynamic>) {
    throw PlanValidationException('profile must be an object.');
  }
  const required = {
    'goal',
    'experience',
    'daysPerWeek',
    'sessionMinutes',
    'equipment',
    'focusAreas',
  };
  for (final key in required) {
    if (!raw.containsKey(key)) {
      throw PlanValidationException('Missing required profile field: $key');
    }
  }
  _validateEnum<Goal>(raw['goal'] as String, Goal.values, 'profile.goal');
  _validateEnum<Experience>(
      raw['experience'] as String, Experience.values, 'profile.experience');
  _requireType<int>(raw, 'daysPerWeek');
  _requireType<int>(raw, 'sessionMinutes');
  if (raw['daysPerWeek'] is! int ||
      (raw['daysPerWeek'] as int) < 1 ||
      (raw['daysPerWeek'] as int) > 7) {
    throw PlanValidationException('profile.daysPerWeek must be 1..7.');
  }
  if (raw['sessionMinutes'] is! int ||
      (raw['sessionMinutes'] as int) < 10 ||
      (raw['sessionMinutes'] as int) > 240) {
    throw PlanValidationException('profile.sessionMinutes must be 10..240.');
  }
  _requireListOf<String>(raw, 'equipment');
  for (final e in raw['equipment'] as List) {
    _validateEnum<Equipment>(e as String, Equipment.values, 'profile.equipment');
  }
  _requireListOf<String>(raw, 'focusAreas');
  for (final f in raw['focusAreas'] as List) {
    _validateEnum<FocusArea>(f as String, FocusArea.values, 'profile.focusAreas');
  }
}

void _validateDay(Object? raw, int index) {
  if (raw is! Map<String, dynamic>) {
    throw PlanValidationException('days[$index] must be an object.');
  }
  const required = {'dayIndex', 'dayLabel', 'focus', 'blocks', 'estimatedMinutes'};
  for (final key in required) {
    if (!raw.containsKey(key)) {
      throw PlanValidationException('days[$index] missing field: $key');
    }
  }
  _requireType<int>(raw, 'dayIndex');
  _requireType<String>(raw, 'dayLabel');
  _requireType<String>(raw, 'focus');
  _requireType<int>(raw, 'estimatedMinutes');
  final dayLabel = raw['dayLabel'] as String;
  if (dayLabel.length > 12) {
    throw PlanValidationException('days[$index].dayLabel exceeds 12 chars.');
  }
  final blocks = raw['blocks'];
  if (blocks is! List || blocks.isEmpty) {
    throw PlanValidationException('days[$index].blocks must be a non-empty array.');
  }
  for (var b = 0; b < blocks.length; b++) {
    _validateBlock(blocks[b] as Object?, index, b);
  }
}

void _validateBlock(Object? raw, int dayIndex, int blockIndex) {
  if (raw is! Map<String, dynamic>) {
    throw PlanValidationException('days[$dayIndex].blocks[$blockIndex] must be an object.');
  }
  if (!raw.containsKey('blockType') || !raw.containsKey('exercises')) {
    throw PlanValidationException(
        'days[$dayIndex].blocks[$blockIndex] needs blockType and exercises.');
  }
  _validateEnum<BlockType>(raw['blockType'] as String, BlockType.values,
      'days[$dayIndex].blocks[$blockIndex].blockType');
  final exercises = raw['exercises'];
  if (exercises is! List || exercises.isEmpty) {
    throw PlanValidationException(
        'days[$dayIndex].blocks[$blockIndex].exercises must be a non-empty array.');
  }
  final bt = raw['blockType'] as String;
  if ((bt == 'superset' || bt == 'circuit' || bt == 'amrap') &&
      (raw['rounds'] is! int)) {
    throw PlanValidationException(
        'days[$dayIndex].blocks[$blockIndex] ($bt) requires integer rounds.');
  }
  for (var e = 0; e < exercises.length; e++) {
    _validateExercise(exercises[e] as Object?, dayIndex, blockIndex, e);
  }
}

void _validateExercise(
    Object? raw, int dayIndex, int blockIndex, int exIndex) {
  if (raw is! Map<String, dynamic>) {
    throw PlanValidationException(
        'days[$dayIndex].blocks[$blockIndex].exercises[$exIndex] must be an object.');
  }
  const required = {
    'exerciseId',
    'name',
    'equipment',
    'muscleGroups',
    'sets',
    'reps',
    'restSec',
  };
  for (final key in required) {
    if (!raw.containsKey(key)) {
      throw PlanValidationException(
          'exercise missing field: $key (days[$dayIndex].blocks[$blockIndex].exercises[$exIndex]).');
    }
  }
  _requireType<String>(raw, 'exerciseId');
  _requireType<String>(raw, 'name');
  _requireType<int>(raw, 'sets');
  _requireType<String>(raw, 'reps');
  _requireType<int>(raw, 'restSec');
  if (raw['sets'] is! int || (raw['sets'] as int) < 1 || (raw['sets'] as int) > 20) {
    throw PlanValidationException(
        'exercise.sets must be 1..20 (days[$dayIndex].blocks[$blockIndex].ex[$exIndex]).');
  }
  if (raw['restSec'] is! int ||
      (raw['restSec'] as int) < 0 ||
      (raw['restSec'] as int) > 1200) {
    throw PlanValidationException(
        'exercise.restSec must be 0..1200 (days[$dayIndex].blocks[$blockIndex].ex[$exIndex]).');
  }
  _validateEnum<Equipment>(raw['equipment'] as String, Equipment.values,
      'exercise.equipment');
  _requireListOf<String>(raw, 'muscleGroups');
  for (final m in raw['muscleGroups'] as List) {
    _validateEnum<FocusArea>(
        m as String, FocusArea.values, 'exercise.muscleGroups');
  }
}

void _requireType<T>(Map<String, dynamic> json, String key) {
  if (json[key] is! T) {
    throw PlanValidationException('Field "$key" must be of type $T.');
  }
}

void _requireListOf<T>(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! List) {
    throw PlanValidationException('Field "$key" must be a list.');
  }
  if (value.any((e) => e is! T)) {
    throw PlanValidationException('Field "$key" must be a list of $T.');
  }
}

void _validateEnum<T extends Enum>(String value, List<T> values, String field) {
  if (values.every((v) => v.name != value)) {
    throw PlanValidationException(
        '$field has invalid value "$value". Allowed: '
        '${values.map((v) => v.name).join(', ')}.');
  }
}

bool _contains(String haystack, String needle) =>
    haystack.toLowerCase().contains(needle.toLowerCase());
