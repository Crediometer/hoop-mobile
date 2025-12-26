// lib/models/group_join_request.dart
import 'package:flutter/material.dart';
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'groupId': groupId,
      'userId': userId,
      'message': message,
      'status': status,
      'slots': slots,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'user': user?.toJson(),
      'group': group?.toJson(),
    };
  }

  // Optional: Copy with method
  GroupJoinRequest copyWith({
    String? id,
    String? groupId,
    String? userId,
    String? message,
    String? status,
    int? slots,
    String? createdAt,
    String? updatedAt,
    User? user,
    Group? group,
  }) {
    return GroupJoinRequest(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      userId: userId ?? this.userId,
      message: message ?? this.message,
      status: status ?? this.status,
      slots: slots ?? this.slots,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      user: user ?? this.user,
      group: group ?? this.group,
    );
  }

  // Helper getters
  bool get isPending => status.toLowerCase() == 'pending';
  bool get isApproved => status.toLowerCase() == 'approved';
  bool get isRejected => status.toLowerCase() == 'rejected';

  // Format dates
  String get formattedCreatedDate {
    try {
      final date = DateTime.parse(createdAt);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return createdAt;
    }
  }

  String get formattedUpdatedDate {
    try {
      final date = DateTime.parse(updatedAt);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return updatedAt;
    }
  }

  // Status badge color helper
  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  // Status text helper
  String get statusText {
    switch (status.toLowerCase()) {
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'pending':
      default:
        return 'Pending Review';
    }
  }
}