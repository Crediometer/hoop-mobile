import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:hoop/components/state/empty_state.dart';
import 'package:hoop/screens/groups/chat_detail_screen.dart';
import 'package:hoop/screens/groups/create_group.dart';
import 'package:hoop/states/OnboardingService.dart';
import 'package:hoop/states/group_state.dart';
import 'package:hoop/dtos/responses/group/Groups.dart';
import 'package:hoop/dtos/responses/group/group_join_request.dart';
import 'package:provider/provider.dart';
import 'package:hoop/constants/themes.dart';
import 'package:hoop/utils/helpers/formatters/hoop_formatter.dart';
import 'package:hoop/states/group_state.dart';

class GroupsTab extends StatefulWidget {
  const GroupsTab({super.key});

  @override
  State<GroupsTab> createState() => _GroupsTabState();
}

class _GroupsTabState extends State<GroupsTab> {
  int selectedSegment =
      0; // 0 = Current, 1 = Finished, 2 = Pending, 3 = Rejected
  bool _showSearch = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Loading states
  Map<int, bool> _segmentLoading = {0: false, 1: false, 2: false, 3: false};
  Map<int, bool> _segmentLoaded = {0: false, 1: false, 2: false, 3: false};
  Map<int, bool> _segmentError = {0: false, 1: false, 2: false, 3: false};

  // Group counts from backend
  Map<String, int> _groupCounts = {
    'current': 0,
    'finished': 0,
    'pending': 0,
    'rejected': 0,
  };

