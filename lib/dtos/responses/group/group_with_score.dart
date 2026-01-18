
import 'package:hoop/dtos/responses/group/groups.dart';

class GroupWithScore {
  final Group group;
  final double matchScore;
  final double distanceKm;

  GroupWithScore({
    required this.group,
    required this.matchScore,
    required this.distanceKm,
  });

  factory GroupWithScore.fromJson(Map<String, dynamic> json) {
    return GroupWithScore(
      group: Group.fromJson(json['group'] ?? {}),
      matchScore: (json['matchScore'] ?? 0).toDouble(),
      distanceKm: (json['distanceKm'] ?? 0).toDouble(),
    );
  }
}
