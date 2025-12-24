
import 'package:hoop/dtos/responses/User.dart';
import 'package:hoop/dtos/responses/group/Groups.dart';

class GroupJoinRequest {
  final String id;
  final String groupId;
  final String userId;
  final String message;
  final String status;
  final int slots;
  final String createdAt;
  final String updatedAt;
  final User? user;
  final Group? group;

  GroupJoinRequest({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.message,
    required this.status,
    required this.slots,
    required this.createdAt,
    required this.updatedAt,
    this.user,
    this.group,
  });

  factory GroupJoinRequest.fromJson(Map<String, dynamic> json) {
    return GroupJoinRequest(
      id: json['id'] ?? '',
      groupId: json['groupId'] ?? '',
      userId: json['userId'] ?? '',
      message: json['message'] ?? '',
      status: json['status'] ?? 'pending',
      slots: json['slots'] ?? 1,
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      group: json['group'] != null ? Group.fromJson(json['group']) : null,
    );
  }
}
