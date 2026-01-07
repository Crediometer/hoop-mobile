
// lib/models/group_invite.dart
import 'package:hoop/dtos/responses/User.dart';
import 'package:hoop/dtos/responses/group/Groups.dart';

class GroupInvite {
  final String id;
  final String groupId;
  final String? email;
  final String? phone;
  final String status;
  final String invitedBy;
  final String createdAt;
  final String? respondedAt;
  final String? response;
  final Group? group;
  final User? inviter;

  GroupInvite({
    required this.id,
    required this.groupId,
    this.email,
    this.phone,
    required this.status,
    required this.invitedBy,
    required this.createdAt,
    this.respondedAt,
    this.response,
    this.group,
    this.inviter,
  });

  factory GroupInvite.fromJson(Map<String, dynamic> json) {
    return GroupInvite(
      id: json['id'] ?? '',
      groupId: json['groupId'] ?? '',
      email: json['email'],
      phone: json['phone'],
      status: json['status'] ?? 'pending',
      invitedBy: json['invitedBy'] ?? '',
      createdAt: json['createdAt'] ?? '',
      respondedAt: json['respondedAt'],
      response: json['response'],
      group: json['group'] != null ? Group.fromJson(json['group']) : null,
      inviter: json['inviter'] != null ? User.fromJson(json['inviter']) : null,
    );
  }
}

