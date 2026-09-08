import 'package:gym_app/features/gym_bro/domain/gym_bro_profile.dart';

/// A mutual Gym Bro match (GB-3), pairing this user with [profile].
class GymBroMatch {
  const GymBroMatch({
    required this.id,
    required this.profile,
    required this.createdAt,
  });

  final String id;
  final GymBroProfile profile;
  final DateTime? createdAt;

  factory GymBroMatch.fromJson(Map<String, dynamic> json) {
    return GymBroMatch(
      id: json['id'].toString(),
      profile: GymBroProfile.fromJson(
        (json['profile'] as Map).cast<String, dynamic>(),
      ),
      createdAt: DateTime.tryParse((json['created_at'] as String?) ?? ''),
    );
  }
}

/// A single chat message within a match (GB-4).
class GymBroChatMessage {
  const GymBroChatMessage({
    required this.id,
    required this.senderId,
    required this.senderUsername,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String senderId;
  final String senderUsername;
  final String text;
  final DateTime? createdAt;

  factory GymBroChatMessage.fromJson(Map<String, dynamic> json) {
    final sender = (json['sender'] as Map?)?.cast<String, dynamic>() ?? const {};
    return GymBroChatMessage(
      id: json['id'].toString(),
      senderId: sender['id'].toString(),
      senderUsername: (sender['username'] as String?) ?? '',
      text: (json['text'] as String?) ?? '',
      createdAt: DateTime.tryParse((json['created_at'] as String?) ?? ''),
    );
  }
}
