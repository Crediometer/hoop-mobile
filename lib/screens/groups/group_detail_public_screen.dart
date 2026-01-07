import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:hoop/components/buttons/primary_button.dart';
import 'package:hoop/constants/themes.dart';
import 'package:hoop/dtos/responses/group/index.dart';
import 'package:hoop/screens/groups/join_group_modal.dart';
import 'package:hoop/services/group_services.dart';
import 'package:hoop/states/group_state.dart';
import 'package:hoop/utils/helpers/formatters/hoop_formatter.dart';
import 'package:provider/provider.dart';

class GroupDetailPublicScreen extends StatefulWidget {
  final Map<String, dynamic> group;

  const GroupDetailPublicScreen({super.key, required this.group});

  @override
  State<GroupDetailPublicScreen> createState() =>
      _GroupDetailPublicScreenState();
}

class _GroupDetailPublicScreenState extends State<GroupDetailPublicScreen> {
  int selectedTab = 0; // 0 = Overview, 1 = Members, 2 = Settings

  // States
  bool _isLoading = false;
  bool _isProcessingAction = false;
  bool _isLoadingMembers = false;
  bool _isLoadingRequests = false;

  // Data
  GroupDetailsPublic? _group;
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
      final groupResponse = await provider.getPublicGroup(groupId.toString());

      if (groupResponse.success && groupResponse.data != null) {
        setState(() => _group = groupResponse.data);
      }
    } catch (e) {
      log('Error loading group data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleJoinGroup(slots, message) async {
    try {
      setState(() => _isProcessingAction = true);
      final groupId = _group?.group.id.toString();
      if (groupId == null) return;

      final provider = Provider.of<GroupCommunityProvider>(
        context,
        listen: false,
      );
      final response = await provider.joinGroup(
        groupId,
        slots: slots,
        message: message,
      );

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully joined ${_group?.group.name}!'),
            backgroundColor: HoopTheme.successGreen,
          ),
        );
        await _loadGroupData();
      }
    } catch (e) {
      log('Error joining group: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to join group'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isProcessingAction = false);
    }
  }

  Future<void> _handleStartGroup() async {
    try {
      setState(() => _isProcessingAction = true);
      final groupId = _group?.group.id.toString();
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : Colors.black;
    final textSecondary = isDark ? Colors.grey[400] : Colors.grey[600];
    final textTertiary = isDark ? Colors.grey[500] : Colors.grey[500];

    // Use actual group data or fallback to widget data
    final Group? displayGroup = _group?.group;
    final groupName = displayGroup?.name ?? 'Group';
    final description = displayGroup?.description ?? '';
    final location = displayGroup?.location ?? '';
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
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back button and settings icon
                      SizedBox(height: 34.0),
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

                      const SizedBox(height: 16),

                      // Status badge + rating (pill-shaped)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (displayGroup is Group &&
                                displayGroup.requireApproval == true)
                              const Text(
                                "Approval Required",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            if (displayGroup is Group &&
                                displayGroup.requireApproval == true)
                              const SizedBox(width: 8),
                            const Text(
                              "⭐ 4.8",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

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
                      : _buildMembersTab(isDark, textPrimary, textSecondary),
                ),

                const SizedBox(height: 20),

                // Action buttons at bottom
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: HoopButton(
                    buttonText:
                        "Join Group • ₦${contributionAmount?.toStringAsFixed(0)}/$frequency",
                    isLoading: _isProcessingAction,
                    onPressed: () {
                      // Show the modal
                      JoinGroupModal.show(
                        context: context,
                        group: {
                          'allowPairing': true,
                          'availableSlots': 10,
                          'maxSlotsPerUser': 5,
                          'contributionAmount': 50000,
                        },
                        onJoin: (slots, message) async {
                          _handleJoinGroup(slots, message);
                        },
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),

            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 220),
              child: Container(
                child: Row(
                  children: [
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
    Group? groupData,
  ) {
    final totalPayout =
        (groupData?.contributionAmount ?? 1) * (groupData?.maxMembers ?? 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),

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
                    groupData is Group && groupData.cycleDurationDays != null
                        ? "End: ${_formatDate(groupData.cycleDurationDays.toString()!)}"
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
                  Icon(Icons.security, size: 18, color: Colors.grey[500]),
                  const SizedBox(width: 8),
                  Text(
                    "Group Rules",
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _infoRow("Contributions due", "5 days", textTertiary),
              const SizedBox(height: 8),
              _infoRow(
                "Late payments incur 1% penalty",
                "(max ₦1,000)",
                textTertiary,
              ),
              const SizedBox(height: 8),
              _infoRow("Max. missed payments allowed", "3", textTertiary),
              const SizedBox(height: 8),
              _infoRow("Payout order determined by", "join date", textTertiary),
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
      ],
    );
  }
}
