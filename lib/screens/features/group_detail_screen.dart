import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

// ========== DATA MODELS ==========
class GroupMember {
  final String userId;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final String? imageVerification;
  final String role; // "ADMIN" | "MEMBER" | "OWNER"
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
    required this.isCurrentUser,
    required this.isAssignedInPayout,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      userId: json['userId']?.toString() ?? '',
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
    String? userId,
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
}

class NextPayoutMember {
  final String memberId;
  final int position;
  final String memberName;
  final double slotValue;

  NextPayoutMember({
    required this.memberId,
    required this.position,
    required this.memberName,
    required this.slotValue,
  });

  factory NextPayoutMember.fromJson(Map<String, dynamic> json) {
    return NextPayoutMember(
      memberId: json['memberId']?.toString() ?? '',
      position: json['position'] ?? 0,
      memberName: json['memberName'] ?? '',
      slotValue: (json['slotValue'] ?? 0).toDouble(),
    );
  }
}

class GroupDetails {
  final String id;
  final String name;
  final String description;
  final String? type;
  final String? status;
  final String payoutOrder;
  final String? location;
  final int maxMembers;
  final int approvedMembersCount;
  final int remainingSlots;
  final bool requireApproval;
  final bool allowPairing;
  final bool allowGroupMessaging;
  final bool allowVideoCalling;
  final bool isPrivate;
  final double contributionAmount;
  final String contributionFrequency;
  final String currency;
  final String startDate;
  final String? endDate;
  final String nextPayoutDate;
  final String createdAt;
  final String currentUserRole; // "ADMIN" | "MEMBER" | "GUEST" | "OWNER"
  final bool canStart;
  final bool canEdit;
  final bool canInvite;
  final List<GroupMember> members;
  final List<NextPayoutMember>? nextPayOut;
  final int? currentCycle;
  final int? totalSlots;
  final int? createdBy;

  GroupDetails({
    required this.id,
    required this.name,
    required this.description,
    this.type,
    this.status,
    required this.payoutOrder,
    this.location,
    required this.maxMembers,
    required this.approvedMembersCount,
    required this.remainingSlots,
    required this.requireApproval,
    required this.allowPairing,
    required this.allowGroupMessaging,
    required this.allowVideoCalling,
    required this.isPrivate,
    required this.contributionAmount,
    required this.contributionFrequency,
    required this.currency,
    required this.startDate,
    this.endDate,
    required this.nextPayoutDate,
    required this.createdAt,
    required this.currentUserRole,
    required this.canStart,
    required this.canEdit,
    required this.canInvite,
    required this.members,
    this.nextPayOut,
    this.currentCycle,
    this.totalSlots,
    this.createdBy,
  });

  factory GroupDetails.fromJson(Map<String, dynamic> json) {
    return GroupDetails(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      type: json['type'],
      status: json['status'],
      payoutOrder: json['payoutOrder'] ?? 'ASSIGNMENT',
      location: json['location'],
      maxMembers: json['maxMembers'] ?? 0,
      approvedMembersCount: json['approvedMembersCount'] ?? 0,
      remainingSlots: json['remainingSlots'] ?? 0,
      requireApproval: json['requireApproval'] ?? false,
      allowPairing: json['allowPairing'] ?? false,
      allowGroupMessaging: json['allowGroupMessaging'] ?? false,
      allowVideoCalling: json['allowVideoCalling'] ?? false,
      isPrivate: json['isPrivate'] ?? false,
      contributionAmount: (json['contributionAmount'] ?? 0).toDouble(),
      contributionFrequency: json['contributionFrequency'] ?? 'monthly',
      currency: json['currency'] ?? 'NGN',
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'],
      nextPayoutDate: json['nextPayoutDate'] ?? '',
      createdAt: json['createdAt'] ?? '',
      currentUserRole: json['currentUserRole'] ?? 'GUEST',
      canStart: json['canStart'] ?? false,
      canEdit: json['canEdit'] ?? false,
      canInvite: json['canInvite'] ?? false,
      members: (json['members'] as List? ?? [])
          .map((item) => GroupMember.fromJson(item))
          .toList(),
      nextPayOut: (json['nextPayOut'] as List?)
          ?.map((item) => NextPayoutMember.fromJson(item))
          .toList(),
      currentCycle: json['currentCycle'],
      totalSlots: json['totalSlots'],
      createdBy: json['createdBy'],
    );
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
}

class PayoutSlot {
  final String id;
  final int position;
  final List<PayoutSlotMember> members;
  final double totalValue;
  final bool isFull;

  PayoutSlot({
    required this.id,
    required this.position,
    required this.members,
    required this.totalValue,
    required this.isFull,
  });

  factory PayoutSlot.fromJson(Map<String, dynamic> json) {
    return PayoutSlot(
      id: json['id'] ?? '',
      position: json['position'] ?? 0,
      members: (json['members'] as List? ?? [])
          .map((item) => PayoutSlotMember.fromJson(item))
          .toList(),
      totalValue: (json['totalValue'] ?? 0).toDouble(),
      isFull: json['isFull'] ?? false,
    );
  }
}

class PayoutSlotMember {
  final GroupMember member;
  final double slotValue;

  PayoutSlotMember({required this.member, required this.slotValue});

