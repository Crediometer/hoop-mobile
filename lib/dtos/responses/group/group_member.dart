
// lib/models/group_member.dart
import 'package:hoop/dtos/responses/User.dart';

class GroupMember {
  final String id;
  final String userId;
  final String groupId;
  final String role;
  final String status;
  final String joinedAt;
  final String? leftAt;
  final User? user;

  GroupMember({
    required this.id,
    required this.userId,
    required this.groupId,
    required this.role,
    required this.status,
    required this.joinedAt,
    this.leftAt,
    this.user,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      groupId: json['groupId'] ?? '',
      role: json['role'] ?? 'member',
      status: json['status'] ?? 'active',
      joinedAt: json['joinedAt'] ?? '',
      leftAt: json['leftAt'],
      user: json['user'] != null ? User.fromJson(json['user']) : null,
    );
  }
}
