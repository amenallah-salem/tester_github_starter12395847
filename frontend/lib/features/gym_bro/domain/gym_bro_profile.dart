/// A candidate profile shown in the Gym Bro discovery feed (GB-2).
class GymBroProfile {
  const GymBroProfile({
    required this.userId,
    required this.username,
    required this.displayName,
    required this.bio,
    required this.trainingGoals,
    required this.experienceLevel,
    required this.availability,
    required this.location,
  });

  final String userId;
  final String username;
  final String displayName;
  final String bio;
  final List<String> trainingGoals;
  final String experienceLevel;
  final String availability;
  final String location;

  factory GymBroProfile.fromJson(Map<String, dynamic> json) {
    final user = (json['user'] as Map?)?.cast<String, dynamic>() ?? const {};
    final displayName = (json['display_name'] as String?) ?? '';
    return GymBroProfile(
      userId: user['id'].toString(),
      username: (user['username'] as String?) ?? '',
      displayName: displayName.isNotEmpty
          ? displayName
          : (user['username'] as String?) ?? 'Gym Bro',
      bio: (json['bio'] as String?) ?? '',
      trainingGoals:
          (json['training_goals'] as List?)?.cast<String>() ?? const [],
      experienceLevel: (json['experience_level'] as String?) ?? '',
      availability: (json['availability'] as String?) ?? '',
      location: (json['location'] as String?) ?? '',
    );
  }
}