  factory PayoutSlotMember.fromJson(Map<String, dynamic> json) {
    return PayoutSlotMember(
      member: GroupMember.fromJson(json['member'] ?? {}),
      slotValue: (json['slotValue'] ?? 0).toDouble(),
    );
  }
}

// ========== PROVIDER (SIMPLIFIED VERSION) ==========
class GroupCommunityProvider extends ChangeNotifier {
  GroupDetails? _currentGroup;
  List<JoinRequest> _joinRequests = [];
  List<PayoutSlot> _payoutSlots = [];
  bool _isLoading = false;

  GroupDetails? get currentGroup => _currentGroup;
  List<JoinRequest> get joinRequests => _joinRequests;
  List<PayoutSlot> get payoutSlots => _payoutSlots;
  bool get isLoading => _isLoading;

  // Mock methods - replace with your actual API calls
  Future<void> getGroup(String groupId) async {
    _isLoading = true;
    notifyListeners();

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    // Mock data
    _currentGroup = GroupDetails(
      id: groupId,
      name: 'Investment Group A',
      description: 'A group for serious investors',
      type: 'investment',
      status: 'forming',
      payoutOrder: 'ASSIGNMENT',
      location: 'Lagos, Nigeria',
      maxMembers: 10,
      approvedMembersCount: 8,
      remainingSlots: 2,
      requireApproval: true,
      allowPairing: true,
      allowGroupMessaging: true,
      allowVideoCalling: true,
      isPrivate: false,
      contributionAmount: 10000.0,
      contributionFrequency: 'monthly',
      currency: 'NGN',
      startDate: '2024-01-01',
      endDate: '2024-12-31',
      nextPayoutDate: '2024-02-01',
      createdAt: '2023-12-01',
      currentUserRole: 'ADMIN',
      canStart: true,
      canEdit: true,
      canInvite: true,
      members: List.generate(
        8,
        (index) => GroupMember(
          userId: 'user_$index',
          firstName: 'User',
          lastName: '$index',
          email: 'user$index@example.com',
          role: index == 0 ? 'OWNER' : 'MEMBER',
          status: 'APPROVED',
          slots: index.isEven ? 1.0 : 0.5,
          joinDate: '2023-12-01',
          totalContributions: 10000.0 * (index + 1),
          receivedPayout: false,
          payoutCycle: 1,
          contributionCount: index + 1,
          isCurrentUser: index == 0,
          isAssignedInPayout: false,
        ),
      ),
      nextPayOut: [
        NextPayoutMember(
          memberId: 'user_1',
          position: 1,
          memberName: 'User 1',
          slotValue: 1.0,
        ),
      ],
      currentCycle: 2,
      totalSlots: 10,
    );

    _isLoading = false;
    notifyListeners();
  }

  Future<List<JoinRequest>> getGroupJoinRequests(String groupId) async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    final mockRequests = [
      JoinRequest(
        id: 1,
        groupId: int.parse(groupId),
        userId: 100,
        message: 'I want to join this group',
        slots: 1,
        status: 'pending',
        user: JoinRequestUser(
          id: 100,
          email: 'newuser@example.com',
          imageVerification: '',
          firstName: 'New',
          lastName: 'User',
          status: 'active',
          createdAt: '2023-12-01',
        ),
        createdAt: '2023-12-20',
      ),
    ];

    _joinRequests = mockRequests;
    notifyListeners();
    return mockRequests;
  }

  Future<List<PayoutSlot>> getPayoutOrder(String groupId) async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    final mockSlots = [
      PayoutSlot(
        id: 'slot-1',
        position: 1,
        members: [
          PayoutSlotMember(
            member: GroupMember(
              userId: 'user_1',
              firstName: 'User',
              lastName: '1',
              email: 'user1@example.com',
              role: 'MEMBER',
              status: 'APPROVED',
              slots: 1.0,
              joinDate: '2023-12-01',
              totalContributions: 10000.0,
              receivedPayout: false,
              payoutCycle: 1,
              contributionCount: 1,
              isCurrentUser: false,
              isAssignedInPayout: true,
            ),
            slotValue: 1.0,
          ),
        ],
        totalValue: 1.0,
        isFull: true,
      ),
    ];

    _payoutSlots = mockSlots;
    notifyListeners();
    return mockSlots;
  }

  Future<void> approveGroupRequest(String groupId, String requestId) async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    _joinRequests.removeWhere((req) => req.id.toString() == requestId);
    notifyListeners();
  }

  Future<void> rejectGroupRequest(String groupId, String requestId) async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    _joinRequests.removeWhere((req) => req.id.toString() == requestId);
    notifyListeners();
  }

  Future<void> finalizeGroup(
    String groupId,
    List<Map<String, dynamic>> payoutOrder,
  ) async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    // Update group status
    if (_currentGroup != null) {
      _currentGroup = GroupDetails.fromJson({
        ..._currentGroup!.toJson(),
        "status": 'active',
      });
    }
    notifyListeners();
  }

  Future<void> joinGroup(String groupId) async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    // Update current user role
    if (_currentGroup != null) {
      _currentGroup = GroupDetails.fromJson({
        ..._currentGroup!.toJson(),
        "currentUserRole": 'MEMBER',
        "approvedMembersCount": _currentGroup!.approvedMembersCount + 1,
      });
    }
    notifyListeners();
  }

  Future<void> startGroup(String groupId) async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    if (_currentGroup != null) {
      _currentGroup = GroupDetails.fromJson({
        ..._currentGroup!.toJson(),
        "status": 'active',
      });
    }
    notifyListeners();
  }

  Future<void> leaveGroup(String groupId) async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    // In real app, this would navigate back
    notifyListeners();
  }
}

