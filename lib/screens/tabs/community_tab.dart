import 'package:flutter/material.dart';
import 'package:hoop/constants/themes.dart';
import 'package:swipe_cards/swipe_cards.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hoop/screens/features/primary_setup_required_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  late MatchEngine _matchEngine;
  final List<SwipeItem> _swipeItems = [];
  int selectedTab = 0;

  final List<Map<String, dynamic>> groups = [
    {
      "name": "Opeyemi thrift",
      "location": "Akure, Ondo, Akure South, Ondo",
      "distance": "7608.2 km away",
      "amount": "₦5,000",
      "pot": "₦20,000",
      "duration": "5 days",
      "match": "0.45",
      "members": "4",
      "description": "ujikccfvghiioiol,,,m\ncsxsderftyuiookkkjjutrewssazzzzaaqwwer",
    },
    {
      "name": "Bello Group",
      "location": "Ikeja, Lagos, Ikeja LGA, Lagos",
      "distance": "12.5 km away",
      "amount": "₦5,200",
      "pot": "₦22,600",
      "duration": "1 week",
      "match": "0.78",
      "members": "5",
      "description": "A thriving thrift community focused on financial growth and mutual support.",
    },
    {
      "name": "Drift thrift",
      "location": "Akure, Ondo, Akure South, Ondo",
      "distance": "7608.2 km away",
      "amount": "₦5,000",
      "pot": "₦20,000",
      "duration": "5 days",
      "match": "0.45",
      "members": "4",
      "description": "ujikccfvghiioiol,,,m\ncsxsderftyuiookkkjjutrewssazzzzaaqwwer",
    },
    {
      "name": "Well Group",
      "location": "Ikeja, Lagos, Ikeja LGA, Lagos",
      "distance": "12.5 km away",
      "amount": "₦5,200",
      "pot": "₦22,600",
      "duration": "1 week",
      "match": "0.78",
      "members": "5",
      "description": "A thriving thrift community focused on financial growth and mutual support.",
    },
  ];

  @override
  void initState() {
    super.initState();

    for (var g in groups) {
      _swipeItems.add(
        SwipeItem(
          content: g,
          likeAction: () {
            print("JOIN → ${g['name']}");
            _showSnackBar("Joined ${g['name']}!");
          },
          nopeAction: () {
            print("PASS → ${g['name']}");
            _showSnackBar("Passed ${g['name']}");
          },
        ),
      );
    }

    _matchEngine = MatchEngine(swipeItems: _swipeItems);
    _checkPrimarySetup();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _checkPrimarySetup() async {
    final prefs = await SharedPreferences.getInstance();
    final needsSetup = prefs.getBool('needsSetup') ?? true;
    if (needsSetup) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const PrimarySetupRequiredScreen(),
          ),
        );
        if (mounted) setState(() {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xff0E1318)
          : Colors.grey[50],
      body: SafeArea(
        child: selectedTab == 0 ? _buildCardsView() : _buildListView(),
      ),
    );
  }

  Widget _buildCardsView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Fixed Header Section
        _buildHeader(isDark),
        const SizedBox(height: 10),
        _buildTabBar(isDark),
        const SizedBox(height: 10),

        // Swipeable Cards Section (with expanded to take remaining space)
        Expanded(
          child: _buildSwipeCards(),
        ),
      ],
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
          Text(
            "🔍 Showing personalized groups near you",
            style: TextStyle(color: textTertiary, fontSize: 12),
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
    final activeTextColor = isDark ? Colors.white : const Color(0xFFFB7F2D);
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
        return _GroupCard(group: groups[index]);
      },
      onStackFinished: () {
        _showSnackBar("No more groups to show");
      },
      // Tinder-like swipe options
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

  Widget _buildListView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.white54 : Colors.black54;
    final textTertiary = isDark ? Colors.white30 : Colors.black38;

    return CustomScrollView(
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
              final g = groups[index];
              final pastelBg = index % 2 == 0 ? const Color(0xFFFFF4EE) : const Color(0xFFEFF7FF);
              final cardColor = isDark ? const Color(0xFF1E2530) : pastelBg;
              final name = g['name'] as String? ?? '';
              final category = name.split(' ').firstWhere((s) => s.isNotEmpty, orElse: () => 'Group');

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
                                  color: isDark ? const Color(0xFF2E2E2E) : const Color(0xFFFFF0E8),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  category,
                                  style: TextStyle(
                                    color: isDark ? Colors.white70 : const Color(0xFFB84B00),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${g['members']} members',
                                style: TextStyle(color: textTertiary, fontSize: 11),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Container(
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF2E2E2E) : Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: isDark
                                  ? null
                                  : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
                            ),
                            child: IconButton(
                              onPressed: () {},
                              icon: Icon(
                                Icons.favorite_border,
                                color: isDark ? Colors.white70 : const Color(0xFFFF6B6B),
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        g['name'] ?? '',
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 14, color: textSecondary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              g['location'] ?? '',
                              style: TextStyle(color: textSecondary, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (g['description'] != null && g['description'].toString().isNotEmpty)
                        Text(
                          g['description'],
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
                            g['amount'] ?? '',
                            const Color(0xFF00C853),
                            isDark,
                          ),
                          const SizedBox(width: 12),
                          _buildDetailChip(
                            Icons.schedule,
                            'Duration',
                            g['duration'] ?? '',
                            textPrimary,
                            isDark,
                          ),
                        ],
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
    );
  }

  Widget _buildDetailChip(IconData icon, String title, String value, Color valueColor, bool isDark) {
    final textTertiary = isDark ? Colors.white30 : Colors.black38;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141617) : Colors.white,
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
  final Map<String, dynamic> group;
  
  const _GroupCard({required this.group});
  
  @override
  State<_GroupCard> createState() => __GroupCardState();
}

class __GroupCardState extends State<_GroupCard> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBgColor = isDark ? HoopTheme.darkCard :HoopTheme.primaryPurple;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final textSecondary = isDark ? Colors.white70 : const Color(0xFF555555);
    final textTertiary = isDark ? Colors.white54 : const Color(0xFF777777);
    final lightPurpleBg = const Color(0xFFE0C0FF);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(24),
      height: 561,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : lightPurpleBg,
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
                child: Text(
                  widget.group["name"] ?? "",
                  style: TextStyle(
                    color: textColor,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Text(
                        "Match: ${widget.group["match"]}",
                        style: TextStyle(color: textTertiary, fontSize: 13),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.people_outline, color: textTertiary, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        "${widget.group["members"]}",
                        style: TextStyle(color: textTertiary, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 18, color: textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.group["location"] ?? "",
                  style: TextStyle(color: textSecondary, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Text(
              widget.group["distance"] ?? "",
              style: TextStyle(color: textSecondary, fontSize: 13),
            ),
          ),
          const SizedBox(height: 24),
          if (widget.group["description"] != null && widget.group["description"].toString().isNotEmpty)
            Text(
              widget.group["description"],
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
            widget.group["amount"] ?? "",
            HoopTheme.primaryGreen,
            textColor,
            isDark,
          ),
          const SizedBox(height: 28),
          _buildDetailRow(
            Icons.attach_money,
            "Total Pot",
            widget.group["pot"] ?? "",
            HoopTheme.primaryRed,
            textColor,
            isDark,
          ),
          const SizedBox(height: 28),
          _buildDetailRow(
            Icons.access_time,
            "Cycle duration",
            widget.group["duration"] ?? "",
            textColor,
            textColor,
            isDark,
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () {},
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
                onPressed: () {},
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