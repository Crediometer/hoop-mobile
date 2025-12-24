// lib/models/group_details.dart
import 'package:hoop/dtos/responses/group/Groups.dart';
import 'package:hoop/dtos/responses/group/group_contribution.dart';
import 'package:hoop/dtos/responses/group/group_join_request.dart';
import 'package:hoop/dtos/responses/group/group_member.dart';
import 'package:hoop/dtos/responses/group/group_stats.dart';
import 'package:hoop/dtos/responses/group/payout_order_item.dart';

class GroupDetails {
  final Group group;
  final List<GroupMember> members;
  final List<PayoutOrderItem> payoutOrder;
  final GroupStats? stats;
  final List<GroupContribution> recentContributions;
  final List<GroupJoinRequest> pendingRequests;

  GroupDetails({
    required this.group,
    required this.members,
    required this.payoutOrder,
    this.stats,
    required this.recentContributions,
    required this.pendingRequests,
  });

  factory GroupDetails.fromJson(Map<String, dynamic> json) {
    return GroupDetails(
      group: Group.fromJson(json['group'] ?? {}),
      members: (json['members'] as List?)
              ?.map((item) => GroupMember.fromJson(item))
              .toList() ??
          [],
      payoutOrder: (json['payoutOrder'] as List?)
              ?.map((item) => PayoutOrderItem.fromJson(item))
              .toList() ??
          [],
      stats: json['stats'] != null ? GroupStats.fromJson(json['stats']) : null,
      recentContributions: (json['recentContributions'] as List?)
              ?.map((item) => GroupContribution.fromJson(item))
              .toList() ??
          [],
      pendingRequests: (json['pendingRequests'] as List?)
              ?.map((item) => GroupJoinRequest.fromJson(item))
              .toList() ??
          [],
    );
  }
}