// Helper extension
extension GroupDetailsExtension on GroupDetails {
  Map<String, dynamic> toJson() {
    return {
      'id': id,
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
      'allowGroupMessaging': allowGroupMessaging,
      'allowVideoCalling': allowVideoCalling,
      'isPrivate': isPrivate,
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
      'members': members.map((m) => m.toJson()).toList(),
      'nextPayOut': nextPayOut
          ?.map(
            (p) => {
              'memberId': p.memberId,
              'position': p.position,
              'memberName': p.memberName,
              'slotValue': p.slotValue,
            },
          )
          .toList(),
      'currentCycle': currentCycle,
      'totalSlots': totalSlots,
      'createdBy': createdBy,
    };
  }
}

// ========== MAIN SCREEN ==========
class GroupDetailScreen extends StatefulWidget {
  final String groupId;

  const GroupDetailScreen({super.key, required this.groupId});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  GroupCommunityProvider? _groupProvider;
  String _activeTab = "overview"; // overview, members, settings
  String _settingsTab = "pending"; // pending, slots, settings
  String _searchTerm = "";
  bool _isLoading = true;
  bool _isProcessingAction = false;
  bool _isLeavingGroup = false;
  bool _isFinalizingGroup = false;

  List<JoinRequest> _joinRequests = [];
  List<PayoutSlot> _payoutSlots = [];
  List<GroupMember> _unassignedMembers = [];

