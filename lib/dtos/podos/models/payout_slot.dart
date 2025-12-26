import 'package:hoop/dtos/responses/group/index.dart';

class PayoutSlot {
  final String id;
  final int position;
  final List<PayoutSlotMember> members;
  double totalValue;
  bool isFull;

  PayoutSlot({
    required this.id,
    required this.position,
    required this.members,
    required this.totalValue,
    required this.isFull,
  });

  factory PayoutSlot.fromJson(Map<String, dynamic> json) {
    return PayoutSlot(
      id: json['id']?.toString() ?? '',
      position: json['position'] ?? 0,
      members: (json['members'] as List<dynamic>?)
              ?.map((item) => PayoutSlotMember.fromJson(item))
              .toList() ??
          [],
      totalValue: (json['totalValue'] as num?)?.toDouble() ?? 0.0,
      isFull: json['isFull'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'position': position,
      'members': members.map((member) => member.toJson()).toList(),
      'totalValue': totalValue,
      'isFull': isFull,
    };
  }
}

class PayoutSlotMember {
  final GroupMember member;
  final double slotValue;

  PayoutSlotMember({
    required this.member,
    required this.slotValue,
  });

  factory PayoutSlotMember.fromJson(Map<String, dynamic> json) {
    return PayoutSlotMember(
      member: GroupMember.fromJson(json['member'] ?? {}),
      slotValue: (json['slotValue'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'member': member.toJson(),
      'slotValue': slotValue,
    };
  }
}