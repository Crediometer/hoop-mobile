import 'package:flutter/material.dart';

class GroupDetailScreen extends StatefulWidget {
  final Map<String, dynamic> group;

  const GroupDetailScreen({
    super.key,
    required this.group,
  });

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  int selectedTab = 0; // 0 = Overview, 1 = Members, 2 = Settings

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : Colors.black;
    final textSecondary = isDark ? Colors.grey[400] : Colors.grey[600];
    final textTertiary = isDark ? Colors.grey[500] : Colors.grey[500];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F111A) : Colors.grey[50],
      body: SingleChildScrollView(
        child: Column(
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
                        onTap: () {},
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

                  // Status badge + rating (pill-shaped)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                        const Text(
                          "Approval Required",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
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
                  const Text(
                    "Rasheed",
                    style: TextStyle(
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
                      const Icon(Icons.people_outline, size: 16, color: Colors.white70),
                      const SizedBox(width: 6),
                      const Text(
                        "1 / 2 members",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 20),
                      const Icon(Icons.location_on_outlined, size: 16, color: Colors.white70),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          "Akure, Ondo, Akure South, Ondo",
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
                    "ufgkhyugcbhgcbbk",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // CONTRIBUTION + CYCLE CHIPS WITH YELLOW BORDER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  border: Border.all(
                    color: const Color(0xFFFFD54F),
                    width: 2.5,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    // Contribution chip
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1A1D27) : Colors.white,
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
                              "₦58,008",
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
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1A1D27) : Colors.white,
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
                              "7 days",
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

            const SizedBox(height: 16),

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
                  ? _buildOverviewTab(isDark, textPrimary, textSecondary, textTertiary)
                  : selectedTab == 1
                      ? _buildMembersTab(isDark, textPrimary, textSecondary)
                      : _buildSettingsTab(isDark, textPrimary, textSecondary),
            ),

            const SizedBox(height: 20),
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
                    )
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

  Widget _buildOverviewTab(bool isDark, Color textPrimary, Color? textSecondary, Color? textTertiary) {
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
                  "12 days left",
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: 0.65,
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
                  "₦7,971 collected",
                  style: TextStyle(
                    color: const Color(0xFF4CAF50),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  "₦31,884 goal",
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
                  Icon(Icons.schedule, size: 18, color: const Color(0xFFE67E22)),
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
                "Sarah Chen • Jan 28, 2024",
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 12,
                ),
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
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Total Pot:",
                    style: TextStyle(
                      color: textTertiary,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    "₦15,942",
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
                    "Start: 12/10/2025",
                    style: TextStyle(
                      color: textTertiary,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    "End: 12/10/2025",
                    style: TextStyle(
                      color: textTertiary,
                      fontSize: 12,
                    ),
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
              _infoRow("Private Group:", "No", textTertiary),
              const SizedBox(height: 8),
              _infoRow("Allow Pairing:", "No", textTertiary),
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
        Text(
          label,
          style: TextStyle(color: color, fontSize: 12),
        ),
        Text(
          value,
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildMembersTab(bool isDark, Color textPrimary, Color? textSecondary) {
    final members = [
      {
        "initials": "OE",
        "name": "OPEYEMI EKUNDAYO",
        "email": "ekundayoelizabeth43@gm...",
        "role": "MEMBER",
        "status": "APPROVED",
        "contributions": "0 contributions",
        "slots": "1 slot(s)",
      },
    ];

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
        Column(
          children: List.generate(
            members.length,
            (index) {
              final member = members[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1D27) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.white10 : Colors.grey[200] ?? Colors.grey,
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
                            color: const Color(0xFF6366F1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              member["initials"] as String,
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
                                member["name"] as String,
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                member["email"] as String,
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
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF2D3139) : Colors.grey[200],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            member["contributions"] as String,
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
                    Row(
                      children: [
                        // Role badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A472A),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 12,
                                color: const Color(0xFF4CAF50),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                member["role"] as String,
                                style: const TextStyle(
                                  color: Color(0xFF4CAF50),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A472A),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            member["status"] as String,
                            style: const TextStyle(
                              color: Color(0xFF4CAF50),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Slots info
                    Text(
                      member["slots"] as String,
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 20),

        // Start Group button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
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

  Widget _buildSettingsTab(bool isDark, Color textPrimary, Color? textSecondary) {
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
                    )
                  ],
          ),
          child: Column(
            children: [
              _settingRow("Notifications", Icons.notifications_outlined, isDark, textPrimary, textSecondary),
              const Divider(),
              _settingRow("Privacy", Icons.lock_outline, isDark, textPrimary, textSecondary),
              const Divider(),
              _settingRow("Leave Group", Icons.exit_to_app_outlined, isDark, textPrimary, Colors.red),
            ],
          ),
        ),
      ],
    );
  }

  Widget _settingRow(String label, IconData icon, bool isDark, Color textPrimary, Color? color) {
    return Row(
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
    );
  }
}