  // Map to track used slots per member
  final Map<String, double> _memberUsedSlots = {};
  final Set<String> _assignedMemberIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _groupProvider = Provider.of<GroupCommunityProvider>(
        context,
        listen: false,
      );
      _loadGroupData();
    });
  }

  Future<void> _loadGroupData() async {
    setState(() => _isLoading = true);
    try {
      await _groupProvider?.getGroup(widget.groupId);

      if (_groupProvider?.currentGroup != null) {
        // Set initial settings tab based on user role
        final isAdmin =
            _groupProvider?.currentGroup!.currentUserRole == "OWNER" ||
            _groupProvider?.currentGroup!.currentUserRole == "ADMIN";
        _settingsTab = isAdmin ? "pending" : "slots";

        // Fetch join requests if admin
        if (isAdmin) {
          await _fetchJoinRequests();
        }

        // Fetch payout order
        await _fetchPayoutOrder();

        // Initialize unassigned members
        _initializeUnassignedMembers();

        // Update member used slots
        _updateMemberUsedSlots();
      }
    } catch (e) {
      debugPrint('Error loading group data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchJoinRequests() async {
    try {
      final requests = await _groupProvider?.getGroupJoinRequests(
        widget.groupId,
      );
      if (requests != null) setState(() => _joinRequests = requests);
    } catch (e) {
      debugPrint('Error fetching join requests: $e');
    }
  }

  Future<void> _fetchPayoutOrder() async {
    try {
      final slots = await _groupProvider?.getPayoutOrder(widget.groupId);
      if (slots != null) setState(() => _payoutSlots = slots);
    } catch (e) {
      debugPrint('Error fetching payout order: $e');
      setState(() => _payoutSlots = []);
    }
  }

  void _initializeUnassignedMembers() {
    final group = _groupProvider?.currentGroup;
    if (group != null) {
      setState(() {
        _unassignedMembers = group.members.map((member) {
          return member.copyWith(isAssignedInPayout: false);
        }).toList();
      });
    }
  }

  void _updateMemberUsedSlots() {
    _memberUsedSlots.clear();
    _assignedMemberIds.clear();

    for (final slot in _payoutSlots) {
      for (final slotMember in slot.members) {
        final memberId = slotMember.member.userId;
        _memberUsedSlots[memberId] =
            (_memberUsedSlots[memberId] ?? 0) + slotMember.slotValue;
        _assignedMemberIds.add(memberId);
      }
    }
  }

  List<GroupMember> get _availableMembers {
    return _unassignedMembers.where((member) {
      final used = _memberUsedSlots[member.userId] ?? 0;
      final totalSlots = member.slots;
      final isAssigned = _assignedMemberIds.contains(member.userId);
      return used < totalSlots && !isAssigned;
    }).toList();
  }

  // Helper methods
  Color _getStatusColor(String status) {
    switch (status) {
      case "APPROVED":
        return const Color(0xFF10B981);
      case "PENDING":
        return const Color(0xFFF97316);
      case "REJECTED":
        return const Color(0xFFEF4444);
      default:
        return Colors.grey;
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'OWNER':
      case 'ADMIN':
        return Colors.amber;
      case 'MEMBER':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _getRoleIcon(String role) {
    switch (role) {
      case 'OWNER':
      case 'ADMIN':
        return Icon(Iconsax.crown, size: 16, color: Colors.amber[700]);
      case 'MEMBER':
        return const Icon(Icons.check_circle, size: 16, color: Colors.green);
      default:
        return const Icon(Icons.person, size: 16, color: Colors.grey);
    }
  }

  String _formatCurrency(double amount) {
    return '₦${amount.toStringAsFixed(2).replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), ',')}';
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  // Calculate days remaining
  int _calculateDaysRemaining(String dateString) {
    try {
      final targetDate = DateTime.parse(dateString);
      final today = DateTime.now();
      final diff = targetDate.difference(today).inDays;
      return diff;
    } catch (e) {
      return 0;
    }
  }

  // Calculate progress
  Map<String, dynamic> _calculateProgress(GroupDetails group) {
    final currentCycle = group.currentCycle ?? 0;
    final totalSlots = group.maxMembers;
    final percentage = (currentCycle / totalSlots * 100)
        .clamp(0, 100)
        .toDouble();

    final amountPerSlot = group.contributionAmount;
    final collectedAmount = currentCycle * amountPerSlot * totalSlots;
    final totalAmount = totalSlots * amountPerSlot * totalSlots;

    return {
      'percentage': percentage,
      'currentCycle': currentCycle,
      'totalSlots': totalSlots,
      'collected': collectedAmount,
      'expected': totalAmount,
    };
  }

  // Check if user is admin
  bool get _isAdmin {
    final group = _groupProvider?.currentGroup;
    if (group == null) return false;
    return group.currentUserRole == "OWNER" || group.currentUserRole == "ADMIN";
  }

  // Check if group is forming
  bool get _isForming {
    return _groupProvider?.currentGroup?.status?.toLowerCase() == "forming";
  }

  // Check if payout order is editable
  bool get _isPayoutOrderEditable {
    if (!_isAdmin || !_isForming) return false;
    return _groupProvider?.currentGroup?.payoutOrder?.toLowerCase() ==
        'assignment';
  }

  // Create new payout slot
  void _createNewPayoutSlot() {
    final newSlot = PayoutSlot(
      id: 'slot-${DateTime.now().millisecondsSinceEpoch}',
      position: _payoutSlots.length + 1,
      members: [],
      totalValue: 0,
      isFull: false,
    );
    setState(() {
      _payoutSlots.add(newSlot);
      _updateMemberUsedSlots();
    });
    _showSnackBar('New payout position created');
  }

  // Delete payout slot
  void _deletePayoutSlot(String slotId) {
    setState(() {
      _payoutSlots.removeWhere((slot) => slot.id == slotId);
      // Reindex positions
      for (int i = 0; i < _payoutSlots.length; i++) {
        _payoutSlots[i] = PayoutSlot(
          id: _payoutSlots[i].id,
          position: i + 1,
          members: _payoutSlots[i].members,
          totalValue: _payoutSlots[i].totalValue,
          isFull: _payoutSlots[i].isFull,
        );
      }
      _updateMemberUsedSlots();
    });
    _showSnackBar('Payout position deleted');
  }

  // Add member to slot
  void _addMemberToSlot(String slotId, GroupMember member, double slotValue) {
    setState(() {
      final slotIndex = _payoutSlots.indexWhere((s) => s.id == slotId);
      if (slotIndex != -1) {
        final slot = _payoutSlots[slotIndex];
        final newTotalValue = slot.totalValue + slotValue;

        if (newTotalValue > 1) {
          _showSnackBar('Cannot exceed 1.0 slot value per position');
          return;
        }

        final newMembers = [
          ...slot.members,
          PayoutSlotMember(member: member, slotValue: slotValue),
        ];

        _payoutSlots[slotIndex] = PayoutSlot(
          id: slot.id,
          position: slot.position,
          members: newMembers,
          totalValue: newTotalValue,
          isFull: newTotalValue == 1,
        );

        _updateMemberUsedSlots();
        _showSnackBar(
          'Added ${member.firstName} to position with $slotValue slot(s)',
        );
      }
    });
  }

  // Remove member from slot
  void _removeMemberFromSlot(String slotId, String memberId) {
    setState(() {
      final slotIndex = _payoutSlots.indexWhere((s) => s.id == slotId);
      if (slotIndex != -1) {
        final slot = _payoutSlots[slotIndex];
        final memberToRemove = slot.members.firstWhere(
          (m) => m.member.userId == memberId,
        );

        final newMembers = slot.members
            .where((m) => m.member.userId != memberId)
            .toList();
        final newTotalValue = slot.totalValue - memberToRemove.slotValue;

        _payoutSlots[slotIndex] = PayoutSlot(
          id: slot.id,
          position: slot.position,
          members: newMembers,
          totalValue: newTotalValue,
          isFull: newTotalValue == 1,
        );

        _updateMemberUsedSlots();
        _showSnackBar('Member removed from payout position');
      }
    });
  }

  // Finalize group
  Future<void> _finalizeGroup() async {
    final notFullSlots = _payoutSlots.where((s) => !s.isFull).toList();
    if (notFullSlots.isNotEmpty) {
      _showSnackBar(
        'Cannot finalize: ${notFullSlots.length} position(s) are not full',
      );
      return;
    }

    setState(() => _isFinalizingGroup = true);
    try {
      // Create payout order payload
      final payoutOrderPayload = <Map<String, dynamic>>[];
      for (final slot in _payoutSlots) {
        for (final member in slot.members) {
          payoutOrderPayload.add({
            'memberId': member.member.userId,
            'position': slot.position,
            'slotValue': member.slotValue,
          });
        }
      }

      await _groupProvider?.finalizeGroup(widget.groupId, payoutOrderPayload);
      _showSnackBar('Group finalized successfully');
      await _loadGroupData(); // Refresh data
    } catch (e) {
      _showSnackBar('Failed to finalize group: $e');
    } finally {
      setState(() => _isFinalizingGroup = false);
    }
  }

  // Handle join request action
  Future<void> _handleRequestAction(JoinRequest request, String action) async {
    setState(() => _isProcessingAction = true);
    try {
      if (action == 'approve') {
        await _groupProvider?.approveGroupRequest(
          widget.groupId,
          request.id.toString(),
        );
      } else {
        await _groupProvider?.rejectGroupRequest(
          widget.groupId,
          request.id.toString(),
        );
      }

      _showSnackBar('Join request ${action}d');
      await _fetchJoinRequests();
      await _groupProvider?.getGroup(widget.groupId);
    } catch (e) {
      _showSnackBar('Failed to process request: $e');
    } finally {
      setState(() => _isProcessingAction = false);
    }
  }

  // Join group
  Future<void> _joinGroup() async {
    try {
      await _groupProvider?.joinGroup(widget.groupId);
      _showSnackBar('Successfully joined group');
      await _loadGroupData();
    } catch (e) {
      _showSnackBar('Failed to join group: $e');
    }
  }

  // Start group
  Future<void> _startGroup() async {
    try {
      await _groupProvider?.startGroup(widget.groupId);
      _showSnackBar('Group started successfully');
      await _loadGroupData();
    } catch (e) {
      _showSnackBar('Failed to start group: $e');
    }
  }

  // Leave group
  Future<void> _leaveGroup() async {
    setState(() => _isLeavingGroup = true);
    try {
      await _groupProvider?.leaveGroup(widget.groupId);
      _showSnackBar('You have left the group');
      Navigator.of(context).pop(); // Go back to previous screen
    } catch (e) {
      _showSnackBar('Failed to leave group: $e');
    } finally {
      setState(() => _isLeavingGroup = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // Build methods for different views
  Widget _buildHeader(GroupDetails group) {
    final gradient = const LinearGradient(
      colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Container(
      decoration: BoxDecoration(gradient: gradient),
      child: Column(
        children: [
          // Top bar with back button and actions
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                Row(
                  children: [
                    if (_isAdmin)
                      IconButton(
                        onPressed: () {
                          // Navigate to invite screen
                        },
                        icon: const Icon(Icons.person_add, color: Colors.white),
                      ),
                    if (!_isAdmin && _isForming)
                      TextButton(
                        onPressed: () => _showLeaveGroupDialog(),
                        child: const Text(
                          'Leave Group',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Group info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (group.requireApproval)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Approval Required',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    const SizedBox(width: 8),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 16, color: Colors.amber),
                        const SizedBox(width: 4),
                        const Text(
                          '4.8',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  group.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 16,
                      color: Colors.white.withOpacity(0.8),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${group.approvedMembersCount} / ${group.maxMembers} members',
                      style: TextStyle(color: Colors.white.withOpacity(0.8)),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: Colors.white.withOpacity(0.8),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        group.location ?? 'Location not specified',
                        style: TextStyle(color: Colors.white.withOpacity(0.8)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  group.description,
                  style: TextStyle(color: Colors.white.withOpacity(0.8)),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(GroupDetails group) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '₦',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Contribution',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          _formatCurrency(group.contributionAmount),
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.access_time,
                          size: 20,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cycle',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          group.contributionFrequency,
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            _buildTabButton('Overview', Icons.trending_up, 'overview'),
            _buildTabButton('Members', Icons.people, 'members'),
            _buildTabButton('Settings', Icons.settings, 'settings'),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String label, IconData icon, String tab) {
    final isSelected = _activeTab == tab;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _activeTab = tab),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isSelected ? Colors.blue : Colors.grey,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.blue : Colors.grey,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search...',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (value) => setState(() => _searchTerm = value),
      ),
    );
  }

  Widget _buildOverviewTab(GroupDetails group) {
    final progressData = _calculateProgress(group);
    final daysRemaining = _calculateDaysRemaining(group.nextPayoutDate);
    final daysText = daysRemaining > 0
        ? '$daysRemaining days left'
        : daysRemaining == 0
        ? 'Today'
        : '${daysRemaining.abs()} days overdue';
    final totalPayoutAmount = group.contributionAmount * group.maxMembers;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Current Cycle Progress
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Current Cycle Progress',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        daysText,
                        style: TextStyle(
                          color: daysRemaining <= 3 ? Colors.red : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: progressData['percentage'] / 100,
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation(Colors.green),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Cycle ${progressData['currentCycle']} of ${progressData['totalSlots']}',
                      ),
                      Text(
                        '${progressData['percentage'].toStringAsFixed(1)}% complete',
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatCurrency(progressData['collected']) +
                            ' collected',
                      ),
                      Text(
                        _formatCurrency(progressData['expected']) + ' total',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Next Payout and Slot Payment cards in a row
          Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Next Payout',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        if (group.nextPayOut?.isNotEmpty ?? false) ...[
                          ...group.nextPayOut!.map(
                            (payout) => Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: Colors.green[50],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.monetization_on,
                                        size: 18,
                                        color: Colors.green,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Position ${payout.position}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            '${payout.memberName} • ${payout.slotValue} slot(s)',
                                          ),
                                          Text(
                                            _formatCurrency(
                                              group.contributionAmount *
                                                  (payout.slotValue ?? 0),
                                            ),
                                            style: const TextStyle(
                                              color: Colors.green,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                              ],
                            ),
                          ),
                          const Divider(),
                          Text(
                            'Total payout: ${_formatCurrency(totalPayoutAmount)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ] else ...[
                          const Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.emoji_events,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 8),
                                Text('No Payout Scheduled'),
                                SizedBox(height: 4),
                                Text(
                                  'Payout order will be determined when group starts',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Slot Payment',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Total Pot: ${_formatCurrency(totalPayoutAmount)}',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Start: ${_formatDate(group.startDate)}'),
                        if (group.endDate != null)
                          Text('End: ${_formatDate(group.endDate!)}'),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Chip(
                              label: Text(
                                '${group.approvedMembersCount} members',
                              ),
                            ),
                            Chip(label: Text('${group.maxMembers} max')),
                            Chip(
                              label: Text('${group.remainingSlots} slots left'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Group Info and Rules
          Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Group Info',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          'Private Group:',
                          group.isPrivate ? 'Yes' : 'No',
                        ),
                        _buildInfoRow(
                          'Allow Pairing:',
                          group.allowPairing ? 'Yes' : 'No',
                        ),
                        _buildInfoRow(
                          'Require Approval:',
                          group.requireApproval ? 'Yes' : 'No',
                        ),
                        _buildInfoRow('Payout Order:', group.payoutOrder),
                        _buildInfoRow(
                          'Remaining Slots:',
                          group.remainingSlots.toString(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Group Rules',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '• Contributions due every ${group.contributionFrequency}',
                        ),
                        Text('• Late payments incur 1% penalty (max ₦1,000)'),
                        Text('• Max 3 missed payments allowed'),
                        Text('• Payout order: ${group.payoutOrder}'),
                        Text('• Group status: ${group.status ?? 'N/A'}'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildMembersTab(GroupDetails group) {
    final filteredMembers = group.members.where((member) {
      final searchLower = _searchTerm.toLowerCase();
      return (member.firstName).toLowerCase().contains(searchLower) ||
          (member.lastName).toLowerCase().contains(searchLower) ||
          member.email.toLowerCase().contains(searchLower);
    }).toList();

    return Column(
      children: [
        _buildSearchBar(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredMembers.length,
            itemBuilder: (context, index) {
              final member = filteredMembers[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: member.imageVerification != null
                        ? NetworkImage(member.imageVerification!)
                        : null,
                    child: member.imageVerification == null
                        ? Text('${member.firstName[0]}${member.lastName[0]}')
                        : null,
                  ),
                  title: Row(
                    children: [
                      Text('${member.firstName} ${member.lastName}'),
                      if (member.isCurrentUser) ...[
                        const SizedBox(width: 8),
                        Chip(
                          label: const Text('You'),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(member.email),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        children: [
                          Chip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _getRoleIcon(member.role),
                                const SizedBox(width: 4),
                                Text(member.role),
                              ],
                            ),
                            backgroundColor: _getRoleColor(
                              member.role,
                            ).withOpacity(0.1),
                          ),
                          Chip(
                            label: Text(member.status),
                            backgroundColor: _getStatusColor(
                              member.status,
                            ).withOpacity(0.1),
                          ),
                          Chip(label: Text('${member.slots} slot(s)')),
                          if (member.isAssignedInPayout)
                            Chip(
                              label: const Text('In Payout Order'),
                              backgroundColor: Colors.green.withOpacity(0.1),
                            ),
                        ],
                      ),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatCurrency(member.totalContributions),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${member.contributionCount ?? 0} contributions',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTab() {
    return Column(
      children: [
        // Tabs within settings
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              if (_isAdmin)
                Expanded(
                  child: _buildSettingsTabButton('Pending Requests', 'pending'),
                ),
              Expanded(
                child: _buildSettingsTabButton('Slot Management', 'slots'),
              ),
              if (_isAdmin)
                Expanded(
                  child: _buildSettingsTabButton('Settings', 'settings'),
                ),
            ],
          ),
        ),

        // Content based on selected settings tab
        Expanded(
          child: _settingsTab == 'pending'
              ? _buildPendingRequestsTab()
              : _settingsTab == 'slots'
              ? _buildSlotManagementTab()
              : _buildAdminSettingsTab(),
        ),
      ],
    );
  }

  Widget _buildSettingsTabButton(String label, String tab) {
    final isSelected = _settingsTab == tab;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _settingsTab = tab),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? Colors.blue : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.blue : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPendingRequestsTab() {
    final filteredRequests = _joinRequests.where((request) {
      final searchLower = _searchTerm.toLowerCase();
      final fullName = '${request.user.firstName} ${request.user.lastName}'
          .toLowerCase();
      return fullName.contains(searchLower) ||
          request.user.email.toLowerCase().contains(searchLower);
    }).toList();

    return Column(
      children: [
        _buildSearchBar(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredRequests.length,
            itemBuilder: (context, index) {
              final request = filteredRequests[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundImage:
                                    request.user.imageVerification.isNotEmpty
                                    ? NetworkImage(
                                        request.user.imageVerification,
                                      )
                                    : null,
                                child: request.user.imageVerification.isEmpty
                                    ? Text(
                                        '${request.user.firstName[0]}${request.user.lastName[0]}',
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${request.user.firstName} ${request.user.lastName}',
                                  ),
                                  Text(
                                    request.user.email,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          PopupMenuButton(
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'approve',
                                child: Text('Approve Request'),
                              ),
                              const PopupMenuItem(
                                value: 'reject',
                                child: Text('Reject Request'),
                              ),
                            ],
                            onSelected: (value) =>
                                _handleRequestAction(request, value as String),
                          ),
                        ],
                      ),
                      if (request.message != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          '"${request.message!}"',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          Chip(
                            label: Text('${request.slots} slot(s)'),
                            backgroundColor: Colors.blue[50],
                          ),
                          Chip(
                            label: Text(request.status),
                            backgroundColor: _getStatusColor(
                              request.status.toUpperCase(),
                            ).withOpacity(0.1),
                          ),
                          Chip(
                            label: Text(_formatDate(request.createdAt)),
                            backgroundColor: Colors.grey[100],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSlotManagementTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payout Order',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isPayoutOrderEditable
                        ? 'Arrange members in payout order. Each position holds exactly 1.0 total slot value.'
                        : 'Payout order is automatically managed by ${_groupProvider?.currentGroup?.payoutOrder} system.',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),

                  if (_isPayoutOrderEditable)
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _createNewPayoutSlot,
                            icon: const Icon(Icons.add),
                            label: const Text('Add Position'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isFinalizingGroup
                                ? null
                                : _finalizeGroup,
                            icon: _isFinalizingGroup
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.check_circle),
                            label: const Text('Save & Finalize'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 24),

                  // Stats
                  Row(
                    children: [
                      _buildStatCard(
                        'Positions',
                        _payoutSlots.length.toString(),
                      ),
                      _buildStatCard(
                        'Full',
                        _payoutSlots.where((s) => s.isFull).length.toString(),
                      ),
                      _buildStatCard(
                        'Available',
                        _availableMembers.length.toString(),
                      ),
                      _buildStatCard(
                        'Assigned',
                        _payoutSlots
                            .fold(0, (sum, slot) => sum + slot.members.length)
                            .toString(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Payout slots
                  Text(
                    _isPayoutOrderEditable
                        ? 'Manage Payout Order'
                        : 'Current Payout Order',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  if (_payoutSlots.isEmpty)
                    Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.grid_view,
                            size: 40,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _isPayoutOrderEditable
                                ? 'No payout positions created yet. Add positions to arrange the payout order.'
                                : 'No payout positions have been set yet.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.grey),
                          ),
                          if (_isPayoutOrderEditable) ...[
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _createNewPayoutSlot,
                              child: const Text('Create First Position'),
                            ),
                          ],
                        ],
                      ),
                    )
                  else
                    Column(
                      children: _payoutSlots
                          .map((slot) => _buildSlotDisplayWidget(slot))
                          .toList(),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotDisplayWidget(PayoutSlot slot) {
    final availableSpace = 1 - slot.totalValue;
    final canAddMember = availableSpace > 0 && _isPayoutOrderEditable;
    final group = _groupProvider?.currentGroup;
    final allowPairing = group?.allowPairing ?? false;

    return Card(
      color: slot.isFull ? Colors.green[50] : Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          slot.position.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Position ${slot.position}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Wrap(
                          spacing: 8,
                          children: [
                            Chip(
                              label: Text(
                                '${slot.totalValue.toStringAsFixed(1)}/1.0 filled',
                              ),
                            ),
                            if (slot.isFull)
                              const Icon(
                                Icons.check_circle,
                                size: 16,
                                color: Colors.green,
                              ),
                            Chip(
                              label: Text(
                                '${slot.members.length} member${slot.members.length != 1 ? 's' : ''}',
                              ),
                            ),
                            if (!_isPayoutOrderEditable)
                              const Chip(label: Text('View Only')),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                if (_isPayoutOrderEditable)
                  IconButton(
                    onPressed: () => _deletePayoutSlot(slot.id),
                    icon: const Icon(Icons.delete, color: Colors.red),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Assigned Members:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (slot.members.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey,
                    style: BorderStyle.solid,

                    //todo:   BorderStyle.dashed,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.people, size: 40, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('No members assigned'),
                  ],
                ),
              )
            else
              Column(
                children: slot.members.map((slotMember) {
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage:
                          slotMember.member.imageVerification != null
                          ? NetworkImage(slotMember.member.imageVerification!)
                          : null,
                      child: slotMember.member.imageVerification == null
                          ? Text(
                              '${slotMember.member.firstName[0]}${slotMember.member.lastName[0]}',
                            )
                          : null,
                    ),
                    title: Text(
                      '${slotMember.member.firstName} ${slotMember.member.lastName}',
                    ),
                    subtitle: Row(
                      children: [
                        Chip(
                          label: Text(
                            '${slotMember.slotValue} slot${slotMember.slotValue != 1 ? 's' : ''}',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${slotMember.member.slots} total',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    trailing: _isPayoutOrderEditable
                        ? IconButton(
                            onPressed: () => _removeMemberFromSlot(
                              slot.id,
                              slotMember.member.userId,
                            ),
                            icon: const Icon(
                              Icons.person_remove,
                              color: Colors.red,
                            ),
                          )
                        : null,
                  );
                }).toList(),
              ),
            const SizedBox(height: 16),
            if (canAddMember) _buildAddMemberToSlotWidget(slot, allowPairing),
          ],
        ),
      ),
    );
  }

  Widget _buildAddMemberToSlotWidget(PayoutSlot slot, bool allowPairing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Add Member:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ..._availableMembers
            .where((member) {
              final used = _memberUsedSlots[member.userId] ?? 0;
              final available = member.slots - used;
              final memberSlotValue = member.slots;
              final availableSpace = 1 - slot.totalValue;

              if (memberSlotValue == 0.5 &&
                  available >= 0.5 &&
                  availableSpace >= 0.5) {
                return true;
              }
              if (memberSlotValue >= 1 &&
                  available >= 1 &&
                  availableSpace >= 1) {
                return true;
              }
              if (memberSlotValue % 1 != 0 &&
                  available >= 0.5 &&
                  availableSpace >= 0.5 &&
                  allowPairing) {
                return true;
              }
              return false;
            })
            .map((member) {
              final used = _memberUsedSlots[member.userId] ?? 0;
              final available = member.slots - used;
              final memberSlotValue = member.slots;

              List<double> assignableValues = [];
              if (memberSlotValue == 0.5) {
                assignableValues = [0.5];
              } else if (memberSlotValue >= 1 && memberSlotValue % 1 == 0) {
                assignableValues = [1];
              } else if (memberSlotValue % 1 != 0 && allowPairing) {
                if (available >= 1 && (1 - slot.totalValue) >= 1)
                  assignableValues.add(1);
                if (available >= 0.5 && (1 - slot.totalValue) >= 0.5)
                  assignableValues.add(0.5);
              }

              if (assignableValues.isEmpty) return const SizedBox();

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: member.imageVerification != null
                      ? NetworkImage(member.imageVerification!)
                      : null,
                  child: member.imageVerification == null
                      ? Text('${member.firstName[0]}${member.lastName[0]}')
                      : null,
                ),
                title: Text('${member.firstName} ${member.lastName}'),
                subtitle: Text(
                  '${available.toStringAsFixed(1)} available • ${member.slots} total',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: assignableValues.map((value) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: ElevatedButton(
                        onPressed: () =>
                            _addMemberToSlot(slot.id, member, value),
                        style: value == 1
                            ? ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                              )
                            : ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey,
                              ),
                        child: Text('Add ${value.toStringAsFixed(1)}'),
                      ),
                    );
                  }).toList(),
                ),
              );
            })
            .toList(),
      ],
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminSettingsTab() {
    final group = _groupProvider?.currentGroup!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Communication Settings',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Control how members can communicate within the group',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),

                // Allow Group Messages
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Allow Group Messages',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Members can send messages in group chat',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: group?.allowGroupMessaging ?? false,
                      onChanged: (value) {
                        // Handle group messaging change
                      },
                    ),
                  ],
                ),

                const Divider(height: 32),

                // Allow Video Calling
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Allow Video Calling',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Members can start video calls within the group',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: group?.allowVideoCalling ?? false,
                      onChanged: (value) {
                        // Handle video call change
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildJoinButton(GroupDetails group) {
    if (group.currentUserRole != "GUEST") {
      return Container(
        padding: const EdgeInsets.all(16),
        color: Colors.green,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shield, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              _isAdmin
                  ? "You're the admin of this group!"
                  : "You're a member of this group!",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: _joinGroup,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_add),
            const SizedBox(width: 8),
            Text(
              'Join Group • ${_formatCurrency(group.contributionAmount)}/${group.contributionFrequency}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartGroupButton() {
    if (_isForming &&
        _groupProvider?.currentGroup?.canStart == true &&
        _isAdmin) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: _startGroup,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
          ),
          child: const Text(
            'Start Group',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
    return const SizedBox();
  }

  void _showLeaveGroupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Group'),
        content: const Text(
          'Are you sure you want to leave this group? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _leaveGroup();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Leave Group'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final group = _groupProvider?.currentGroup;

    if (_isLoading && group == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (group == null && !_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Group Not Found')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Group not found'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Back to Community'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          // Header
          _buildHeader(group!),

          // Stats
          _buildStats(group),

          // Tabs
          _buildTabs(),

          // Search bar (conditionally)
          if (_activeTab == "members" || (_activeTab == "settings" && _isAdmin))
            _buildSearchBar(),

          // Content
          Expanded(
            child: _activeTab == "overview"
                ? _buildOverviewTab(group)
                : _activeTab == "members"
                ? _buildMembersTab(group)
                : _buildSettingsTab(),
          ),

          // Bottom buttons
          if (group.currentUserRole == "GUEST") _buildJoinButton(group),
          if (_isForming && group.canStart && _isAdmin)
            _buildStartGroupButton(),
        ],
      ),
    );
  }
}