  // Data for each segment
  Map<int, List<Group>> _segmentGroups = {
    0: [],
    1: [],
  }; // Only for groups (0, 1)
  Map<int, List<GroupJoinRequest>> _segmentRequests = {
    2: [],
    3: [],
  }; // For requests (2, 3)

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGroupCounts();
    });
  }

  Future<void> _loadGroupCounts() async {
    try {
      final provider = Provider.of<GroupCommunityProvider>(
        context,
        listen: false,
      );
      final response = await provider.getMyGroupCounts();

      if (response.success && response.data != null) {
        setState(() {
          _groupCounts = {
            'current': response.data!['current'] ?? 0,
            'finished': response.data!['finished'] ?? 0,
            'pending': response.data!['pending'] ?? 0,
            'rejected': response.data!['rejected'] ?? 0,
          };
        });

        // Pre-load current groups if counts > 0
        if (selectedSegment == 0 &&
            !_segmentLoaded[0]! &&
            _groupCounts['current']! > 0) {
          await _loadSegmentData(0);
        }
      }
    } catch (error) {
      print('Error loading group counts: $error');
    }
  }

  Future<void> _loadSegmentData(int segment) async {
    if (_segmentLoaded[segment]! ||
        _segmentLoading[segment]! ||
        _groupCounts[_getSegmentKey(segment)]! <= 0) {
      return;
    }

    if (!mounted) return;

    setState(() {
      _segmentLoading[segment] = true;
      _segmentError[segment] = false;
    });

    try {
      final provider = Provider.of<GroupCommunityProvider>(
        context,
        listen: false,
      );

      switch (segment) {
        case 0: // Current groups (active/forming)
          final response = await provider.getMyGroup(
            page: 0,
            limit: 20,
            status: 'active',
          );
          if (response.success && response.data != null) {
            setState(() {
              _segmentGroups[0] = response.data!.content;
            });
          }
          break;

        case 1: // Finished groups
          final response = await provider.getMyGroup(
            page: 0,
            limit: 20,
            status: 'completed',
          );
          if (response.success && response.data != null) {
            setState(() {
              _segmentGroups[1] = response.data!.content;
            });
          }
          break;

        case 2: // Pending join requests
          final response = await provider.getMyJoinRequests('pending');
          if (response.success && response.data != null) {
            setState(() {
              _segmentRequests[2] = response.data!;
            });
          }
          break;

        case 3: // Rejected join requests
          final response = await provider.getMyJoinRequests('rejected');
          if (response.success && response.data != null) {
            setState(() {
              _segmentRequests[3] = response.data!;
            });
          }
          break;
      }

      if (mounted) {
        setState(() {
          _segmentLoaded[segment] = true;
          _segmentLoading[segment] = false;
        });
      }
    } catch (error) {
      print('Error loading segment $segment: $error');
      if (mounted) {
        setState(() {
          _segmentError[segment] = true;
          _segmentLoading[segment] = false;
        });
      }
    }
  }

  String _getSegmentKey(int segment) {
    switch (segment) {
      case 0:
        return 'current';
      case 1:
        return 'finished';
      case 2:
        return 'pending';
      case 3:
        return 'rejected';
      default:
        return 'current';
    }
  }

  List<dynamic> get displayedItems {
    if (selectedSegment <= 1) {
      // For groups (current/finished)
      final groups = _segmentGroups[selectedSegment] ?? [];
      final q = _searchQuery.trim().toLowerCase();
      if (q.isNotEmpty) {
        return groups.where((g) {
          final name = g.name.toLowerCase();
          final desc = g.description?.toLowerCase() ?? '';
          final tags = g.tags.join(' ').toLowerCase();
          return name.contains(q) || desc.contains(q) || tags.contains(q);
        }).toList();
      }
      return groups;
    } else {
      // For join requests (pending/rejected)
      final requests = _segmentRequests[selectedSegment] ?? [];
      final q = _searchQuery.trim().toLowerCase();
      if (q.isNotEmpty) {
        return requests.where((r) {
          final groupName = r.group?.name?.toLowerCase() ?? '';
          final message = r.message.toLowerCase();
          return groupName.contains(q) || message.contains(q);
        }).toList();
      }
      return requests;
    }
  }

  void _handleSegmentChange(int newSegment) {
    setState(() {
      selectedSegment = newSegment;
    });

    // Load data for this segment if not already loaded
    if (!_segmentLoaded[newSegment]! && !_segmentLoading[newSegment]!) {
      _loadSegmentData(newSegment);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : Colors.black;
    final textSecondary = isDark ? Colors.grey[400] : Colors.grey[600];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F111A) : Colors.grey[50],
      body: Column(
        children: [
          // HEADER
          Container(
            color: isDark ? const Color(0xFF0F111A) : Colors.white,
            padding: const EdgeInsets.only(
              left: 20,
              right: 20,
              top: 24,
              bottom: 12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _showSearch
                      ? _buildSearchHeader(isDark, textPrimary, textSecondary)
                      : _buildTitleHeader(
                          isDark,
                          textPrimary,
                          textSecondary,
                          displayedItems,
                          0,
                        ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // SEGMENTED CONTROL with counts
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1D27) : Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSegmentButtonFixed(
                    "Current (${_groupCounts['current']})",
                    0,
                    isDark,
                  ),
                  _buildSegmentButtonFixed(
                    "Finished (${_groupCounts['finished']})",
                    1,
                    isDark,
                  ),
                  _buildSegmentButtonFixed(
                    "Pending (${_groupCounts['pending']})",
                    2,
                    isDark,
                  ),
                  _buildSegmentButtonFixed(
                    "Rejected (${_groupCounts['rejected']})",
                    3,
                    isDark,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // CONTENT AREA
          Expanded(
            child: _buildSegmentContent(isDark, textPrimary, textSecondary),
          ),
        ],
      ),

      // FLOATING ACTION BUTTON
      floatingActionButton: Consumer<GroupCommunityProvider>(
        builder: (context, provider, child) {
          return StreamBuilder<bool>(
            stream: OnboardingService.onOnboardingStatusChanged,
            initialData: true,
            builder: (context, snapshot) {
              log("snapshot.data?? ${snapshot.data}");
              final needsOnboarding = snapshot.data ?? true;
              return needsOnboarding
                  ? const SizedBox.shrink()
                  : Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF07013B), Color(0xFF1A0B5E)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF07013B).withOpacity(0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: FloatingActionButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (builder) => GroupCreationFlowScreen(),
                            ),
                          );
                          // Navigate to create group screen
                        },
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        child: const Icon(
                          Icons.add,
                          size: 28,
                          color: Colors.white,
                        ),
                      ),
                    );
            },
          );
        },
      ),
    );
  }

  Widget _buildSegmentContent(
    bool isDark,
    Color textPrimary,
    Color? textSecondary,
  ) {
    if (_segmentLoading[selectedSegment]!) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: HoopTheme.primaryRed),
            const SizedBox(height: 16),
            Text(_getLoadingMessage(), style: TextStyle(color: textSecondary)),
          ],
        ),
      );
    }

    if (_segmentError[selectedSegment]!) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: HoopTheme.primaryRed),
            const SizedBox(height: 16),
            Text(_getErrorMessage(), style: TextStyle(color: textPrimary)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _loadSegmentData(selectedSegment),
              style: ElevatedButton.styleFrom(
                backgroundColor: HoopTheme.primaryRed,
                foregroundColor: Colors.white,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    final items = displayedItems;

    if (items.isEmpty) {
      return HoopEmptyState(
        title: _getEmptyStateTitle(),
        subtitle: _getEmptyStateSubtitle(),
        iconData: _getEmptyStateIcon(),
        onPress: () => _loadSegmentData(selectedSegment),
        secondaryActionText: "Refresh",
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadSegmentData(selectedSegment),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: items.length,
        itemBuilder: (context, index) {
          if (selectedSegment <= 1) {
            // Render group card
            final group = items[index] as Group;
            return _buildGroupCard(group, isDark, textPrimary, textSecondary);
          } else {
            // Render join request card
            final request = items[index] as GroupJoinRequest;
            return _buildRequestCard(
              request,
              isDark,
              textPrimary,
              textSecondary,
            );
          }
        },
      ),
    );
  }

  // ========== GROUP CARD (Current/Finished) ==========

  Widget _buildGroupCard(
    Group group,
    bool isDark,
    Color textPrimary,
    Color? textSecondary,
  ) {
    final avatarColor = _getAvatarColor(group.id);
    final statusColor = _getGroupStatusColor(group.status);
    final initials = _getInitials(group.name);
    final dueDate = _getDueDate(group);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ChatDetailScreen(group: _groupToMap(group)),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Avatar with initials
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: avatarColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Group info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              group.name,
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              dueDate,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              group.description ?? 'No description',
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '₦${group.contributionAmount}',
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ========== JOIN REQUEST CARD (Pending/Rejected) ==========

  Widget _buildRequestCard(
    GroupJoinRequest request,
    bool isDark,
    Color textPrimary,
    Color? textSecondary,
  ) {
    final groupName = request.group?.name ?? 'Unknown Group';
    final initials = _getInitials(groupName);
    final avatarColor = _getAvatarColor(request.groupId);
    final statusColor = request.statusColor;
    final statusText = request.statusText;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Avatar with initials
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: avatarColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Request info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          groupName,
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (request.message.isNotEmpty)
                    Text(
                      request.message,
                      style: TextStyle(color: textSecondary, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 12,
                        color: textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        HoopFormatters.formatTimeAgo(request.createdAt),
                        style: TextStyle(color: textSecondary, fontSize: 11),
                      ),
                      const Spacer(),
                      if (request.group?.contributionAmount != null)
                        Text(
                          '₦${request.group!.contributionAmount}',
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '??';

    final parts = name.trim().split(RegExp(r'\s+'));

    final validParts = parts.where((part) => part.isNotEmpty).toList();

    if (validParts.length >= 2) {
      if (validParts[0].isNotEmpty && validParts[1].isNotEmpty) {
        return '${validParts[0][0]}${validParts[1][0]}'.toUpperCase();
      }
    }

    if (validParts.isNotEmpty) {
      final firstPart = validParts[0];
      return firstPart.substring(0, firstPart.length > 2 ? 2 : 1).toUpperCase();
    }

    return '??';
  }

  Color _getAvatarColor(String id) {
    final colors = [
      const Color(0xFF9C27B0), // Purple
      const Color(0xFFE91E63), // Pink
      const Color(0xFFF44336), // Red
      const Color(0xFF00BCD4), // Cyan
      const Color(0xFF4CAF50), // Green
      const Color(0xFFFF9800), // Orange
      const Color(0xFF2196F3), // Blue
      const Color(0xFF673AB7), // Deep Purple
      const Color(0xFFFF5722), // Deep Orange
      const Color(0xFF795548), // Brown
    ];
    final index = id.hashCode.abs() % colors.length;
    return colors[index];
  }

  Color _getGroupStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'forming':
        return HoopTheme.primaryRed;
      case 'completed':
      case 'ended':
        return HoopTheme.successGreen;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return HoopTheme.primaryRed;
    }
  }

  String _getDueDate(Group group) {
    try {
      final startDate = DateTime.parse(group.startDate);
      final dueDate = startDate.add(Duration(days: group.cycleDurationDays));
      final now = DateTime.now();
      final difference = dueDate.difference(now);

      if (difference.inDays > 0) {
        return 'Due in ${difference.inDays} day${difference.inDays > 1 ? 's' : ''}';
      } else if (difference.inHours > 0) {
        return 'Due in ${difference.inHours}h';
      } else {
        return 'Due Today';
      }
    } catch (e) {
      return 'Due Soon';
    }
  }

  Map<String, dynamic> _groupToMap(Group group) {
    return {
      "initials": _getInitials(group.name),
      "name": group.name,
      "id": group.id,
      "description": group.description ?? '',
      "dueDate": _getDueDate(group),
      "timeLeft": group.status,
      "color": _getAvatarColor(group.id),
      "group": group,
    };
  }

  // ========== UI STRING HELPERS ==========

  String _getLoadingMessage() {
    switch (selectedSegment) {
      case 0:
        return 'Loading current groups...';
      case 1:
        return 'Loading finished groups...';
      case 2:
        return 'Loading pending requests...';
      case 3:
        return 'Loading rejected requests...';
      default:
        return 'Loading...';
    }
  }

  String _getErrorMessage() {
    switch (selectedSegment) {
      case 0:
        return 'Failed to load current groups';
      case 1:
        return 'Failed to load finished groups';
      case 2:
        return 'Failed to load pending requests';
      case 3:
        return 'Failed to load rejected requests';
      default:
        return 'Failed to load data';
    }
  }

  String _getEmptyStateTitle() {
    switch (selectedSegment) {
      case 0:
        return "No current groups";
      case 1:
        return "No finished groups";
      case 2:
        return "No pending requests";
      case 3:
        return "No rejected requests";
      default:
        return "No data";
    }
  }

  String _getEmptyStateSubtitle() {
    switch (selectedSegment) {
      case 0:
        return "You currently don't have any active groups";
      case 1:
        return "No completed groups yet";
      case 2:
        return "You haven't applied to any groups";
      case 3:
        return "No rejected applications";
      default:
        return "No data found";
    }
  }

  IconData _getEmptyStateIcon() {
    switch (selectedSegment) {
      case 0:
        return Icons.folder_open_outlined;
      case 1:
        return Icons.check_circle_outline;
      case 2:
        return Icons.hourglass_empty;
      case 3:
        return Icons.cancel_outlined;
      default:
        return Icons.folder_open_outlined;
    }
  }

  // ========== HEADER WIDGETS ==========

  Widget _buildSegmentButtonFixed(String label, int segment, bool isDark) {
    final isSelected = selectedSegment == segment;
    return GestureDetector(
      onTap: () => _handleSegmentChange(segment),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected
                ? (isDark ? Colors.white : HoopTheme.primaryRed)
                : (isDark ? Colors.grey[500] : Colors.grey[500]),
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  // Widget _buildTitleHeader(
  //   bool isDark,
  //   Color? textPrimary,
  //   Color? textSecondary,
  //   int selectedSegment,
  // ) {
  //   final segmentLabels = [
  //     'current groups',
  //     'finished groups',
  //     'pending requests',
  //     'rejected requests',
  //   ];
  //   final items = displayedItems;

  //   return Column(
  //     key: const ValueKey('title'),
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Row(
  //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //         children: [
  //           Text(
  //             selectedSegment <= 1 ? "Groups" : "Join Requests",
  //             style: TextStyle(
  //               color: const Color(0xFF080953),
  //               fontSize: 28,
  //               fontWeight: FontWeight.normal,
  //               fontFamily: 'Inter',
  //               letterSpacing: -0.5,
  //             ),
  //           ),
  //           Row(
  //             children: [
  //               Container(
  //                 decoration: BoxDecoration(
  //                   color: isDark ? Colors.white10 : Colors.grey[100],
  //                   shape: BoxShape.circle,
  //                 ),
  //                 child: IconButton(
  //                   onPressed: () => setState(() => _showSearch = true),
  //                   icon: Icon(Icons.search, color: textPrimary, size: 22),
  //                   padding: EdgeInsets.zero,
  //                   constraints: const BoxConstraints(
  //                     minWidth: 44,
  //                     minHeight: 44,
  //                   ),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ],
  //       ),
  //       const SizedBox(height: 8),
  //       Row(
  //         children: [
  //           Icon(
  //             selectedSegment <= 1 ? Icons.people : Icons.pending_actions,
  //             size: 16,
  //             color: textSecondary,
  //           ),
  //           const SizedBox(width: 6),
  //           Text(
  //             "${items.length} ${segmentLabels[selectedSegment]}",
  //             style: TextStyle(color: textSecondary, fontSize: 13),
  //           ),
  //         ],
  //       ),
  //     ],
  //   );
  // }

  Widget _buildTitleHeader(
    bool isDark,
    Color? textPrimary,
    Color? textSecondary,
    List displayedGroups,
    int selectedSegment,
  ) {
    return Column(
      key: const ValueKey('title'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Group",
              style: TextStyle(
                color: const Color(0xFF080953),
                fontSize: 28,
                fontWeight: FontWeight.normal,
                fontFamily: 'Inter',
                letterSpacing: -0.5,
              ),
            ),
            Row(
              children: [
                // Search icon
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: () => setState(() => _showSearch = true),
                    icon: Icon(Icons.search, color: textPrimary, size: 22),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Checkmark icon
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.check, color: textPrimary, size: 22),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Subtitle with updates indicator
        Row(
          children: [
            Icon(Icons.people, size: 16, color: textSecondary),
            const SizedBox(width: 6),
            Text(
              "${displayedGroups.length} ${selectedSegment == 0
                  ? 'active'
                  : selectedSegment == 1
                  ? 'finished'
                  : selectedSegment == 2
                  ? 'pending'
                  : 'rejected'} groups",
              style: TextStyle(color: textSecondary, fontSize: 13),
            ),
            const SizedBox(width: 12),
            const Text('•', style: TextStyle(color: Colors.redAccent)),
            const SizedBox(width: 8),
            Text(
              '59 new updates',
              style: TextStyle(
                color: const Color(0xFFFF6F21),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchHeader(
    bool isDark,
    Color? textPrimary,
    Color? textSecondary,
  ) {
    return Column(
      key: const ValueKey('search'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF141617) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    const Icon(Icons.search, size: 20, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) => setState(() => _searchQuery = v),
                        style: TextStyle(color: textPrimary),
                        decoration: InputDecoration(
                          hintText: _getSearchHint(),
                          hintStyle: TextStyle(
                            color: textSecondary,
                            fontSize: 13,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                          _showSearch = false;
                        });
                      },
                      child: const Icon(
                        Icons.close,
                        size: 20,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: () {},
                icon: Icon(Icons.tune, color: textPrimary, size: 22),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  String _getSearchHint() {
    switch (selectedSegment) {
      case 0:
      case 1:
        return 'Search groups by name, description...';
      case 2:
      case 3:
        return 'Search requests by group name, message...';
      default:
        return 'Search...';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
