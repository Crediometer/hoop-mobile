import 'package:flutter/material.dart';
import 'package:hoop/constants/themes.dart';
import 'package:hoop/dtos/responses/group/index.dart';
import 'package:swipe_cards/swipe_cards.dart';
import 'package:hoop/states/group_state.dart';
import 'package:hoop/dtos/responses/group/Groups.dart';
import 'package:provider/provider.dart';
import 'package:hoop/utils/helpers/formatters/hoop_formatter.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  late MatchEngine _matchEngine;
  final List<SwipeItem> _swipeItems = [];
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
      final provider = Provider.of<GroupCommunityProvider>(context, listen: false);
      
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
          nopeAction: () => _handlePassGroup(group.group),
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
    try {
      final provider = Provider.of<GroupCommunityProvider>(context, listen: false);
      final response = await provider.joinCommunityGroup(group.group.id);
      
      if (response.success) {
        _showSnackBar("Successfully joined ${group.group.name}!");
      } else {
        _showSnackBar("Failed to join group: ${response.message}");
      }
    } catch (error) {
      _showSnackBar("Error joining group: ${error.toString()}");
    }
  }

  void _handlePassGroup(Group group) {
    _showSnackBar("Passed ${group.name}");
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xff0E1318) : Colors.grey[50];

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Consumer<GroupCommunityProvider>(
          builder: (context, provider, child) {
            final groups = provider.communities;
            
            if (_isLoading && groups.isEmpty) {
              return _buildLoadingState(isDark);
            }
            
            if (_hasError && groups.isEmpty) {
              return _buildErrorState(isDark);
            }
            
            if (groups.isEmpty) {
              return _buildEmptyState(isDark);
            }
            
            return selectedTab == 0 ? _buildCardsView(groups) : _buildListView(groups);
          },
        ),
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: HoopTheme.primaryRed,
          ),
          const SizedBox(height: 20),
          Text(
            'Finding groups near you...',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 60,
              color: HoopTheme.primaryRed,
            ),
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

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.group_outlined,
              size: 60,
              color: isDark ? Colors.white70 : Colors.grey,
            ),
            const SizedBox(height: 20),
            Text(
              'No groups found nearby',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Try adjusting your location settings or check back later',
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
              child: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardsView(List<GroupWithScore> groups) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        _buildHeader(isDark),
        const SizedBox(height: 10),
        _buildTabBar(isDark),
        const SizedBox(height: 10),

        Expanded(
          child: _swipeItems.isEmpty 
            ? _buildEmptyCardsState(isDark)
            : _buildSwipeCards(),
        ),
      ],
    );
  }

  Widget _buildEmptyCardsState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.swipe_outlined,
            size: 80,
            color: isDark ? Colors.white30 : Colors.grey[300],
          ),
          const SizedBox(height: 20),
          Text(
            'Swipe cards will appear here',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.white54 : Colors.black54;
    final textTertiary = isDark ? Colors.white30 : Colors.black38;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
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
                  _buildIconButton(
                    Icons.notifications_outlined,
                    textPrimary,
                    isDark,
                  ),
                  const SizedBox(width: 12),
                  _buildIconButton(
                    Icons.tune,
                    textPrimary,
                    isDark,
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

  Widget _buildIconButton(IconData icon, Color color, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.grey[100],
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: () {},
        icon: Icon(icon, color: color, size: 24),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      ),
    );
  }

  Widget _buildTabBar(bool isDark) {
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
                    )
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
      likeTag: Container(
        margin: const EdgeInsets.all(15.0),
        padding: const EdgeInsets.all(10.0),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.green, width: 2.0),
          borderRadius: BorderRadius.circular(10.0),
          color: Colors.green.withOpacity(0.1),
        ),
        child: const Text(
          'JOIN',
          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 24),
        ),
      ),
      nopeTag: Container(
        margin: const EdgeInsets.all(15.0),
        padding: const EdgeInsets.all(10.0),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.red, width: 2.0),
          borderRadius: BorderRadius.circular(10.0),
          color: Colors.red.withOpacity(0.1),
        ),
        child: const Text(
          'PASS',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 24),
        ),
      ),
    );
  }

  Widget _buildListView(List<GroupWithScore> groups) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.white54 : Colors.black54;
    final textTertiary = isDark ? Colors.white30 : Colors.black38;

    return RefreshIndicator(
      onRefresh: _fetchCommunityGroups,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(isDark),
                const SizedBox(height: 20),
                _buildTabBar(isDark),
                const SizedBox(height: 20),
              ],
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final group = groups[index];
                
                // Use dynamic colors from theme
                final cardColor = HoopTheme.getCardColor(index, isDark);
                final category = group.group.tags.isNotEmpty 
                    ? group.group.tags.first 
                    : 'General';
                final categoryColor = HoopTheme.getCategoryColor(category);
                final categoryTextColor = HoopTheme.getCategoryTextColor(category);

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
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
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                                  style: TextStyle(color: textTertiary, fontSize: 11),
                                ),
                              ],
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () => _handleJoinGroup(group),
                              icon: Icon(
                                Icons.favorite_border,
                                color: isDark ? Colors.white70 : HoopTheme.primaryRed,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
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
                              Icon(Icons.location_on_outlined, size: 14, color: textSecondary),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${group.distanceKm!.toStringAsFixed(1)} km away',
                                  style: TextStyle(color: textSecondary, fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 10),
                        if (group.group.description != null && group.group.description!.isNotEmpty)
                          Text(
                            group.group.description!,
                            style: TextStyle(color: textSecondary, fontSize: 13),
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
                              HoopTheme.primaryGreen,
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
              childCount: groups.length,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String title, String value, Color valueColor, bool isDark) {
    final textTertiary = isDark ? Colors.white30 : Colors.black38;
    final chipColor = isDark ? const Color(0xFF141617) : HoopTheme.getCardColor(0, false);
    
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
              Text(value, style: TextStyle(color: valueColor, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}

class _GroupCard extends StatefulWidget {
  final GroupWithScore group;
  
  const _GroupCard({required this.group});
  
  @override
  State<_GroupCard> createState() => __GroupCardState();
}

class __GroupCardState extends State<_GroupCard> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final textSecondary = isDark ? Colors.white70 : const Color(0xFF555555);
    final textTertiary = isDark ? Colors.white54 : const Color(0xFF777777);
    
    // Get dynamic colors from theme
    final swipeColorIndex = widget.group.group.id.hashCode.abs() % HoopTheme.swipeCardColors.length;
    final swipeCardColor = HoopTheme.getCardColor(swipeColorIndex, false);
    final category = widget.group.group.tags.isNotEmpty 
        ? widget.group.group.tags.first 
        : 'General';
    final categoryColor = HoopTheme.getCategoryColor(category);
    final categoryTextColor = HoopTheme.getCategoryTextColor(category);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(24),
      // height: 561,
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 200,
                    child: Text(
                      widget.group.group.name,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "Match: ${widget.group.matchScore.toStringAsFixed(2)}",
                    style: TextStyle(color: textTertiary, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.people_outline, color: textTertiary, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        "${widget.group.group.maxMembers}",
                        style: TextStyle(color: textTertiary, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (widget.group.group.location != null && widget.group.group.location!.isNotEmpty)
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 18, color: textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.group.group.location!,
                    style: TextStyle(color: textSecondary, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 4),
          if (widget.group.distanceKm != null)
            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: Text(
                '${widget.group.distanceKm!.toStringAsFixed(1)} km away',
                style: TextStyle(color: textSecondary, fontSize: 13),
              ),
            ),
          const SizedBox(height: 24),
          if (widget.group.group.description != null && widget.group.group.description!.isNotEmpty)
            Text(
              widget.group.group.description!,
              style: TextStyle(
                color: textSecondary,
                fontSize: 14,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 30),
          _buildDetailRow(
            Icons.attach_money,
            "Contribution amount",
            "₦${widget.group.group.contributionAmount.toStringAsFixed(0)}",
            HoopTheme.primaryGreen,
            textColor,
            isDark,
          ),
          const SizedBox(height: 28),
          _buildDetailRow(
            Icons.account_balance_wallet,
            "Total Pot",
            "₦${(widget.group.group.contributionAmount * widget.group.group.maxMembers).toStringAsFixed(0)}",
            HoopTheme.primaryRed,
            textColor,
            isDark,
          ),
          const SizedBox(height: 28),
          _buildDetailRow(
            Icons.access_time,
            "Cycle duration",
            widget.group.group.displayCycleDuration,
            textColor,
            textColor,
            isDark,
          ),
          const Spacer(),
          Consumer<GroupCommunityProvider>(
            builder: (context, provider, child) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      final matchEngine = context.findAncestorStateOfType<_CommunityScreenState>()?._matchEngine;
                      matchEngine?.currentItem?.nope();
                    },
                    icon: const Icon(Icons.close, color: Colors.red, size: 20),
                    label: const Text(
                      "Pass",
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        await provider.joinCommunityGroup(widget.group.group.id);
                        final matchEngine = context.findAncestorStateOfType<_CommunityScreenState>()?._matchEngine;
                        matchEngine?.currentItem?.like();
                      } catch (error) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to join: ${error.toString()}'),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: HoopTheme.primaryRed,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    ),
                    icon: const Icon(Icons.favorite_border, color: Colors.white, size: 20),
                    label: const Text(
                      "Join",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
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
              Text(title, style: TextStyle(color: textColor, fontSize: 15)),
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