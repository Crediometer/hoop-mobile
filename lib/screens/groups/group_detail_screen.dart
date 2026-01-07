import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:hoop/constants/themes.dart';
import 'package:hoop/dtos/responses/group/index.dart';
import 'package:hoop/services/group_services.dart';
import 'package:hoop/states/group_state.dart';
import 'package:hoop/utils/helpers/formatters/hoop_formatter.dart';
import 'package:provider/provider.dart';

class GroupDetailScreen extends StatefulWidget {
  final Map<String, dynamic> group;

  const GroupDetailScreen({super.key, required this.group});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  int selectedTab = 0; // 0 = Overview, 1 = Members, 2 = Settings

  // States
  bool _isLoading = false;
  bool _isProcessingAction = false;
  bool _isLoadingMembers = false;
  bool _isLoadingRequests = false;

  // Data
  GroupDetails? _group;
  List<GroupMember> _members = [];
  List<JoinRequest> _joinRequests = [];
  List<dynamic> _nextPayout = [];

  // Search
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadGroupData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadGroupData() async {
    try {
      setState(() => _isLoading = true);

      final groupId = widget.group['id'];
      if (groupId == null) return;

      // Load group details
      final provider = Provider.of<GroupCommunityProvider>(
        context,
        listen: false,
      );
      final groupResponse = await provider.getGroup(groupId.toString());

      if (groupResponse.success && groupResponse.data != null) {
        setState(() => _group = groupResponse.data);

        // Load members
        await _loadMembers();

        // Load join requests if admin
        if (_group?.currentUserRole == "OWNER" ||
            _group?.currentUserRole == "ADMIN") {
          await _loadJoinRequests();
        }

        // Load payout order if available
        await _loadPayoutOrder();
      }
    } catch (e) {
      log('Error loading group data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMembers() async {
    try {
      setState(() => _isLoadingMembers = true);

      if (_group?.members != null) {
        setState(() => _members = _group!.members!);
      }
    } catch (e) {
      log('Error loading members: $e');
    } finally {
      setState(() => _isLoadingMembers = false);
    }
  }

  Future<void> _loadJoinRequests() async {
    try {
      setState(() => _isLoadingRequests = true);
      final groupId = _group?.id.toString();
      if (groupId == null) return;

      final service = GroupHttpService();
      final response = await service.getGroupJoinRequests(groupId);

      if (response.success && response.data != null) {
        // setState(() => _joinRequests = response.data!);
      }
    } catch (e) {
      log('Error loading join requests: $e');
    } finally {
      setState(() => _isLoadingRequests = false);
    }
  }

  Future<void> _loadPayoutOrder() async {
    try {
      final groupId = _group?.id.toString();
      if (groupId == null) return;

      final service = GroupHttpService();
      final response = await service.getPayoutOrderGroup(groupId);

      if (response.success && response.data != null) {
        setState(() => _nextPayout = response.data!['payoutOrder'] ?? []);
      }
    } catch (e) {
      log('Error loading payout order: $e');
    }
  }

  Future<void> _handleStartGroup() async {
    try {
      setState(() => _isProcessingAction = true);
      final groupId = _group?.id.toString();
      if (groupId == null) return;

      final provider = Provider.of<GroupCommunityProvider>(
        context,
        listen: false,
      );
      final response = await provider.startGroup(groupId);

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Group started successfully!'),
            backgroundColor: HoopTheme.successGreen,
          ),
        );
        await _loadGroupData();
      }
    } catch (e) {
      log('Error starting group: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start group'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isProcessingAction = false);
    }
  }

  Future<void> _handleLeaveGroup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Leave Group'),
        content: Text('Are you sure you want to leave ${_group?.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Leave', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      setState(() => _isProcessingAction = true);
      final groupId = _group?.id.toString();
      if (groupId == null) return;

      final service = GroupHttpService();
      final response = await service.leaveGroup(groupId);

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You have left ${_group?.name}'),
            backgroundColor: HoopTheme.successGreen,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      log('Error leaving group: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to leave group'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isProcessingAction = false);
    }
  }

  Future<void> _handleRequestAction(String requestId, String action) async {
    try {
      setState(() => _isProcessingAction = true);
      final groupId = _group?.id.toString();
      if (groupId == null) return;

      final service = GroupHttpService();

      if (action == 'approve') {
        await service.approveGroupRequest(groupId, requestId);
      } else {
        await service.rejectGroupRequest(groupId, requestId);
      }

      setState(() {
        _joinRequests.removeWhere((req) => req.id.toString() == requestId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Join request ${action}d'),
          backgroundColor: HoopTheme.successGreen,
        ),
      );

      // Refresh group data
      await _loadGroupData();
    } catch (e) {
      log('Error processing request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to process request'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isProcessingAction = false);
    }
  }

  Color _getAvatarColor(String id) {
    final colors = [
      const Color(0xFF9C27B0),
      const Color(0xFFE91E63),
      const Color(0xFFF44336),
      const Color(0xFF00BCD4),
      const Color(0xFF4CAF50),
      const Color(0xFFFF9800),
      const Color(0xFF2196F3),
      const Color(0xFF673AB7),
      const Color(0xFFFF5722),
      const Color(0xFF795548),
    ];
    final index = id.hashCode.abs() % colors.length;
    return colors[index];
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case "APPROVED":
        return HoopTheme.successGreen;
      case "PENDING":
        return HoopTheme.vibrantOrange;
      case "REJECTED":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String dateString) {
    try {
      return HoopFormatters.formatTimeAgo(dateString);
    } catch (e) {
      return dateString;
    }
  }

  String _getProgressSubtitle(GroupDetails? group) {
    if (group == null) return '0 days left';

    try {
      final nextPayout = group.nextPayoutDate;
      if (nextPayout == null) return 'No payout scheduled';

      final targetDate = DateTime.parse(nextPayout);
      final today = DateTime.now();
      final difference = targetDate.difference(today);
      final days = difference.inDays;

      if (days > 0) return '$days days left';
      if (days == 0) return 'Today';
      return '${days.abs()} days overdue';
    } catch (e) {
      return 'Soon';
    }
  }

  double _getProgressValue(GroupDetails? group) {
    if (group == null) return 0.0;

    final currentCycle = group.currentCycle ?? 0;
    final totalSlots = group.maxMembers ?? 1;

    if (totalSlots == 0) return 0.0;
    return (currentCycle / totalSlots).clamp(0.0, 1.0);
  }

  // Filtered data getters
  List<GroupMember> get _filteredMembers {
    if (_searchQuery.isEmpty) return _members;

    final query = _searchQuery.toLowerCase();
    return _members.where((member) {
      final name = '${member.firstName} ${member.lastName}'.toLowerCase();
      final email = member.email?.toLowerCase() ?? '';
      return name.contains(query) || email.contains(query);
    }).toList();
  }

  List<JoinRequest> get _filteredRequests {
    if (_searchQuery.isEmpty) return _joinRequests;

    final query = _searchQuery.toLowerCase();
    return _joinRequests.where((request) {
      final name = '${request.user.firstName} ${request.user.lastName}'
          .toLowerCase();
      final email = request.user.email.toLowerCase();

      return name.contains(query) || email.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : Colors.black;
    final textSecondary = isDark ? Colors.grey[400] : Colors.grey[600];
    final textTertiary = isDark ? Colors.grey[500] : Colors.grey[500];

    // Use actual group data or fallback to widget data
    final GroupDetails displayGroup = _group ?? GroupDetails();
    final groupName = displayGroup is Group
        ? displayGroup.name
        : displayGroup.name ?? 'Group';
    final description = displayGroup is Group
        ? displayGroup.description
        : displayGroup.description ?? '';
    final location = displayGroup is Group
        ? displayGroup.location
        : displayGroup.location ?? '';
    final membersCount = displayGroup is Group
        ? displayGroup.approvedMembersCount
        : 0;
    final maxMembers = displayGroup is Group ? displayGroup.maxMembers : 0;
    final contributionAmount = displayGroup is Group
        ? displayGroup.contributionAmount
        : 0;
    final frequency = displayGroup is Group
        ? displayGroup.contributionFrequency
        : '';
    final isAdmin =
        displayGroup is Group &&
        (displayGroup.currentUserRole == "OWNER" ||
            displayGroup.currentUserRole == "ADMIN");
    final isMember =
        displayGroup is Group && displayGroup.currentUserRole != "GUEST";
    final canStart = displayGroup is Group && displayGroup.canStart == true;
    final isForming =
        displayGroup is Group &&
        displayGroup.status?.toLowerCase() == 'forming';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F111A) : Colors.grey[50],
      body: SingleChildScrollView(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // GRADIENT HEADER WITH BACK BUTTON - GREEN GRADIENT
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 34),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back button and settings icon
                      SizedBox(height: 34.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: isAdmin
                                ? () {
                                    // Navigate to invite screen
                                    Navigator.pushNamed(
                                      context,
                                      '/group/invite',
                                      arguments: displayGroup.id.toString(),
                                    );
                                  }
                                : null,
                            child: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: const Color(0xFF4A148C),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.people_outline,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Group name
                      Text(
                        groupName ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Members + Location
                      Row(
                        children: [
                          const Icon(
                            Icons.people_outline,
                            size: 16,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "$membersCount / $maxMembers members",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 20),
                          const Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              (location != null) && (location ?? '').isNotEmpty
                                  ? location
                                  : "Location not specified",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Group ID / Description
                      Text(
                        (description != null) && description.isNotEmpty
                            ? description
                            : "No description available",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 64),

                // TAB BUTTONS (Overview | Members | Settings)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1A1D27) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      _buildTabButton("Overview", Icons.bar_chart, 0, isDark),
                      _buildTabButton("Members", Icons.people, 1, isDark),
                      _buildTabButton("Settings", Icons.settings, 2, isDark),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // TAB CONTENT
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: selectedTab == 0
                      ? _buildOverviewTab(
                          isDark,
                          textPrimary,
                          textSecondary,
                          textTertiary,
                          displayGroup,
                        )
                      : selectedTab == 1
                      ? _buildMembersTab(isDark, textPrimary, textSecondary)
                      : _buildSettingsTab(
                          isDark,
                          textPrimary,
                          textSecondary,
                          isAdmin,
                        ),
                ),

                const SizedBox(height: 20),

                // Action buttons at bottom
                if (isMember && isForming && canStart && isAdmin)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildStartButton(),
                  ),

                const SizedBox(height: 20),
              ],
            ),
            // CONTRIBUTION + CYCLE CHIPS WITH YELLOW BORDER
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 200),
              child: Container(
                child: Row(
                  children: [
                    // Contribution chip
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1A1D27)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  "💵",
                                  style: TextStyle(fontSize: 20),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Contribution",
                                  style: TextStyle(
                                    color: textTertiary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "₦${contributionAmount?.toStringAsFixed(0)}",
                              style: TextStyle(
                                color: const Color(0xFF4CAF50),
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Cycle chip
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1A1D27)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  "⏱️",
                                  style: TextStyle(fontSize: 20),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Cycle",
                                  style: TextStyle(
                                    color: textTertiary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              frequency ?? '',
                              style: TextStyle(
                                color: const Color(0xFF9C27B0),
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String label, IconData icon, int index, bool isDark) {
    final isSelected = selectedTab == index;
    final textColor = isDark ? Colors.white : Colors.black;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF2D3139) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? const Color(0xFF6366F1) : Colors.grey[500],
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? textColor : Colors.grey[500],
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewTab(
    bool isDark,
    Color textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    GroupDetails groupData,
  ) {
    final progressSubtitle = _getProgressSubtitle(
      groupData is GroupDetails ? groupData : null,
    );
    final progressValue = _getProgressValue(
      groupData is GroupDetails ? groupData : null,
    );
    final totalPayout = groupData is Group
        ? (groupData.contributionAmount ?? 1) * (groupData.maxMembers ?? 1)
        : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Current Cycle Progress
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Current Cycle Progress",
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  progressSubtitle,
                  style: TextStyle(color: textSecondary, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progressValue,
                minHeight: 8,
                backgroundColor: isDark ? Colors.white10 : Colors.grey[300],
                valueColor: AlwaysStoppedAnimation(const Color(0xFF4CAF50)),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "₦${(totalPayout * progressValue).toStringAsFixed(0)} collected",
                  style: TextStyle(
                    color: const Color(0xFF4CAF50),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  "₦${totalPayout.toStringAsFixed(0)} goal",
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Next Payout
        if (_nextPayout.isNotEmpty)
          Column(
            children: _nextPayout.map((payout) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1D27) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isDark
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 18,
                          color: const Color(0xFFE67E22),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Next Payout",
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${payout['memberName']} • ${_formatDate(payout['assignedAt'])}",
                      style: TextStyle(color: textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              );
            }).toList(),
          )
        else
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1D27) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 18,
                      color: const Color(0xFFE67E22),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Next Payout",
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "No payout scheduled yet",
                  style: TextStyle(color: textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),

        const SizedBox(height: 12),

        // Slot Payment
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1D27) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Slot Payment",
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "No payout schedule yet — will be based on slots",
                style: TextStyle(color: textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Total Pot:",
                    style: TextStyle(color: textTertiary, fontSize: 12),
                  ),
                  Text(
                    "₦${totalPayout.toStringAsFixed(0)}",
                    style: TextStyle(
                      color: const Color(0xFF4CAF50),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Start: ${groupData is Group ? _formatDate(groupData.startDate ?? '') : 'N/A'}",
                    style: TextStyle(color: textTertiary, fontSize: 12),
                  ),
                  Text(
                    groupData is Group && groupData.endDate != null
                        ? "End: ${_formatDate(groupData.endDate!)}"
                        : "No end date",
                    style: TextStyle(color: textTertiary, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Group Info
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1D27) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: Colors.grey[500]),
                  const SizedBox(width: 8),
                  Text(
                    "Group Info",
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _infoRow(
                "Private Group:",
                (groupData is Group && groupData.isPrivate == true)
                    ? "Yes"
                    : "No",
                textTertiary,
              ),
              const SizedBox(height: 8),
              _infoRow(
                "Allow Pairing:",
                (groupData is Group && groupData.allowPairing == true)
                    ? "Yes"
                    : "No",
                textTertiary,
              ),
              const SizedBox(height: 8),
              _infoRow(
                "Payout Order:",
                (groupData is Group && groupData.payoutOrder != null)
                    ? groupData.payoutOrder!
                    : "Not set",
                textTertiary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value, Color? color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: color, fontSize: 12)),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildMembersTab(
    bool isDark,
    Color textPrimary,
    Color? textSecondary,
  ) {
    if (_isLoadingMembers) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: CircularProgressIndicator(color: HoopTheme.primaryRed),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search bar
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1D27) : Colors.grey[100],
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.grey[300] ?? Colors.grey,
              width: 1,
            ),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            style: TextStyle(color: textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: "Search members...",
              hintStyle: TextStyle(color: textSecondary, fontSize: 14),
              border: InputBorder.none,
              prefixIcon: Icon(Icons.search, color: textSecondary, size: 20),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),

        // Members list
        if (_filteredMembers.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(Icons.people_outline, size: 48, color: textSecondary),
                  const SizedBox(height: 16),
                  Text(
                    "No members found",
                    style: TextStyle(color: textSecondary),
                  ),
                ],
              ),
            ),
          )
        else
          Column(
            children: _filteredMembers.map((member) {
              final initials = HoopFormatters.getInitials(
                '${member.firstName} ${member.lastName}',
              );
              final avatarColor = _getAvatarColor(member.userId);
              final statusColor = _getStatusColor(member.status ?? '');
              final isCurrentUser = false; // You'll need to implement this

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1D27) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? Colors.white10
                        : Colors.grey[200] ?? Colors.grey,
                    width: 1,
                  ),
                  boxShadow: isDark
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row with avatar and role
                    Row(
                      children: [
                        // Avatar
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: avatarColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              initials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Name and email
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${member.firstName} ${member.lastName}',
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                member.email ?? '',
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Contribution badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF2D3139)
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${member.contributionCount ?? 0} contributions',
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Role and status badges
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        // Role badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                member.role == "ADMIN" || member.role == "OWNER"
                                ? Colors.orange.withOpacity(0.1)
                                : Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                member.role == "ADMIN" || member.role == "OWNER"
                                    ? Icons.emoji_events
                                    : Icons.person,
                                size: 12,
                                color:
                                    member.role == "ADMIN" ||
                                        member.role == "OWNER"
                                    ? Colors.orange
                                    : Colors.green,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                member.role ?? 'MEMBER',
                                style: TextStyle(
                                  color:
                                      member.role == "ADMIN" ||
                                          member.role == "OWNER"
                                      ? Colors.orange
                                      : Colors.green,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            member.status?.toUpperCase() ?? 'ACTIVE',
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),

                        // Slots badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${member.slots ?? 1} slot(s)',
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Contribution amount
                    Text(
                      '₦${member.totalContributions?.toStringAsFixed(0) ?? '0'} contributed',
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

        const SizedBox(height: 20),

        // Start Group button (only for admins in forming groups)
        if (_group?.currentUserRole == "OWNER" ||
            _group?.currentUserRole == "ADMIN")
          if (_group?.status?.toLowerCase() == 'forming' &&
              _group?.canStart == true)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessingAction ? null : _handleStartGroup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isProcessingAction
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        "Start Group",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
      ],
    );
  }

  Widget _buildSettingsTab(
    bool isDark,
    Color textPrimary,
    Color? textSecondary,
    bool isAdmin,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Group Settings",
          style: TextStyle(
            color: textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),

        // Communication settings (only for admins)
        if (isAdmin && _group != null)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1D27) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                      ),
                    ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Communication",
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                _settingSwitch(
                  "Allow Group Messages",
                  _group?.allowGroupMessaging ?? false,
                  (value) {
                    // Handle group messaging change
                    final provider = Provider.of<GroupCommunityProvider>(
                      context,
                      listen: false,
                    );
                    provider.handleAllowGroupMessagingChange(value);
                  },
                  isDark,
                  textSecondary,
                ),
                const Divider(),
                _settingSwitch(
                  "Allow Video Calls",
                  _group?.allowVideoCall ?? false,
                  (value) {
                    // Handle video call change
                    final provider = Provider.of<GroupCommunityProvider>(
                      context,
                      listen: false,
                    );
                    provider.handleAllowVideoCallChange(value);
                  },
                  isDark,
                  textSecondary,
                ),
              ],
            ),
          ),

        // Join requests section (only for admins)
        if (isAdmin && _joinRequests.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1D27) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                      ),
                    ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Pending Requests",
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "${_joinRequests.length}",
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ..._joinRequests.take(3).map((request) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${request.user.firstName} ${request.user.lastName}",
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              request.user.email,
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => _handleRequestAction(
                                request.id.toString(),
                                'approve',
                              ),
                              icon: Icon(
                                Icons.check,
                                size: 18,
                                color: Colors.green,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(),
                            ),
                            IconButton(
                              onPressed: () => _handleRequestAction(
                                request.id.toString(),
                                'reject',
                              ),
                              icon: Icon(
                                Icons.close,
                                size: 18,
                                color: Colors.red,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
                if (_joinRequests.length > 3)
                  TextButton(
                    onPressed: () {
                      // Show all requests dialog
                    },
                    child: Text(
                      "View all requests",
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),

        // Danger zone
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1D27) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                    ),
                  ],
          ),
          child: Column(
            children: [
              _settingRow(
                "Leave Group",
                Icons.exit_to_app_outlined,
                isDark,
                textPrimary,
                Colors.red,
                onTap: _handleLeaveGroup,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _settingSwitch(
    String label,
    bool value,
    Function(bool) onChanged,
    bool isDark,
    Color? textSecondary,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF6366F1),
        ),
      ],
    );
  }

  Widget _settingRow(
    String label,
    IconData icon,
    bool isDark,
    Color textPrimary,
    Color? color, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[500]),
        ],
      ),
    );
  }

  Widget _buildStartButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isProcessingAction ? null : _handleStartGroup,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6366F1),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _isProcessingAction
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                "Start Group",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}
