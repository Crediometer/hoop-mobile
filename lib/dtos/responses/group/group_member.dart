import 'package:flutter/material.dart';

class GroupMember {
  final num userId;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final String? imageVerification;
  final String role; // "ADMIN" | "MEMBER" - Note: Removed "OWNER"
  final String status; // "APPROVED" | "PENDING" | "REJECTED"
  final double slots;
  final String joinDate;
  final String? approvedAt;
  final double totalContributions;
  final bool receivedPayout;
  final int payoutCycle;
  final int? contributionCount;
  final bool isCurrentUser;
  final bool isAssignedInPayout;

  GroupMember({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    this.avatarUrl,
    this.imageVerification,
    required this.role,
    required this.status,
    required this.slots,
    required this.joinDate,
    this.approvedAt,
    required this.totalContributions,
    required this.receivedPayout,
    required this.payoutCycle,
    this.contributionCount,
    this.isCurrentUser = false,
    this.isAssignedInPayout = false,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      userId: json['userId'],
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      avatarUrl: json['avatarUrl'],
      imageVerification: json['imageVerification'],
      role: json['role'] ?? 'MEMBER',
      status: json['status'] ?? 'PENDING',
      slots: (json['slots'] ?? 1).toDouble(),
      joinDate: json['joinDate'] ?? '',
      approvedAt: json['approvedAt'],
      totalContributions: (json['totalContributions'] ?? 0).toDouble(),
      receivedPayout: json['receivedPayout'] ?? false,
      payoutCycle: json['payoutCycle'] ?? 0,
      contributionCount: json['contributionCount'],
      isCurrentUser: json['isCurrentUser'] ?? false,
      isAssignedInPayout: json['isAssignedInPayout'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'avatarUrl': avatarUrl,
      'imageVerification': imageVerification,
      'role': role,
      'status': status,
      'slots': slots,
      'joinDate': joinDate,
      'approvedAt': approvedAt,
      'totalContributions': totalContributions,
      'receivedPayout': receivedPayout,
      'payoutCycle': payoutCycle,
      'contributionCount': contributionCount,
      'isCurrentUser': isCurrentUser,
      'isAssignedInPayout': isAssignedInPayout,
    };
  }

  GroupMember copyWith({
    int? userId,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? avatarUrl,
    String? imageVerification,
    String? role,
    String? status,
    double? slots,
    String? joinDate,
    String? approvedAt,
    double? totalContributions,
    bool? receivedPayout,
    int? payoutCycle,
    int? contributionCount,
    bool? isCurrentUser,
    bool? isAssignedInPayout,
  }) {
    return GroupMember(
      userId: userId ?? this.userId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      imageVerification: imageVerification ?? this.imageVerification,
      role: role ?? this.role,
      status: status ?? this.status,
      slots: slots ?? this.slots,
      joinDate: joinDate ?? this.joinDate,
      approvedAt: approvedAt ?? this.approvedAt,
      totalContributions: totalContributions ?? this.totalContributions,
      receivedPayout: receivedPayout ?? this.receivedPayout,
      payoutCycle: payoutCycle ?? this.payoutCycle,
      contributionCount: contributionCount ?? this.contributionCount,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
      isAssignedInPayout: isAssignedInPayout ?? this.isAssignedInPayout,
    );
  }

  // Helper getters for easier access
  String get fullName => '$firstName $lastName';
  
  bool get isAdmin => role == 'ADMIN';
  bool get isMember => role == 'MEMBER';
  
  bool get isApproved => status == 'APPROVED';
  bool get isPending => status == 'PENDING';
  bool get isRejected => status == 'REJECTED';
  
  // Format helpers
  String get formattedPhone => phone ?? 'No phone';
  String get formattedJoinDate => _formatDate(joinDate);
  String get formattedApprovedAt => approvedAt != null ? _formatDate(approvedAt!) : 'Not approved';
  
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
  
  // For avatar display
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
  
  // Check if member has verification
  bool get hasImageVerification => imageVerification != null && imageVerification!.isNotEmpty;
  
  // Get display role (for UI)
  String get displayRole {
    switch (role) {
      case 'ADMIN':
        return 'Admin';
      case 'MEMBER':
        return 'Member';
      default:
        return role;
    }
  }
  
  // Get display status (for UI)
  String get displayStatus {
    switch (status) {
      case 'APPROVED':
        return 'Approved';
      case 'PENDING':
        return 'Pending';
      case 'REJECTED':
        return 'Rejected';
      default:
        return status;
    }
  }
  
  // Status color for UI
  Color get statusColor {
    switch (status) {
      case 'APPROVED':
        return const Color(0xFF10B981); // Green
      case 'PENDING':
        return const Color(0xFFF97316); // Orange
      case 'REJECTED':
        return const Color(0xFFEF4444); // Red
      default:
        return Colors.grey;
    }
  }
  
  // Role color for UI
  Color get roleColor {
    switch (role) {
      case 'ADMIN':
        return Colors.amber;
      case 'MEMBER':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
  
  // Check if member can be assigned to payout
  bool get canBeAssignedToPayout {
    return isApproved && !isAssignedInPayout && slots > 0;
  }
  
  // Calculate remaining slots
  double get remainingSlots {
    // Assuming 1 slot per member as default
    // You might want to adjust this based on your business logic
    return slots;
  }
  
  // Check if member has contributed
  bool get hasContributed => totalContributions > 0;
  
  // Get contribution status
  String get contributionStatus {
    if (contributionCount == null) return 'No contributions';
    return '$contributionCount contribution${contributionCount != 1 ? 's' : ''}';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GroupMember && other.userId == userId;
  }

  @override
  int get hashCode => userId.hashCode;

  @override
  String toString() {
    return 'GroupMember(userId: $userId, name: $fullName, role: $role, status: $status)';
  }
}