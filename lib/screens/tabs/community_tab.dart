import 'package:flutter/material.dart';
import 'package:hoop/components/indicators/loader.dart';
import 'package:hoop/components/state/empty_state.dart';
import 'package:hoop/constants/themes.dart';
import 'package:hoop/dtos/responses/group/index.dart';
import 'package:hoop/screens/notifications/notification_screen.dart';
import 'package:hoop/screens/settings/community_preference.dart';
import 'package:hoop/screens/tabs/market_storm.dart';
import 'package:hoop/states/group_state.dart';
import 'package:hoop/states/ws/notification_socket.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:swipe_cards/swipe_cards.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  late MatchEngine _matchEngine;
  final List<SwipeItem> _swipeItems = [];
  List<GroupWithScore> _passedGroups = [];
  int selectedTab = 0;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();

    // Initialize with empty match engine
    _matchEngine = MatchEngine(swipeItems: _swipeItems);

    // Fetch data from backend after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchCommunityGroups();
    });
  }

  Future<void> _fetchCommunityGroups() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final provider = Provider.of<GroupCommunityProvider>(
        context,
        listen: false,
      );

      // Fetch groups from backend
      await provider.getCommunityGroups(
        lat: 6.5244, // Lagos coordinates
        lng: 3.3792,
        page: 0,
        limit: 20,
      );

      // Build swipe items from fetched data
      _buildSwipeItems(provider.communities);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Failed to load groups: ${error.toString()}';
        });
      }
    }
  }

  void _buildSwipeItems(List<GroupWithScore> groups) {
    _swipeItems.clear();

    for (var group in groups) {
      _swipeItems.add(
        SwipeItem(
          content: group,
          likeAction: () => _handleJoinGroup(group),
          nopeAction: () => _handlePassGroup(group),
        ),
      );
    }

    if (mounted) {
      setState(() {
        _matchEngine = MatchEngine(swipeItems: _swipeItems);
      });
    }
  }

  Future<void> _handleJoinGroup(GroupWithScore group) async {
    Navigator.pushNamed(
      context,
      "/group/detail/public",
      arguments: group.group.toJson(),
    );
  }

  void _handlePassGroup(GroupWithScore group) {
    _passedGroups.add(group);
    _showSnackBar("Passed ${group.group.name}");
  }

  void _rewindLastSwipe() {
    if (_passedGroups.isNotEmpty) {
      final lastGroup = _passedGroups.removeLast();
      // Add back to the beginning of swipe items
      _swipeItems.insert(
        0,
        SwipeItem(
          content: lastGroup,
          likeAction: () => _handleJoinGroup(lastGroup),
          nopeAction: () => _handlePassGroup(lastGroup),
        ),
      );

      // Recreate match engine with updated items
      setState(() {
        _matchEngine = MatchEngine(swipeItems: _swipeItems);
      });

      _showSnackBar("Rewinded ${lastGroup.group.name}");
    } else {
      _showSnackBar("No groups to rewind");
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // SINGLE HEADER (Always visible)
            Consumer<GroupCommunityProvider>(
              builder: (context, provider, child) {
                return _buildHeader();
              },
            ),

            // TAB BAR (Always visible)
            _buildTabBar(),

            // MAIN CONTENT (Changes based on selected tab)
            Expanded(
              child: Consumer<GroupCommunityProvider>(
                builder: (context, provider, child) {
                  final groups = provider.communities;

                  if (selectedTab == 0) return _buildCardsView(groups);
                  if (selectedTab == 1) return _buildListView(groups);
                  if (selectedTab == 2) return MarketStormTab();
                  return Container(); // Fallback
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.white54 : Colors.black54;
    final textTertiary = isDark ? Colors.white30 : Colors.black38;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Discover Groups",
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              Row(
                children: [
                  Consumer<NotificationWebSocketHandler>(
                    builder: (context, notification, child) {
                      return ValueListenableBuilder(
                        valueListenable: notification.unreadCount,
                        builder: (context, value, child) {
                          return Badge(
                            label: value != 0
                                ? Text(value > 999 ? '999+' : '$value')
                                : null,

                            child: _buildIconButton(
                              Iconsax.notification_status,
                              textPrimary,
                              isDark,
                              () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => NotificationsScreen(),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  _buildIconButton(
                    Icons.tune,
                    textPrimary,
                    isDark,
                    () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => CommunitySettingsScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Find your perfect thrift community",
            style: TextStyle(
              color: textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 4),
          Consumer<GroupCommunityProvider>(
            builder: (context, provider, child) {
              return Text(
                "🔍 Showing ${provider.communities.length} personalized groups",
                style: TextStyle(color: textTertiary, fontSize: 12),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2530) : Colors.grey[100],
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          _buildTab("Cards", Icons.grid_view_rounded, 0, isDark),
          _buildTab("List", Icons.list_rounded, 1, isDark),
          _buildTab("Market Storm", Icons.bar_chart, 2, isDark),
        ],
      ),
    );
  }

  Widget _buildTab(String label, IconData icon, int index, bool isDark) {
    final isSelected = selectedTab == index;
    final activeColor = isDark ? const Color(0xFF2D3139) : Colors.white;
    final activeTextColor = isDark ? Colors.white : HoopTheme.primaryRed;
    final inactiveTextColor = isDark ? Colors.grey[500] : Colors.grey[500];

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.transparent,
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? activeTextColor : inactiveTextColor,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? activeTextColor : inactiveTextColor,
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

  Widget _buildIconButton(
    IconData icon,
    Color color,
    bool isDark,
    VoidCallback? callBack,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.grey[100],
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: callBack,
        icon: Icon(icon, color: color, size: 24),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      ),
    );
  }

  Widget _buildCardsView(List<GroupWithScore> groups) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return (_hasError && groups.isEmpty)
        ? _buildErrorState(isDark)
        : (_isLoading && groups.isEmpty)
        ? Center(
            child: WaveLoader(size: 150, waveDuration: Duration(seconds: 3)),
          )
        : _swipeItems.isEmpty
        ? HoopEmptyState(
            title: 'No groups found nearby',
            subtitle:
                'Try adjusting your location settings or check back later',
            iconData: Icons.group_outlined,
            secondaryActionText: "Refresh Community",
            onPress: _fetchCommunityGroups,
          )
        : Stack(
            children: [
              // Swipe cards take full space
              Positioned.fill(child: _buildSwipeCards()),

              // Action buttons overlay at the bottom
              Positioned(
                left: 0,
                right: 0,
                bottom: 20,
                child: _buildActionButtons(),
              ),
            ],
          );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: HoopTheme.primaryRed),
            const SizedBox(height: 20),
            Text(
              'Could not load groups',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _fetchCommunityGroups,
              style: ElevatedButton.styleFrom(
                backgroundColor: HoopTheme.primaryRed,
                foregroundColor: Colors.white,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwipeCards() {
    return SwipeCards(
      matchEngine: _matchEngine,
      itemBuilder: (context, index) {
        final group = _swipeItems[index].content as GroupWithScore;
        return _GroupCard(group: group);
      },
      onStackFinished: () {
        _showSnackBar("No more groups to show");
      },
      upSwipeAllowed: false,
      fillSpace: true,
      likeTag: _buildSwipeIndicator("JOIN", Colors.green),
      nopeTag: _buildSwipeIndicator("PASS", Colors.red),

      // Add subtle physics effects
      // animationDuration: const Duration(milliseconds: 200),
      // swipeThreshold: 0.2,
    );
  }

  Widget _buildSwipeIndicator(String text, Color color) {
    return Positioned(
      top: 60,
      left: text == "JOIN" ? null : 20,
      right: text == "PASS" ? null : 20,
      child: Transform.rotate(
        angle: text == "JOIN" ? -0.2 : 0.2,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            border: Border.all(color: color, width: 3),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildRoundedActionButton(
            icon: Icons.close,
            backgroundColor: Colors.red.shade50,
            iconColor: Colors.red,
            size: 64,
            onPressed: () {
              _matchEngine.currentItem?.nope();
            },
            label: "Pass",
          ),
          const SizedBox(width: 40),

          _buildRoundedActionButton(
            icon: Icons.replay,
            backgroundColor: Colors.blue.shade50,
            iconColor: Colors.blue,
            size: 52,
            onPressed: _rewindLastSwipe,
            showLabel: false,
          ),
          const SizedBox(width: 40),
          _buildRoundedActionButton(
            icon: Icons.favorite,
            backgroundColor: Colors.green.shade50,
            iconColor: Colors.green,
            size: 64,
            onPressed: () {
              _matchEngine.currentItem?.like();
            },
            label: "Join",
          ),
        ],
      ),
    );
  }

  Widget _buildRoundedActionButton({
    required IconData icon,
    required Color backgroundColor,
    required Color iconColor,
    required double size,
    required VoidCallback onPressed,
    String? label,
    bool showLabel = true,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(size / 2),
              child: Icon(icon, color: iconColor, size: size * 0.45),
            ),
          ),
        ),
        if (label != null && showLabel)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              label,
              style: TextStyle(
                color: iconColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildListView(List<GroupWithScore> groups) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: _fetchCommunityGroups,
      child: (_hasError && groups.isEmpty)
          ? SingleChildScrollView(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: _buildErrorState(isDark),
              ),
            )
          : (_isLoading && groups.isEmpty)
          ? SingleChildScrollView(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: Center(
                  child: WaveLoader(
                    size: 150,
                    waveDuration: Duration(seconds: 3),
                  ),
                ),
              ),
            )
          : groups.isEmpty
          ? SingleChildScrollView(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: Center(
                  child: HoopEmptyState(
                    title: 'No groups found nearby',
                    subtitle:
                        'Try adjusting your location settings or check back later',
                    iconData: Icons.group_outlined,
                    secondaryActionText: "Refresh Community",
                    onPress: _fetchCommunityGroups,
                  ),
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];
                final textPrimary = isDark ? Colors.white : Colors.black87;
                final textSecondary = isDark ? Colors.white54 : Colors.black54;
                final textTertiary = isDark ? Colors.white30 : Colors.black38;

                // Use dynamic colors from theme
                final cardColor = HoopTheme.getCommunityCardColor(
                  index,
                  isDark,
                );
                final category = group.group.tags.isNotEmpty
                    ? group.group.tags.first
                    : 'General';
                final categoryColor = HoopTheme.getCategoryBackgroundColor(
                  category,
                  isDark,
                );
                final categoryTextColor = HoopTheme.getCategoryTextColor(
                  category,
                  isDark,
                );

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: isDark
                        ? null
                        : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: categoryColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    category.toUpperCase(),
                                    style: TextStyle(
                                      color: categoryTextColor,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${group.group.maxMembers} max members',
                                  style: TextStyle(
                                    color: textTertiary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () => _handleJoinGroup(group),
                              icon: Icon(
                                Icons.favorite_border,
                                color: isDark
                                    ? Colors.white70
                                    : HoopTheme.primaryRed,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 40,
                                minHeight: 40,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          group.group.name,
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (group.distanceKm != null)
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${group.distanceKm!.toStringAsFixed(1)} km away',
                                  style: TextStyle(
                                    color: textSecondary,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 10),
                        if (group.group.description != null &&
                            group.group.description!.isNotEmpty)
                          Text(
                            group.group.description!,
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 13,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildDetailChip(
                              Icons.attach_money,
                              'Contribution',
                              '₦${group.group.contributionAmount.toStringAsFixed(0)}',
                              HoopTheme.successGreen,
                              isDark,
                            ),
                            const SizedBox(width: 12),
                            _buildDetailChip(
                              Icons.schedule,
                              'Duration',
                              group.group.displayCycleDuration,
                              HoopTheme.primaryRed,
                              isDark,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => _handleJoinGroup(group),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: HoopTheme.primaryRed,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 44),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Join Group'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildDetailChip(
    IconData icon,
    String title,
    String value,
    Color valueColor,
    bool isDark,
  ) {
    final textTertiary = isDark ? Colors.white30 : Colors.black38;
    final chipColor = isDark
        ? const Color(0xFF141617)
        : HoopTheme.getCardColor(false);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isDark
            ? null
            : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)],
      ),
      child: Row(
        children: [
          Icon(icon, color: valueColor, size: 16),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: textTertiary, fontSize: 11)),
              Text(
                value,
                style: TextStyle(
                  color: valueColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final GroupWithScore group;

  const _GroupCard({required this.group});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final textSecondary = isDark ? Colors.white70 : const Color(0xFF555555);
    final textTertiary = isDark ? Colors.white54 : const Color(0xFF777777);

    // Get dynamic colors from theme
    final swipeColorIndex =
        group.group.id.hashCode.abs() % HoopTheme.swipeCardColors.length;
    final swipeCardColor = HoopTheme.getCommunityCardColor(
      swipeColorIndex,
      false,
    );

    return SingleChildScrollView(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: const EdgeInsets.all(24),
        height: 520,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2C) : swipeCardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.group.name,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      // Match score with progress bar
                      Row(
                        children: [
                          Text(
                            "Match Score: ",
                            style: TextStyle(color: textTertiary, fontSize: 13),
                          ),
                          Text(
                            "${(group.matchScore * 100).toStringAsFixed(0)}%",
                            style: TextStyle(
                              color: group.matchScore > 0.7
                                  ? Colors.green
                                  : group.matchScore > 0.4
                                  ? Colors.orange
                                  : Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: group.matchScore,
                                backgroundColor: textTertiary.withOpacity(0.2),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  group.matchScore > 0.7
                                      ? Colors.green
                                      : group.matchScore > 0.4
                                      ? Colors.orange
                                      : Colors.red,
                                ),
                                minHeight: 6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: HoopTheme.primaryRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: HoopTheme.primaryRed.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.people_outline,
                            color: HoopTheme.primaryRed,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "${group.group.maxMembers}",
                            style: TextStyle(
                              color: HoopTheme.primaryRed,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Location and distance row
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 18,
                  color: textSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (group.group.location != null &&
                          group.group.location!.isNotEmpty)
                        Text(
                          group.group.location!,
                          style: TextStyle(color: textSecondary, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (group.distanceKm != null)
                        Text(
                          '${group.distanceKm!.toStringAsFixed(1)} km away',
                          style: TextStyle(color: textTertiary, fontSize: 13),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Description
            if (group.group.description != null &&
                group.group.description!.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "About",
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    group.group.description!,
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 24),

            // Group details
            _buildDetailRow(
              Icons.attach_money,
              "Contribution amount",
              "₦${group.group.contributionAmount.toStringAsFixed(0)}",
              HoopTheme.successGreen,
              textColor,
              isDark,
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              Icons.account_balance_wallet,
              "Total Pot",
              "₦${(group.group.contributionAmount * group.group.maxMembers).toStringAsFixed(0)}",
              HoopTheme.primaryRed,
              textColor,
              isDark,
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              Icons.access_time,
              "Cycle duration",
              group.group.displayCycleDuration,
              textColor,
              textColor,
              isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String title,
    String value,
    Color valueColor,
    Color textColor,
    bool isDark,
  ) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isDark ? Colors.white10 : Colors.grey[200],
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: textColor, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: textColor.withOpacity(0.8),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: valueColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
