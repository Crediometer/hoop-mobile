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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'groupId': groupId,
      'memberId': memberId,
      'position': position,
      'cycleNumber': cycleNumber,
      'createdAt': createdAt,
      'member': member?.toJson(),
    };
  }

  // Optional: Copy with method for immutability
  PayoutOrderItem copyWith({
    String? id,
    String? groupId,
    String? memberId,
    int? position,
    int? cycleNumber,
    String? createdAt,
    GroupMember? member,
  }) {
    return PayoutOrderItem(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      memberId: memberId ?? this.memberId,
      position: position ?? this.position,
      cycleNumber: cycleNumber ?? this.cycleNumber,
      createdAt: createdAt ?? this.createdAt,
      member: member ?? this.member,
    );
  }

  // Helper methods
  bool get isFirst => position == 1;
  bool get isLast => cycleNumber > 1; // You might want to adjust this based on your logic
  
  // Format position with ordinal suffix (1st, 2nd, 3rd, etc.)
  String get formattedPosition {
    switch (position) {
      case 1:
        return '1st';
      case 2:
        return '2nd';
      case 3:
        return '3rd';
      default:
        return '${position}th';
    }
  }

  // Format cycle number
  String get formattedCycle => 'Cycle $cycleNumber';

  // Format date
  String get formattedCreatedDate {
    try {
      final date = DateTime.parse(createdAt);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return createdAt;
    }
  }

  // Get member name (if member exists)
  String get memberName => member?.firstName ?? 'Unknown Member';

  // Get member avatar (if member exists)
  String? get memberAvatar => member?.imageVerification;

  // Get member initials (if member exists)
  String get memberInitials {
    final name = member?.firstName ?? '';
    if (name.isEmpty) return '??';
    
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty) {
      return parts[0].substring(0, min(2, parts[0].length)).toUpperCase();
    }
    return '??';
  }

  // Helper for min function
  int min(int a, int b) => a < b ? a : b;

  // Compare by position for sorting
  static int compareByPosition(PayoutOrderItem a, PayoutOrderItem b) {
    return a.position.compareTo(b.position);
  }

  // Compare by cycle then position
  static int compareByCycleAndPosition(PayoutOrderItem a, PayoutOrderItem b) {
    final cycleCompare = a.cycleNumber.compareTo(b.cycleNumber);
    if (cycleCompare != 0) return cycleCompare;
    return a.position.compareTo(b.position);
  }
}