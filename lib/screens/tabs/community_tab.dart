import 'package:flutter/material.dart';
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
  int selectedTab = 0; // 0 → Cards, 1 → List

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
          },
          nopeAction: () {
            print("PASS → ${g['name']}");
          },
        ),
      );
    }

    _matchEngine = MatchEngine(swipeItems: _swipeItems);

    // Check whether user needs to complete primary account setup.
    _checkPrimarySetup();
  }

  Future<void> _checkPrimarySetup() async {
    final prefs = await SharedPreferences.getInstance();
    // If the flag is absent, assume setup is required (first-time user).
    final needsSetup = prefs.getBool('needsSetup') ?? true;
    if (needsSetup) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        // Show the setup-required screen modally. That screen will mark
        // setup as complete when the user finishes.
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const PrimarySetupRequiredScreen(),
          ),
        );
        // Refresh UI after returning from setup flow.
        if (mounted) setState(() {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xff0E1318) : Colors.grey[50];
    final cardBgColor = isDark ? const Color(0xff1E2530) : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.white54 : Colors.black54;
    final textTertiary = isDark ? Colors.white30 : Colors.black38;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -----------------------------------------
            // HEADER
            // -----------------------------------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
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
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.grey[100],
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: () {},
                          icon: Icon(
                            Icons.notifications_outlined,
                            color: textPrimary,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.grey[100],
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: () {},
                          icon: Icon(
                            Icons.tune, // Filter icon alternative
                            color: textPrimary,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Find your perfect thrift community",
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),

            const SizedBox(height: 6),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "🔍 Showing personalized groups near you",
                style: TextStyle(color: textTertiary, fontSize: 12),
              ),
            ),

            const SizedBox(height: 20),

            // -----------------------------------------
            // TOP TABS (Cards | List)
            // -----------------------------------------
            Container(
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
            ),

            const SizedBox(height: 20),

            // -----------------------------------------
            // MAIN CONTENT → SWIPE CARDS
            // -----------------------------------------
            Expanded(
              child: selectedTab == 0
                  ? SingleChildScrollView(
                      child: SizedBox(
                        height: 620, // Enough space for 561px card + margins/swiping
                        child: _buildSwipeCards(context),
                      ),
                    )
                  : _buildListView(isDark),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------
  // TAB WIDGET
  // --------------------------------------------------------------
  Widget _buildTab(String label, IconData icon, int index, bool isDark) {
    final isSelected = selectedTab == index;
    // Active color matching Groups tab style
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

  // --------------------------------------------------------------
  // SWIPE CARDS BUILDER
  // --------------------------------------------------------------
  Widget _buildSwipeCards(BuildContext context) {
    return SwipeCards(
      matchEngine: _matchEngine,

      onStackFinished: () {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("No more groups")));
      },

      itemBuilder: (c, index) {
        final g = groups[index];
        return _buildCard(g);
      },
    );
  }

  // --------------------------------------------------------------
  // CARD UI
  // --------------------------------------------------------------
  Widget _buildCard(Map<String, dynamic> g) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Lavender background for light mode, Darker for dark mode
    final cardBgColor = isDark ? const Color(0xFF1E2530) : const Color(0xFFE0C0FF); 
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final textSecondary = isDark ? Colors.white70 : const Color(0xFF555555);
    final textTertiary = isDark ? Colors.white54 : const Color(0xFF777777);
    
    // Specific colors from the design
    final greenColor = const Color(0xFF00C853);
    final orangeColor = const Color(0xFFFF5722);
    final lightPurpleBg = const Color(0xFFE0C0FF); // Main card bg

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(24),
      height: 561, // Fixed height as requested
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
          // HEADER: Title + Match/Members
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  g["name"] ?? "",
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
                        "Match: ${g["match"]}",
                        style: TextStyle(color: textTertiary, fontSize: 13),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.people_outline, color: textTertiary, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        "${g["members"]}",
                        style: TextStyle(color: textTertiary, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),

          // LOCATION
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 18, color: textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  g["location"] ?? "",
                  style: TextStyle(color: textSecondary, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 4),

          // DISTANCE (Indented slightly to align with text above if needed, or just below)
          Padding(
            padding: const EdgeInsets.only(left: 24), // Align with text of location
            child: Text(
              g["distance"] ?? "",
              style: TextStyle(color: textSecondary, fontSize: 13),
            ),
          ),

          const SizedBox(height: 24),

          // DESCRIPTION
          if (g["description"] != null && g["description"].toString().isNotEmpty)
            Text(
              g["description"],
              style: TextStyle(
                color: textSecondary,
                fontSize: 14,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),

          const SizedBox(height: 30),

          // DETAILS SECTION - Centered with more gap
          
          // Contribution Amount
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.attach_money, color: textColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Contribution amount",
                      style: TextStyle(color: textColor, fontSize: 15),
                    ),
                    Text(
                      g["amount"] ?? "",
                      style: TextStyle(
                        color: greenColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Total Pot
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.attach_money, color: textColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Total Pot",
                      style: TextStyle(color: textColor, fontSize: 15),
                    ),
                    Text(
                      g["pot"] ?? "",
                      style: TextStyle(
                        color: orangeColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Cycle Duration
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                child: Icon(Icons.access_time, color: textColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Cycle duration",
                      style: TextStyle(color: textColor, fontSize: 15),
                    ),
                    Text(
                      g["duration"] ?? "",
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Spacer(),

          // BUTTONS
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () => _matchEngine.currentItem?.nope(),
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
                onPressed: () => _matchEngine.currentItem?.like(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: orangeColor,
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



  // --------------------------------------------------------------
  // LIST VIEW FOR SECOND TAB
  // --------------------------------------------------------------
  Widget _buildListView(bool isDark) {
    final cardBgColor = isDark ? const Color(0xff1E2530) : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.white54 : Colors.black54;
    final textTertiary = isDark ? Colors.white30 : Colors.black38;
    final greenColor = const Color(0xFF00C853);

    return ListView.builder(
      itemCount: groups.length,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemBuilder: (c, i) {
        final g = groups[i];
        // Alternate pastel backgrounds (light mode) to match design image
        final pastelBg = i % 2 == 0 ? const Color(0xFFFFF4EE) : const Color(0xFFEFF7FF);
        final cardColor = isDark ? const Color(0xFF1E2530) : pastelBg;

        // Derive a small category label from the name (first word) as a lightweight placeholder
        final name = g['name'] as String? ?? '';
        final category = name.split(' ').firstWhere((s) => s.isNotEmpty, orElse: () => 'Group');

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
                // Top row: category chip + favorite
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category chip with small members/age below
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF2E2E2E) : const Color(0xFFFFF0E8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Text(
                                category,
                                style: TextStyle(
                                  color: isDark ? Colors.white70 : const Color(0xFFB84B00),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
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

                    // Favourite / heart button
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
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Title
                Text(
                  g['name'] ?? '',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),

                // Location
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

                // Short description
                if (g['description'] != null && g['description'].toString().isNotEmpty)
                  Text(
                    g['description'],
                    style: TextStyle(color: textSecondary, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                const SizedBox(height: 12),

                // Bottom chips: Contribution + Duration
                Row(
                  children: [
                    // Contribution chip
                    Container(
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
                          Icon(Icons.attach_money, color: greenColor, size: 16),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Contribution',
                                style: TextStyle(color: textTertiary, fontSize: 11),
                              ),
                              Text(
                                g['amount'] ?? '',
                                style: TextStyle(color: greenColor, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Duration chip
                    Container(
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
                          Icon(Icons.schedule, color: textTertiary, size: 16),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Duration',
                                style: TextStyle(color: textTertiary, fontSize: 11),
                              ),
                              Text(
                                g['duration'] ?? '',
                                style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
