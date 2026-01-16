import 'package:hoop/dtos/responses/group/group_member.dart';
import 'package:hoop/dtos/responses/group/group_stats.dart';

class GroupDetailsPublic {
  final int id;
  final String name;
  final String description;
  final String type; // e.g. "PUBLIC"
  final String status; // e.g. "FORMING"
  final String location;
  final String city;
  final String state;
  final String payoutOrder;
  final String country;
  final num maxMembers;
  final num currentMembersCount;
  final num remainingSlots;
  final bool requireApproval;
  final bool allowPairing;
  final bool isPrivate;
  final num? contributionAmount;
  final String contributionFrequency; // e.g. "MONTHLY"
  final String currency; // e.g. "NGN"
  final String startDate; // ISO date string
  final String endDate; // ISO date string
  final String createdAt; // ISO date string
  final bool canJoin;
  final String? joinRestrictionReason;


  final GroupStats? stats;

  GroupDetailsPublic({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.status,
    required this.payoutOrder,
    required this.location,
    required this.city,
    required this.state,
    required this.country,
    required this.maxMembers,
    required this.currentMembersCount,
    required this.remainingSlots,
    required this.requireApproval,
    required this.allowPairing,
    required this.isPrivate,
    required this.contributionAmount,
    required this.contributionFrequency,
    required this.currency,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
    required this.canJoin,
    this.joinRestrictionReason,
    this.stats,
  });

  factory GroupDetailsPublic.fromJson(Map<String, dynamic> json) {
    return GroupDetailsPublic(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      type: json['type'] as String? ?? '',
      payoutOrder: json['payoutOrder'] as String? ?? '',
      status: json['status'] as String? ?? '',
      location: json['location'] as String? ?? '',
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      country: json['country'] as String? ?? '',
      maxMembers: json['maxMembers'] as num? ?? 0,
      currentMembersCount: json['currentMembersCount'] as num? ?? 0,
      remainingSlots: json['remainingSlots'] as num? ?? 0,
      requireApproval: json['requireApproval'] as bool? ?? false,
      allowPairing: json['allowPairing'] as bool? ?? false,
      isPrivate: json['isPrivate'] as bool? ?? false,
      contributionAmount: (json['contributionAmount'] as num?)?.toDouble() ?? 0.0,
      contributionFrequency: json['contributionFrequency'] as String? ?? '',
      currency: json['currency'] as String? ?? '',
      startDate: json['startDate'] as String? ?? '',
      endDate: json['endDate'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
      canJoin: json['canJoin'] as bool? ?? false,
      joinRestrictionReason: json['joinRestrictionReason'] as String?,
      
      stats: json['stats'] != null ? GroupStats.fromJson(json['stats']) : null,
    );
  }
}