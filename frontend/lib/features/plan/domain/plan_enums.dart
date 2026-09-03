// Enums shared across the plan contract. Names match the JSON contract values
// exactly (lowercase snake_case where applicable) so (de)serialization is a
// direct `.name` mapping.

enum Goal { hypertrophy, strength, fatloss, endurance, general }

enum Experience { beginner, intermediate, advanced }

enum Equipment {
  barbell,
  dumbbell,
  kettlebell,
  machine,
  cable,
  bodyweight,
  resistanceBand,
}

enum FocusArea {
  chest,
  back,
  legs,
  shoulders,
  arms,
  core,
  fullBody,
  cardio,
}

enum WeeklySplit {
  fullBody,
  upperLower,
  pushPullLegs,
  bodyPartSplit,
  custom,
}

enum BlockType { straight, superset, circuit, amrap, rest }
