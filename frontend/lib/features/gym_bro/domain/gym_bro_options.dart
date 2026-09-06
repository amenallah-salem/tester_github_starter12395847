/// Fixed choice lists for the Gym Bro training profile (GB-1).
/// Values must match `Profile.GOAL_CHOICES` / `Profile.EXPERIENCE_CHOICES`
/// on the backend exactly, since they're sent as-is in the PATCH payload.
library;

const List<MapEntry<String, String>> gymBroGoalOptions = [
  MapEntry('strength', 'Strength'),
  MapEntry('cardio', 'Cardio'),
  MapEntry('general_fitness', 'General fitness'),
  MapEntry('hypertrophy', 'Hypertrophy'),
  MapEntry('weight_loss', 'Weight loss'),
  MapEntry('flexibility', 'Flexibility & mobility'),
];

const List<MapEntry<String, String>> gymBroExperienceOptions = [
  MapEntry('beginner', 'Beginner'),
  MapEntry('intermediate', 'Intermediate'),
  MapEntry('advanced', 'Advanced'),
];

String gymBroGoalLabel(String value) => gymBroGoalOptions
    .firstWhere(
      (e) => e.key == value,
      orElse: () => MapEntry(value, value),
    )
    .value;

String gymBroExperienceLabel(String value) => gymBroExperienceOptions
    .firstWhere(
      (e) => e.key == value,
      orElse: () => MapEntry(value, value),
    )
    .value;
