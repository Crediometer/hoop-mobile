
import 'package:hoop/dtos/responses/group/Groups.dart';
import 'package:hoop/dtos/responses/group/group_member.dart';
import 'package:hoop/dtos/responses/group/group_stats.dart';

class GroupDetailsPublic {
  final Group group;
  final List<GroupMember> members;
  final GroupStats? stats;

  GroupDetailsPublic({
    required this.group,
    required this.members,
    this.stats,
  });

  factory GroupDetailsPublic.fromJson(Map<String, dynamic> json) {
    return GroupDetailsPublic(
      group: Group.fromJson(json['group'] ?? {}),
      members: (json['members'] as List?)
              ?.map((item) => GroupMember.fromJson(item))
              .toList() ??
          [],
      stats: json['stats'] != null ? GroupStats.fromJson(json['stats']) : null,
    );
  }
}

