// lib/models/payout_order.dart
import 'package:hoop/dtos/responses/group/group_member.dart';

class PayoutOrderItem {
  final String id;
  final String groupId;
  final String memberId;
  final int position;
  final int cycleNumber;
  final String createdAt;
  final GroupMember? member;

  PayoutOrderItem({
    required this.id,
    required this.groupId,
    required this.memberId,
    required this.position,
    required this.cycleNumber,
    required this.createdAt,
    this.member,
  });

  factory PayoutOrderItem.fromJson(Map<String, dynamic> json) {
    return PayoutOrderItem(
      id: json['id'] ?? '',
      groupId: json['groupId'] ?? '',
      memberId: json['memberId'] ?? '',
      position: json['position'] ?? 0,
      cycleNumber: json['cycleNumber'] ?? 1,
      createdAt: json['createdAt'] ?? '',
      member: json['member'] != null ? GroupMember.fromJson(json['member']) : null,
    );
  }
}

