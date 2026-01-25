import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hoop/components/state/empty_state.dart';
import 'package:hoop/constants/themes.dart';
import 'package:hoop/dtos/podos/chats/messages.dart';
import 'package:hoop/dtos/responses/group/groups.dart';
import 'package:hoop/dtos/responses/group/group_join_request.dart';
import 'package:hoop/screens/groups/chat_detail_screen.dart';
import 'package:hoop/screens/groups/create_group.dart';
import 'package:hoop/states/OnboardingService.dart';
import 'package:hoop/states/auth_state.dart';
import 'package:hoop/states/group_state.dart';
import 'package:hoop/states/ws/chat_sockets.dart';
import 'package:hoop/utils/helpers/formatters/hoop_formatter.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:smart_overlay_menu/smart_overlay_menu.dart';

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
  String? userId;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final groupProvider = context.read<GroupCommunityProvider>();
      userId = authProvider.user?.id.toString();
      _loadGroupCounts();

      // if(groupProvider.activeGroups)
      // groupProvider.ge
    });
  }

  // Group counts from backend
  Map<String, int> _groupCounts = {
    'current': 0,
    'finished': 0,
    'pending': 0,
    'rejected': 0,
  };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
      }
    } catch (error) {
      print('Error loading group counts: $error');
    }
  }

  Future<void> _loadSegmentData(
    int segment, {
    bool forceRefresh = false,
  }) async {
    if (!mounted) return;

    final provider = Provider.of<GroupCommunityProvider>(
      context,
      listen: false,
    );

    try {
      switch (segment) {
        case 0: // Current groups (active/forming)
          await provider.getMyGroup(
            page: 0,
            limit: 20,
            status: 'active',
            forceRefresh: forceRefresh,
          );
          break;

        case 1: // Finished groups
          await provider.getMyGroup(
            page: 0,
            limit: 20,
            status: 'completed',
            forceRefresh: forceRefresh,
          );
          break;

        case 2: // Pending join requests
          await provider.getMyJoinRequests(
            'pending',
            forceRefresh: forceRefresh,
          );
          break;

        case 3: // Rejected join requests
          await provider.getMyJoinRequests(
            'rejected',
            forceRefresh: forceRefresh,
          );
          break;
      }
    } catch (error) {
      print('Error loading segment $segment: $error');
    }
  }

  List<dynamic> get displayedItems {
    final provider = Provider.of<GroupCommunityProvider>(context);

    switch (selectedSegment) {
      case 0: // Current groups
        final groups = provider.activeGroups;
        return _filterGroups(groups);
      case 1: // Finished groups
        final groups = provider.completedGroups;
        return _filterGroups(groups);
      case 2: // Pending requests
        final requests = provider.pendingRequests;
        return _filterRequests(requests);
      case 3: // Rejected requests
        final requests = provider.rejectedRequests;
        return _filterRequests(requests);
      default:
        return [];
    }
  }

  List<Group> _filterGroups(List<Group> groups) {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return groups;

    return groups.where((g) {
      final name = g.name.toLowerCase();
      final desc = g.description?.toLowerCase() ?? '';
      final tags = g.tags.join(' ').toLowerCase();
      return name.contains(q) || desc.contains(q) || tags.contains(q);
    }).toList();
  }

  List<GroupJoinRequest> _filterRequests(List<GroupJoinRequest> requests) {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return requests;

    return requests.where((r) {
      final groupName = r.groupName?.toLowerCase() ?? '';
      final message = r.message?.toLowerCase();
      return groupName.contains(q) || (message ?? '').contains(q);
    }).toList();
  }

  bool get _isLoading {
    final provider = Provider.of<GroupCommunityProvider>(context);
    switch (selectedSegment) {
      case 0:
        return provider.isSegmentLoading('active');
      case 1:
        return provider.isSegmentLoading('completed');
      case 2:
        return provider.isRequestsLoading('pending');
      case 3:
        return provider.isRequestsLoading('rejected');
      default:
        return false;
    }
  }

  bool get _hasError {
    return false;
  }

  bool get _isLoaded {
    final provider = Provider.of<GroupCommunityProvider>(context);
    switch (selectedSegment) {
      case 0:
        return provider.isSegmentLoaded('active');
      case 1:
        return provider.isSegmentLoaded('completed');
      case 2:
        return provider.isRequestsLoaded('pending');
      case 3:
        return provider.isRequestsLoaded('rejected');
      default:
        return false;
    }
  }

  void _handleSegmentChange(int newSegment) {
    setState(() {
      selectedSegment = newSegment;
    });

    if (!_isLoaded) {
      _loadSegmentData(newSegment);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : Colors.black;
    final textSecondary = isDark ? Colors.grey[400] : Colors.grey[600];
    final provider = Provider.of<GroupCommunityProvider>(context);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F111A) : Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // HEADER - Only rebuilds when websocket connection changes
            Consumer<ChatWebSocketHandler>(
              builder: (context, handler, child) {
                return _buildHeader(
                  isDark,
                  textPrimary,
                  textSecondary,
                  handler,
                );
              },
            ),

            const SizedBox(height: 16),

            // SEGMENTED CONTROL - Fixed counts, no websocket dependency
            _buildSegmentedControl(isDark),

            const SizedBox(height: 16),

            // CONTENT AREA - Optimized with multiple Consumers
            Expanded(
              child: _buildContentArea(
                isDark,
                textPrimary,
                textSecondary,
                provider,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Consumer<GroupCommunityProvider>(
        builder: (context, provider, child) {
          return StreamBuilder<bool>(
            stream: OnboardingService.onOnboardingStatusChanged,
            initialData: true,
            builder: (context, snapshot) {
              final needsOnboarding = snapshot.data ?? true;
              return !needsOnboarding
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
                        },
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        child: const Icon(
                          Iconsax.add,
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

  Widget _buildHeader(
    bool isDark,
    Color? textPrimary,
    Color? textSecondary,
    ChatWebSocketHandler handler,
  ) {
    return Container(
      color: isDark ? const Color(0xFF0F111A) : Colors.white,
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 12),
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
                    handler,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedControl(bool isDark) {
    return SingleChildScrollView(
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
    );
  }

  Widget _buildContentArea(
    bool isDark,
    Color textPrimary,
    Color? textSecondary,
    GroupCommunityProvider provider,
  ) {
    if (_isLoading && !_isLoaded) {
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

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: HoopTheme.primaryRed),
            const SizedBox(height: 16),
            Text(_getErrorMessage(), style: TextStyle(color: textPrimary)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () =>
                  _loadSegmentData(selectedSegment, forceRefresh: true),
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
        onPress: () => _loadSegmentData(selectedSegment, forceRefresh: true),
        secondaryActionText: "Refresh",
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadSegmentData(selectedSegment, forceRefresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: items.length,
        itemBuilder: (context, index) {
          if (selectedSegment <= 1) {
            // Render group card with SmartOverlayMenu
            final group = items[index] as Group;
            return _GroupCardWithPreview(
              group: group,
              isDark: isDark,
              textPrimary: textPrimary,
              userId: userId,
              textSecondary: textSecondary,
              selectedSegment: selectedSegment,
            );
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

  // ========== JOIN REQUEST CARD (Pending/Rejected) ==========
  Widget _buildRequestCard(
    GroupJoinRequest request,
    bool isDark,
    Color textPrimary,
    Color? textSecondary,
  ) {
    final groupName = request.groupName ?? 'Unknown Group';
    final initials = HoopFormatters.getInitials(groupName);
    final avatarColor = _getAvatarColor(request.groupId.toString());
    final statusColor = request.statusColor;
    final statusText = request.displayStatus;

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
                  if ((request.message ?? '').isNotEmpty)
                    Text(
                      request.message ?? '',
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
                      if (request.contributionAmount != null)
                        Text(
                          '₦${request.contributionAmount}',
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

  Widget _buildTitleHeader(
    bool isDark,
    Color? textPrimary,
    Color? textSecondary,
    List displayedGroups,
    ChatWebSocketHandler handler,
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

            // Connection status - only rebuilds when isConnected changes
            Consumer<ChatWebSocketHandler>(
              builder: (context, handler, child) {
                if (handler.isConnected.value) return const SizedBox.shrink();

                return Row(
                  children: [
                    const CupertinoActivityIndicator(),
                    const SizedBox(width: 4),
                    Text(
                      "Connecting...",
                      style: TextStyle(
                        color: const Color(0xFF080953),
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                );
              },
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
                    icon: Icon(
                      Iconsax.search_favorite,
                      color: textPrimary,
                      size: 22,
                    ),
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
                    onPressed: () {
                      handler.markAllMessagesAsRead();
                    },
                    icon: Icon(
                      Iconsax.message_tick,
                      color: textPrimary,
                      size: 22,
                    ),
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
            Icon(Iconsax.people, size: 16, color: textSecondary),
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

            // Unread messages - only rebuilds when unreadMessages changes
            Consumer<ChatWebSocketHandler>(
              builder: (context, handler, child) {
                final totalUnread = handler.totalUnreadMessages;
                if (totalUnread <= 0) return const SizedBox.shrink();

                return Text(
                  '${totalUnread > 99 ? '99+' : totalUnread} new messages',
                  style: TextStyle(
                    color: const Color(0xFFFF6F21),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                );
              },
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

  // Helper methods for avatar color
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
}

// ========== SEPARATE WIDGET FOR GROUP CARD WITH PREVIEW ==========
class _GroupCardWithPreview extends StatefulWidget {
  final Group group;
  final bool isDark;
  final String? userId;
  final Color textPrimary;
  final Color? textSecondary;
  final int selectedSegment;

  const _GroupCardWithPreview({
    required this.group,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.userId,
    required this.selectedSegment,
  });

  @override
  State<_GroupCardWithPreview> createState() => __GroupCardWithPreviewState();
}

class __GroupCardWithPreviewState extends State<_GroupCardWithPreview> {
  late final SmartOverlayMenuController _previewController;

  @override
  void initState() {
    super.initState();
    _previewController = SmartOverlayMenuController();
  }

  @override
  void dispose() {
    super.dispose();
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
      "initials": HoopFormatters.getInitials(group.name),
      "name": group.name,
      "id": group.id,
      "description": group.description ?? '',
      "dueDate": _getDueDate(group),
      "timeLeft": group.status,
      "color": _getAvatarColor(group.id.toString()),
      "group": group,
    };
  }

  String _formatPreviewTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  Widget _buildPreviewContent() {
    // Use Consumer to only rebuild when messages or typingUsers change
    return Consumer<ChatWebSocketHandler>(
      builder: (context, handler, child) {
        // Find messages for this group
        MessageGroup? groupMessages;
        final typingUsers = handler.getTypingUsers(widget.group.id);

        try {
          groupMessages = handler.messages.value.firstWhere(
            (msg) => msg.groupId.toString() == widget.group.id.toString(),
          );
        } catch (e) {
          // Handle case where no messages are found
        }

        final messages = (groupMessages?.messages ?? [])
            .where((m) => m.content.isNotEmpty)
            .toList()
            .reversed
            .take(5)
            .toList();

        final avatarColor = _getAvatarColor(widget.group.id.toString());
        final initials = HoopFormatters.getInitials(widget.group.name);

        return Container(
          width: 350,
          decoration: BoxDecoration(
            color: widget.isDark ? const Color(0xFF1A1D27) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: widget.isDark
                      ? const Color(0xFF2D3139)
                      : Colors.grey[50],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        _previewController.close();
                        Navigator.pushNamed(
                          context,
                          '/chat/detail',
                          arguments: _groupToMap(widget.group),
                        );
                      },
                      child: Container(
                        width: 40,
                        height: 40,
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
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          _previewController.close();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatDetailScreen(
                                group: _groupToMap(widget.group),
                              ),
                            ),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.group.name,
                              style: TextStyle(
                                color: widget.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              messages.isEmpty
                                  ? 'No messages yet'
                                  : '${messages.length} message${messages.length > 1 ? 's' : ''}',
                              style: TextStyle(
                                color: widget.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _previewController.close(),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: widget.isDark
                              ? Colors.white10
                              : Colors.grey[100],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          color: widget.textSecondary,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Divider
              Container(
                height: 1,
                color: widget.isDark ? Colors.white10 : Colors.grey[200],
              ),

              // Messages preview
              Container(
                constraints: const BoxConstraints(maxHeight: 350),
                child: messages.isEmpty
                    ? Container(
                        height: 120,
                        child: Center(
                          child: Text(
                            'No messages yet',
                            style: TextStyle(
                              color: widget.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        reverse: true,
                        shrinkWrap: true,
                        physics: const ClampingScrollPhysics(),
                        itemCount: min(messages.length, 7),
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final isOwn = message.isFromUser(widget.userId ?? '');

                          return Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isOwn
                                  ? const Color(0xFF6366F1).withOpacity(0.2)
                                  : (widget.isDark
                                        ? Colors.white10
                                        : Colors.grey[100]),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  message.content,
                                  style: TextStyle(
                                    color: widget.textPrimary,
                                    fontSize: 11,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatPreviewTime(
                                    message.createdAt ?? DateTime.now(),
                                  ),
                                  style: TextStyle(
                                    color: widget.textSecondary,
                                    fontSize: 9,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final avatarColor = _getAvatarColor(widget.group.id.toString());
    final statusColor = _getGroupStatusColor(widget.group.status);
    final initials = HoopFormatters.getInitials(widget.group.name);
    final dueDate = _getDueDate(widget.group);

    return SmartOverlayMenu(
      controller: _previewController,
      topWidgetAlignment: Alignment.center,
      openWithTap: false,
      topWidget: _buildPreviewContent(),
      repositionAnimationDuration: const Duration(microseconds: 1),
      bottomWidgetAlignment: Alignment.centerLeft,
      repositionAnimationCurve: Curves.easeInOut,
      bottomWidget: Consumer<ChatWebSocketHandler>(
        builder: (context, handler, child) {
          return _buildMessageMenu(handler, widget.group);
        },
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: widget.isDark ? const Color(0xFF1A1D27) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: widget.isDark
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
                      ChatDetailScreen(group: _groupToMap(widget.group)),
                ),
              );
            },
            onLongPress: () {
              _previewController.open();
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

                  // Group info with message and unread count
                  Expanded(
                    child: Consumer<ChatWebSocketHandler>(
                      builder: (context, handler, child) {
                        // Find messages for this group
                        MessageGroup? groupMessages;
                        try {
                          groupMessages = handler.messages.value.firstWhere(
                            (msg) =>
                                msg.groupId.toString() ==
                                widget.group.id.toString(),
                          );
                        } catch (e) {
                          // No messages for this group
                        }

                        final lastMessage = groupMessages?.messages.lastOrNull;
                        final unreadCount =
                            handler
                                .unreadMessages
                                .value[widget.group.id]
                                ?.length ??
                            0;
                        print(
                          "handler.unreadMessages.value?? ${handler.unreadMessages.value}",
                        );
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.group.name,
                                    style: TextStyle(
                                      color: widget.textPrimary,
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
                                    unreadCount > 0 ? '$unreadCount' : dueDate,
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
                                    lastMessage?.content ??
                                        widget.group.description ??
                                        'No description',
                                    style: TextStyle(
                                      color: widget.textSecondary,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  lastMessage?.createdAt != null
                                      ? HoopFormatters.formatTime(
                                          lastMessage!.createdAt!,
                                        )
                                      : '₦${widget.group.contributionAmount}',
                                  style: TextStyle(
                                    color: widget.textSecondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageMenu(ChatWebSocketHandler handler, Group group) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1A1D27)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMenuTile(
            icon: CupertinoIcons.reply,
            label: 'Open Chat',
            onTap: () {
              _previewController.close();
              Navigator.pushNamed(
                context,
                '/chat/detail',
                arguments: _groupToMap(group),
              );
            },
          ),
          _buildMenuTile(
            icon: Iconsax.message_tick,
            label: 'Read All Messages',
            onTap: () {
              _previewController.close();
              handler.markAllGroupMessagesAsRead(group.id);
            },
          ),
          _buildMenuTile(
            icon: Iconsax.call,
            label: 'Audio Call Group',
            onTap: () async {
              _previewController.close();
              final callData = await handler.startWebRTCCall(
                context,
                type: 'audio',
                groupId: group.id.toInt(),
                groupName: group.name,
              );
            },
          ),
          _buildMenuTile(
            icon: Iconsax.video,
            label: 'Video Call Group',
            onTap: () async {
              _previewController.close();
              final callData = await handler.startWebRTCCall(
                context,
                type: 'video',
                groupId: group.id.toInt(),
                groupName: group.name,
              );
            },
          ),
          const SizedBox(height: 4),
          _buildMenuTile(
            icon: Iconsax.profile_delete,
            label: 'Leave Group',
            isDestructive: true,
            onTap: () async {
              _previewController.close();
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          width: 220,
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isDestructive
                    ? Colors.red
                    : (isDark ? Colors.grey[300] : Colors.grey[700]),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: isDestructive
                      ? Colors.red
                      : (isDark ? Colors.grey[300] : Colors.grey[700]),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
