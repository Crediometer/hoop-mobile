
// lib/dtos/responses/group/Groups.dart
class Group {
  final String id;
  final String name;
  final String description;
  final double contributionAmount;
  final String cycleDuration;
  final int cycleDurationDays;
  final int maxMembers;
  final int currentCycle;
  final String payoutOrder;
  final bool isPrivate;
  final bool requireApproval;
  final bool allowPairing;
  final String? location;
  final List<String> tags;
  final String status;
  final String startDate;
  final String createdBy;
  final String createdAt;
  final String updatedAt;
  final int? approvedMembersCount;
  final double? latitude;
  final double? longitude;
  final bool isCommunity;
  final bool allowGroupMessage;
  final bool allowGroupVideoCall;
  final String displayCycleDuration;
  final bool nextCycleDue;
  final String? nextPayoutDate;

  Group({
    required this.id,
    required this.name,
    required this.description,
    required this.contributionAmount,
    required this.cycleDuration,
    required this.cycleDurationDays,
    required this.maxMembers,
    required this.currentCycle,
    required this.payoutOrder,
    required this.isPrivate,
    required this.requireApproval,
    required this.allowPairing,
    this.location,
    required this.tags,
    required this.status,
    required this.startDate,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.approvedMembersCount,
    this.latitude,
    this.longitude,
    required this.isCommunity,
    required this.allowGroupMessage,
    required this.allowGroupVideoCall,
    required this.displayCycleDuration,
    required this.nextCycleDue,
    this.nextPayoutDate,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      contributionAmount: (json['contributionAmount'] ?? 0).toDouble(),
      cycleDuration: json['cycleDuration'] ?? '7 days',
      cycleDurationDays: json['cycleDurationDays'] ?? 7,
      maxMembers: json['maxMembers'] ?? 0,
      currentCycle: json['currentCycle'] ?? 1,
      payoutOrder: json['payoutOrder'] ?? 'assignment',
      isPrivate: json['isPrivate'] ?? false,
      requireApproval: json['requireApproval'] ?? false,
      allowPairing: json['allowPairing'] ?? true,
      location: json['location'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      status: json['status'] ?? 'forming',
      startDate: json['startDate'] ?? '',
      createdBy: json['createdBy'].toString(),
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      approvedMembersCount: json['approvedMembersCount'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      isCommunity: json['isCommunity'] ?? false,
      allowGroupMessage: json['allowGroupMessage'] ?? true,
      allowGroupVideoCall: json['allowGroupVideoCall'] ?? true,
      displayCycleDuration: json['displayCycleDuration'] ?? '7 days',
      nextCycleDue: json['nextCycleDue'] ?? false,
      nextPayoutDate: json['nextPayoutDate'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'contributionAmount': contributionAmount,
      'cycleDuration': cycleDuration,
      'cycleDurationDays': cycleDurationDays,
      'maxMembers': maxMembers,
      'currentCycle': currentCycle,
      'payoutOrder': payoutOrder,
      'isPrivate': isPrivate,
      'requireApproval': requireApproval,
      'allowPairing': allowPairing,
      'location': location,
      'tags': tags,
      'status': status,
      'startDate': startDate,
      'createdBy': createdBy,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'approvedMembersCount': approvedMembersCount,
      'latitude': latitude,
      'longitude': longitude,
      'isCommunity': isCommunity,
      'allowGroupMessage': allowGroupMessage,
      'allowGroupVideoCall': allowGroupVideoCall,
      'displayCycleDuration': displayCycleDuration,
      'nextCycleDue': nextCycleDue,
      'nextPayoutDate': nextPayoutDate,
    };
  }

  // Helper getters for UI
  bool get isPublic => !isPrivate;
  String get formattedAmount => '₦$contributionAmount';
  String get membersInfo => '$maxMembers members max';
  double get progress => maxMembers > 0 ? (approvedMembersCount ?? 0) / maxMembers : 0;
  bool get isFull => maxMembers > 0 && (approvedMembersCount ?? 0) >= maxMembers;
  bool get isActive => status.toLowerCase() == 'active' || status.toLowerCase() == 'forming';
  String get formattedLocation => location ?? 'Location not specified';
  String get category => tags.isNotEmpty ? tags.first : 'General';

  // For backward compatibility with existing code
  int get currentMembers => approvedMembersCount ?? 0;
  String get contributionFrequency => cycleDuration;
  String get creatorId => createdBy;
  bool get allowMessage => allowGroupMessage;
  bool get allowVideoCall => allowGroupVideoCall;
}
