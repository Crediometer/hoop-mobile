import 'dart:convert';

import 'package:hoop/dtos/responses/group/index.dart';

class GroupDetails {
  final int? id;
  final int? currentCycle;
  final String? name;
  final String? description;
  final String? type;
  final String? status;
  final String? payoutOrder;
  final String? location;
  final int? maxMembers;
  final double? approvedMembersCount;
  final double? remainingSlots;
  final bool? requireApproval;
  final bool? allowPairing;
  final bool? isPrivate;
  final List<PayoutItem>? nextPayOut;
  final int? createdBy;
  final bool? allowVideoCall;
  final bool? allowGroupMessaging;
  final double? contributionAmount;
  final String? contributionFrequency;
  final String? currency;
  final String? startDate;
  final String? endDate;
  final String? nextPayoutDate;
  final String? createdAt;
  final String? currentUserRole;
  final bool? canStart;
  final bool? canEdit;
  final bool? canInvite;
  final List<GroupMember>? members;

  GroupDetails({
    this.id,
    this.currentCycle,
    this.name,
    this.description,
    this.type,
    this.status,
    this.payoutOrder,
    this.location,
    this.maxMembers,
    this.approvedMembersCount,
    this.remainingSlots,
    this.requireApproval,
    this.allowPairing,
    this.isPrivate,
    this.nextPayOut,
    this.createdBy,
    this.allowVideoCall,
    this.allowGroupMessaging,
    this.contributionAmount,
    this.contributionFrequency,
    this.currency,
    this.startDate,
    this.endDate,
    this.nextPayoutDate,
    this.createdAt,
    this.currentUserRole,
    this.canStart,
    this.canEdit,
    this.canInvite,
    this.members,
  });

  factory GroupDetails.fromJson(Map<String, dynamic> json) {
    return GroupDetails(
      id: json['id'] != null ? json['id'] as int? : null,
      currentCycle: json['currentCycle'] != null ? json['currentCycle'] as int? : null,
      name: json['name'] as String?,
      description: json['description'] as String?,
      type: json['type'] as String?,
      status: json['status'] as String?,
      payoutOrder: json['payoutOrder'] as String?,
      location: json['location'] as String?,
      maxMembers: json['maxMembers'] != null ? json['maxMembers'] as int? : null,
      approvedMembersCount: json['approvedMembersCount'] != null ? 
          (json['approvedMembersCount'] is int ? 
           (json['approvedMembersCount'] as int).toDouble() : 
           json['approvedMembersCount'] as double) : null,
      remainingSlots: json['remainingSlots'] != null ? 
          (json['remainingSlots'] is int ? 
           (json['remainingSlots'] as int).toDouble() : 
           json['remainingSlots'] as double) : null,
      requireApproval: json['requireApproval'] as bool?,
      allowPairing: json['allowPairing'] as bool?,
      isPrivate: json['isPrivate'] as bool?,
      nextPayOut: json['nextPayOut'] != null ? 
          (json['nextPayOut'] as List).map((item) => PayoutItem.fromJson(item)).toList() : 
          null,
      createdBy: json['createdBy'] != null ? json['createdBy'] as int? : null,
      allowVideoCall: json['allowVideoCall'] as bool?,
      allowGroupMessaging: json['allowGroupMessaging'] as bool?,
      contributionAmount: json['contributionAmount'] != null ? 
          (json['contributionAmount'] is int ? 
           (json['contributionAmount'] as int).toDouble() : 
           json['contributionAmount'] as double) : null,
      contributionFrequency: json['contributionFrequency'] as String?,
      currency: json['currency'] as String?,
      startDate: json['startDate'] as String?,
      endDate: json['endDate'] as String?,
      nextPayoutDate: json['nextPayoutDate'] as String?,
      createdAt: json['createdAt'] as String?,
      currentUserRole: json['currentUserRole'] as String?,
      canStart: json['canStart'] as bool?,
      canEdit: json['canEdit'] as bool?,
      canInvite: json['canInvite'] as bool?,
      members: json['members'] != null ? 
          (json['members'] as List).map((item) => GroupMember.fromJson(item)).toList() : 
          null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'currentCycle': currentCycle,
      'name': name,
      'description': description,
      'type': type,
      'status': status,
      'payoutOrder': payoutOrder,
      'location': location,
      'maxMembers': maxMembers,
      'approvedMembersCount': approvedMembersCount,
      'remainingSlots': remainingSlots,
      'requireApproval': requireApproval,
      'allowPairing': allowPairing,
      'isPrivate': isPrivate,
      'nextPayOut': nextPayOut?.map((item) => item.toJson()).toList(),
      'createdBy': createdBy,
      'allowVideoCall': allowVideoCall,
      'allowGroupMessaging': allowGroupMessaging,
      'contributionAmount': contributionAmount,
      'contributionFrequency': contributionFrequency,
      'currency': currency,
      'startDate': startDate,
      'endDate': endDate,
      'nextPayoutDate': nextPayoutDate,
      'createdAt': createdAt,
      'currentUserRole': currentUserRole,
      'canStart': canStart,
      'canEdit': canEdit,
      'canInvite': canInvite,
      'members': members?.map((item) => item.toJson()).toList(),
    };
  }

  String toJsonString() => json.encode(toJson());
  
  factory GroupDetails.fromJsonString(String jsonString) => 
      GroupDetails.fromJson(json.decode(jsonString));
}



class PayoutItem {
  final int? memberId;
  final int? position;
  final String? memberName;
  final double? slotValue;

  PayoutItem({
    this.memberId,
    this.position,
    this.memberName,
    this.slotValue,
  });

  factory PayoutItem.fromJson(Map<String, dynamic> json) {
    return PayoutItem(
      memberId: json['memberId'] != null ? json['memberId'] as int? : null,
      position: json['position'] != null ? json['position'] as int? : null,
      memberName: json['memberName'] as String?,
      slotValue: json['slotValue'] != null ? 
          (json['slotValue'] is int ? 
           (json['slotValue'] as int).toDouble() : 
           json['slotValue'] as double) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'memberId': memberId,
      'position': position,
      'memberName': memberName,
      'slotValue': slotValue,
    };
  }

  String toJsonString() => json.encode(toJson());
  
  factory PayoutItem.fromJsonString(String jsonString) => 
      PayoutItem.fromJson(json.decode(jsonString));

  // Helper method
  bool get isFullSlot => slotValue == 1.0;
  bool get isHalfSlot => slotValue == 0.5;
}