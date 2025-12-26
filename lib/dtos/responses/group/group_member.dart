// lib/models/group_member.dart
import 'package:hoop/dtos/responses/User.dart';

class GroupMember {
  final String id;
  final String userId;
  final String imageVerification;
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
    this.imageVerification = "",
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
      imageVerification: json['imageVerification'] ?? '',
      leftAt: json['leftAt'],
      user: json['user'] != null ? User.fromJson(json['user']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'groupId': groupId,
      'role': role,
      'status': status,
      'joinedAt': joinedAt,
      'leftAt': leftAt,
      'user': user?.toJson(),
    };
  }

  // Optional: Copy with method for immutability
  GroupMember copyWith({
    String? id,
    String? userId,
    String? groupId,
    String? role,
    String? status,
    String? joinedAt,
    String? leftAt,
    User? user,
  }) {
    return GroupMember(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      groupId: groupId ?? this.groupId,
      role: role ?? this.role,
      status: status ?? this.status,
      joinedAt: joinedAt ?? this.joinedAt,
      leftAt: leftAt ?? this.leftAt,
      user: user ?? this.user,
    );
  }

  // Helper methods
  bool get isAdmin => role.toLowerCase() == 'admin';
  bool get isModerator => role.toLowerCase() == 'moderator';
  bool get isMember => role.toLowerCase() == 'member';

  bool get isActive => status.toLowerCase() == 'active';
  bool get isPending => status.toLowerCase() == 'pending';
  bool get isRejected => status.toLowerCase() == 'rejected';
  bool get isLeft => leftAt != null;

  // Format joined date
  String get formattedJoinedDate {
    try {
      final date = DateTime.parse(joinedAt);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return joinedAt;
    }
  }
}
