
import 'package:hoop/dtos/responses/group/Groups.dart';

class GroupWithScore {
  final Group group;
  final double matchScore;

  GroupWithScore({
    required this.group,
    required this.matchScore,
  });

  factory GroupWithScore.fromJson(Map<String, dynamic> json) {
    return GroupWithScore(
      group: Group.fromJson(json['group'] ?? {}),
      matchScore: (json['matchScore'] ?? 0).toDouble(),
    );
  }
}
