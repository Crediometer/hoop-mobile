import 'package:flutter/material.dart';

class GroupJoinRequest {
  final int id;
  final int groupId;
  final String groupName;
  final String groupDescription;
  final double contributionAmount;
  final int approvedMembersCount;
  final String groupStatus;
  final String groupUpdatedAt;
  final String status; // 'pending' | 'approved' | 'rejected' | 'withdrawn' | 'expired'
  final String createdAt;
  final String? startDate;
  final int slots;
  final String? message;
  final int? maxMembers;
  final String? location;

  GroupJoinRequest({
    required this.id,
    required this.groupId,
    required this.groupName,
    required this.groupDescription,
    required this.contributionAmount,
    required this.approvedMembersCount,
    required this.groupStatus,
    required this.groupUpdatedAt,
    required this.status,
    required this.createdAt,
    this.startDate,
    this.slots = 1,
    this.message,
    this.maxMembers,
    this.location,
  });

  factory GroupJoinRequest.fromJson(Map<String, dynamic> json) {
    return GroupJoinRequest(
      id: json['id'] ?? 0,
      groupId: json['groupId'] ?? 0,
      groupName: json['groupName'] ?? '',
      groupDescription: json['groupDescription'] ?? '',
      contributionAmount: (json['contributionAmount'] ?? 0).toDouble(),
      approvedMembersCount: json['approvedMembersCount'] ?? 0,
      groupStatus: json['groupStatus'] ?? '',
      groupUpdatedAt: json['groupUpdatedAt'] ?? '',
      status: json['status'] ?? 'pending',
      createdAt: json['createdAt'] ?? '',
      startDate: json['startDate'],
      slots: json['slots'] ?? 1,
      message: json['message'],
      maxMembers: json['maxMembers'],
      location: json['location'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'groupId': groupId,
      'groupName': groupName,
      'groupDescription': groupDescription,
      'contributionAmount': contributionAmount,
      'approvedMembersCount': approvedMembersCount,
      'groupStatus': groupStatus,
      'groupUpdatedAt': groupUpdatedAt,
      'status': status,
      'createdAt': createdAt,
      'startDate': startDate,
      'slots': slots,
      'message': message,
      'maxMembers': maxMembers,
      'location': location,
    };
  }

  GroupJoinRequest copyWith({
    int? id,
    int? groupId,
    String? groupName,
    String? groupDescription,
    double? contributionAmount,
    int? approvedMembersCount,
    String? groupStatus,
    String? groupUpdatedAt,
    String? status,
    String? createdAt,
    String? startDate,
    int? slots,
    String? message,
    int? maxMembers,
    String? location,
  }) {
    return GroupJoinRequest(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      groupDescription: groupDescription ?? this.groupDescription,
      contributionAmount: contributionAmount ?? this.contributionAmount,
      approvedMembersCount: approvedMembersCount ?? this.approvedMembersCount,
      groupStatus: groupStatus ?? this.groupStatus,
      groupUpdatedAt: groupUpdatedAt ?? this.groupUpdatedAt,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      startDate: startDate ?? this.startDate,
      slots: slots ?? this.slots,
      message: message ?? this.message,
      maxMembers: maxMembers ?? this.maxMembers,
      location: location ?? this.location,
    );
  }

  // Helper getters
  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get isWithdrawn => status == 'withdrawn';
  bool get isExpired => status == 'expired';

  bool get isActive => isPending; // Pending requests are active
  bool get isProcessed => isApproved || isRejected; // Requests that have been acted upon

  // Status color for UI
  Color get statusColor {
    switch (status) {
      case 'pending':
        return const Color(0xFFF97316); // Orange
      case 'approved':
        return const Color(0xFF10B981); // Green
      case 'rejected':
        return const Color(0xFFEF4444); // Red
      case 'withdrawn':
        return Colors.grey;
      case 'expired':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  // Status display text
  String get displayStatus {
    switch (status) {
      case 'pending':
        return 'Pending Review';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'withdrawn':
        return 'Withdrawn';
      case 'expired':
        return 'Expired';
      default:
        return status;
    }
  }

  // Group status helpers
  bool get isGroupForming => groupStatus.toLowerCase() == 'forming';
  bool get isGroupActive => groupStatus.toLowerCase() == 'active';
  bool get isGroupCompleted => groupStatus.toLowerCase() == 'completed';
  bool get isGroupCancelled => groupStatus.toLowerCase() == 'cancelled';

  // Format dates
  String get formattedCreatedAt => _formatDate(createdAt);
  String get formattedGroupUpdatedAt => _formatDate(groupUpdatedAt);
  String? get formattedStartDate => startDate != null ? _formatDate(startDate!) : null;

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  // Calculate days since request
  int get daysSinceCreation {
    try {
      final createdDate = DateTime.parse(createdAt);
      final now = DateTime.now();
      return now.difference(createdDate).inDays;
    } catch (e) {
      return 0;
    }
  }

  // Check if request is recent (within 7 days)
  bool get isRecent => daysSinceCreation <= 7;

  // Group capacity info
  int? get remainingSlots {
    if (maxMembers == null) return null;
    return maxMembers! - approvedMembersCount;
  }

  bool get isGroupFull {
    if (maxMembers == null) return false;
    return approvedMembersCount >= maxMembers!;
  }

  // Contribution info
  String get formattedContributionAmount {
    return '₦${contributionAmount.toStringAsFixed(2).replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), ',')}';
  }

  // Message handling
  bool get hasMessage => message != null && message!.isNotEmpty;
  String get truncatedMessage {
    if (!hasMessage) return '';
    if (message!.length <= 100) return message!;
    return '${message!.substring(0, 100)}...';
  }

  // Location display
  String get displayLocation => location ?? 'Location not specified';

  // Slots display
  String get slotsDisplay {
    return '$slots slot${slots != 1 ? 's' : ''}';
  }

  // Member count display
  String get memberCountDisplay {
    if (maxMembers == null) return '$approvedMembersCount members';
    return '$approvedMembersCount / $maxMembers members';
  }

  // Check if group has capacity for this request
  bool get canBeApproved {
    if (isGroupFull) return false;
    if (!isPending) return false;
    if (isGroupCompleted || isGroupCancelled) return false;
    return true;
  }

  // Action availability based on status
  bool get canApprove => isPending && canBeApproved;
  bool get canReject => isPending;
  bool get canWithdraw => isPending; // User can withdraw their own request

  // Group type indicators
  bool get isPrivateGroup => groupStatus.toLowerCase().contains('private');
  bool get requiresApproval => groupStatus.toLowerCase().contains('approval') || isPending;

  // For list sorting
  DateTime get createdAtDate {
    try {
      return DateTime.parse(createdAt);
    } catch (e) {
      return DateTime.now();
    }
  }

  // Group completeness percentage
  double get groupCompleteness {
    if (maxMembers == null || maxMembers == 0) return 0;
    return (approvedMembersCount / maxMembers!) * 100;
  }

  String get groupCompletenessDisplay {
    return '${groupCompleteness.toStringAsFixed(1)}% complete';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GroupJoinRequest && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'GroupJoinRequest(id: $id, group: $groupName, status: $status, created: $formattedCreatedAt)';
  }
}




class JoinRequest {
  final int id;
  final int groupId;
  final int userId;
  final String? message;
  final int slots;
  final String status; // 'pending' | 'approved' | 'rejected'
  final int? reviewedBy;
  final String? reviewedAt;
  final JoinRequestUser user;
  final String createdAt;

  JoinRequest({
    required this.id,
    required this.groupId,
    required this.userId,
    this.message,
    required this.slots,
    required this.status,
    this.reviewedBy,
    this.reviewedAt,
    required this.user,
    required this.createdAt,
  });

  factory JoinRequest.fromJson(Map<String, dynamic> json) {
    return JoinRequest(
      id: json['id'] ?? 0,
      groupId: json['groupId'] ?? 0,
      userId: json['userId'] ?? 0,
      message: json['message'],
      slots: json['slots'] ?? 1,
      status: json['status'] ?? 'pending',
      reviewedBy: json['reviewedBy'],
      reviewedAt: json['reviewedAt'],
      user: JoinRequestUser.fromJson(json['user'] ?? {}),
      createdAt: json['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'groupId': groupId,
      'userId': userId,
      'message': message,
      'slots': slots,
      'status': status,
      'reviewedBy': reviewedBy,
      'reviewedAt': reviewedAt,
      'user': user.toJson(),
      'createdAt': createdAt,
    };
  }

  JoinRequest copyWith({
    int? id,
    int? groupId,
    int? userId,
    String? message,
    int? slots,
    String? status,
    int? reviewedBy,
    String? reviewedAt,
    JoinRequestUser? user,
    String? createdAt,
  }) {
    return JoinRequest(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      userId: userId ?? this.userId,
      message: message ?? this.message,
      slots: slots ?? this.slots,
      status: status ?? this.status,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      user: user ?? this.user,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Helper getters
  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  bool get isProcessed => !isPending;
  bool get isActive => isPending;

  // Status color for UI
  Color get statusColor {
    switch (status) {
      case 'pending':
        return const Color(0xFFF97316); // Orange
      case 'approved':
        return const Color(0xFF10B981); // Green
      case 'rejected':
        return const Color(0xFFEF4444); // Red
      default:
        return Colors.grey;
    }
  }

  // Status display text
  String get displayStatus {
    switch (status) {
      case 'pending':
        return 'Pending Review';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      default:
        return status;
    }
  }

  // Check if request has been reviewed
  bool get hasBeenReviewed => reviewedBy != null && reviewedAt != null;

  // Format dates
  String get formattedCreatedAt => _formatDate(createdAt);
  String? get formattedReviewedAt => reviewedAt != null ? _formatDate(reviewedAt!) : null;

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  // Calculate days since request
  int get daysSinceCreation {
    try {
      final createdDate = DateTime.parse(createdAt);
      final now = DateTime.now();
      return now.difference(createdDate).inDays;
    } catch (e) {
      return 0;
    }
  }

  // Check if request is recent (within 7 days)
  bool get isRecent => daysSinceCreation <= 7;

  // Check if request is old (more than 30 days)
  bool get isOld => daysSinceCreation > 30;

  // Message handling
  bool get hasMessage => message != null && message!.isNotEmpty;
  String get truncatedMessage {
    if (!hasMessage) return 'No message provided';
    if (message!.length <= 100) return message!;
    return '${message!.substring(0, 100)}...';
  }

  // Slots display
  String get slotsDisplay {
    return '$slots slot${slots != 1 ? 's' : ''}';
  }

  // User info helpers
  String get userFullName => user.fullName;
  String get userEmail => user.email;
  String get userPhone => user.formattedPhone;
  bool get userHasVerification => user.hasVerification;

  // Action availability based on status
  bool get canApprove => isPending;
  bool get canReject => isPending;

  // Check if reviewed recently (within 24 hours)
  bool get recentlyReviewed {
    if (reviewedAt == null) return false;
    try {
      final reviewedDate = DateTime.parse(reviewedAt!);
      final now = DateTime.now();
      return now.difference(reviewedDate).inHours <= 24;
    } catch (e) {
      return false;
    }
  }

  // For list sorting
  DateTime get createdAtDate {
    try {
      return DateTime.parse(createdAt);
    } catch (e) {
      return DateTime.now();
    }
  }

  DateTime? get reviewedAtDate {
    if (reviewedAt == null) return null;
    try {
      return DateTime.parse(reviewedAt!);
    } catch (e) {
      return null;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is JoinRequest && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'JoinRequest(id: $id, user: $userFullName, status: $status, created: $formattedCreatedAt)';
  }
}

class JoinRequestUser {
  final int id;
  final String email;
  final String imageVerification;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final String status;
  final String createdAt;

  JoinRequestUser({
    required this.id,
    required this.email,
    required this.imageVerification,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    required this.status,
    required this.createdAt,
  });

  factory JoinRequestUser.fromJson(Map<String, dynamic> json) {
    return JoinRequestUser(
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      imageVerification: json['imageVerification'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      phoneNumber: json['phoneNumber'],
      status: json['status'] ?? '',
      createdAt: json['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'imageVerification': imageVerification,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'status': status,
      'createdAt': createdAt,
    };
  }

  // Helper getters
  String get fullName => '$firstName $lastName';
  String get formattedPhone => phoneNumber ?? 'No phone';
  bool get hasVerification => imageVerification.isNotEmpty;
  bool get isActive => status.toLowerCase() == 'active';
  bool get isVerified => status.toLowerCase() == 'verified';

  // Format date
  String get formattedCreatedAt {
    try {
      final date = DateTime.parse(createdAt);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return createdAt;
    }
  }

  // Avatar initials
  String get avatarInitials {
    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '${firstName[0]}${lastName[0]}'.toUpperCase();
    } else if (firstName.isNotEmpty) {
      return firstName[0].toUpperCase();
    } else if (lastName.isNotEmpty) {
      return lastName[0].toUpperCase();
    }
    return '?';
  }

  @override
  String toString() {
    return 'JoinRequestUser(id: $id, name: $fullName, email: $email)';
  }
}
