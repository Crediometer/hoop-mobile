
import 'package:hoop/dtos/responses/User.dart';

class GroupContribution {
  final String id;
  final String groupId;
  final String userId;
  final double amount;
  final String status;
  final String createdAt;
  final User? user;

  GroupContribution({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.user,
  });

  factory GroupContribution.fromJson(Map<String, dynamic> json) {
    return GroupContribution(
      id: json['id'] ?? '',
      groupId: json['groupId'] ?? '',
      userId: json['userId'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      createdAt: json['createdAt'] ?? '',
      user: json['user'] != null ? User.fromJson(json['user']) : null,
    );
  }
}

