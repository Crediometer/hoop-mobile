import 'package:flutter/material.dart';
import 'package:hoop/screens/features/chat_detail_screen.dart';

class GroupsTab extends StatefulWidget {
  const GroupsTab({super.key});

  @override
  State<GroupsTab> createState() => _GroupsTabState();
}

class _GroupsTabState extends State<GroupsTab> {
  int selectedSegment = 0; // 0 = Current, 1 = Finished, 2 = Pending, 3 = Rejected
  bool _showSearch = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, dynamic>> currentGroups = [
    {
      "initials": "WB",
      "name": "Water business thrift",
      "description": "Gjfkdbdxbnccm",
      "dueDate": "Due Dec 6",
      "timeLeft": "12h",
      "color": const Color(0xFF9C27B0), // Purple
    },
    {
      "initials": "FT",
      "name": "fridey thrift",
      "description": "asdfghjkml, ertgyhijkolsdfghjklasdfghjklyu...",
      "dueDate": "Due Dec 6",
      "timeLeft": "12h",
      "color": const Color(0xFFE91E63), // Pink
    },
    {
      "initials": "RT",
      "name": "rice thrift",
      "description": "qx m, lkjhqsxc l,m nbvcwehkiuytrequsxcio...",
      "dueDate": "Due Dec 4",
      "timeLeft": "23h",
      "color": const Color(0xFFF44336), // Red
    },
    {
      "initials": "TT",
      "name": "thursday thrift",
      "description": "wdfhkhgfdfhgsssgjlkkll,mnnbbvcxzzz...",
      "dueDate": "Due Dec 4",
      "timeLeft": "23h",
      "color": const Color(0xFF00BCD4), // Cyan
    },
    {
      "initials": "WT",
      "name": "Water thrift",
      "description": "Ell do DL to go go go go go go to to go go go...",
      "dueDate": "Due Dec 3",
      "timeLeft": "1d",
      "color": const Color(0xFF9C27B0), // Purple
    },
    {
      "initials": "CS",
      "name": "Credio staff ajo",
      "description": "hroughout the duration of the inter...",
      "dueDate": "Due Dec 2",
      "timeLeft": "3d",
      "color": const Color(0xFFE91E63), // Pink
    },
    {
      "initials": "EV",
      "name": "Evening thrift",
      "description": "Some description here...",
      "dueDate": "Due Nov 27",
      "timeLeft": "Nov 27",
      "color": const Color(0xFFF44336), // Red
    },
  ];

  final List<Map<String, dynamic>> finishedGroups = [
    {
      "initials": "BG",
      "name": "Bello Group",
      "description": "Completed successfully",
      "dueDate": "Nov 15",
      "timeLeft": "Finished",
      "color": const Color(0xFF4CAF50), // Green
    },
  ];

  final List<Map<String, dynamic>> pendingGroups = [
    {
      "initials": "MG",
      "name": "Morning Group",
      "description": "Pending approval...",
      "dueDate": "Dec 10",
      "timeLeft": "Pending",
      "color": const Color(0xFFFF9800), // Orange
    },
    {
      "initials": "NG",
      "name": "Night Group",
      "description": "Waiting for members...",
      "dueDate": "Dec 12",
      "timeLeft": "Pending",
      "color": const Color(0xFF2196F3), // Blue
    },
    {
      "initials": "SG",
      "name": "Sunday Group",
      "description": "Pending confirmation...",
      "dueDate": "Dec 15",
      "timeLeft": "Pending",
      "color": const Color(0xFF673AB7), // Deep Purple
    },
    {
      "initials": "MN",
      "name": "Monday Night",
      "description": "Awaiting start date...",
      "dueDate": "Dec 20",
      "timeLeft": "Pending",
      "color": const Color(0xFFFF5722), // Deep Orange
    },
  ];

  final List<Map<String, dynamic>> rejectedGroups = [
    {
      "initials": "RG",
      "name": "Rejected Group",
      "description": "Application rejected",
      "dueDate": "Dec 1",
      "timeLeft": "Rejected",
      "color": const Color(0xFFF44336), // Red
    },
  ];

  List<Map<String, dynamic>> get displayedGroups {
    List<Map<String, dynamic>> base;
    if (selectedSegment == 0) {
      base = currentGroups;
    } else if (selectedSegment == 1) {
      base = finishedGroups;
    } else if (selectedSegment == 2) {
      base = pendingGroups;
    } else {
      base = rejectedGroups;
    }

    // Apply search query filter
    final q = _searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      base = base.where((g) {
        final name = (g['name'] as String?)?.toLowerCase() ?? '';
        final desc = (g['description'] as String?)?.toLowerCase() ?? '';
        return name.contains(q) || desc.contains(q);
      }).toList();
    }


    return base;
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
            padding: const EdgeInsets.only(left: 20, right: 20, top: 24, bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title / Search row with animation
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _showSearch
                      ? _buildSearchHeader(isDark, textPrimary, textSecondary)
                      : _buildTitleHeader(isDark, textPrimary, textSecondary, displayedGroups, selectedSegment),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // SEGMENTED CONTROL (Current | Finished | Pending | Rejected)
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
                  _buildSegmentButtonFixed("Current (14)", 0, isDark),
                  _buildSegmentButtonFixed("Finished (0)", 1, isDark),
                  _buildSegmentButtonFixed("Pending (4)", 2, isDark),
                  _buildSegmentButtonFixed("Rejected (1)", 3, isDark),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // LIST OF GROUPS
          Expanded(
            child: displayedGroups.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder_open_outlined,
                          size: 64,
                          color: textSecondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No groups",
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: displayedGroups.length,
                    itemBuilder: (context, index) {
                      final group = displayedGroups[index];
                      return _buildGroupCard(group, isDark, textPrimary, textSecondary);
                    },
                  ),
          ),
        ],
      ),

      // FLOATING ACTION BUTTON
      floatingActionButton: Container(
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
          onPressed: () {},
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add, size: 28, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildSegmentButton(String label, int index, bool isDark) {
    final isSelected = selectedSegment == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedSegment = index),
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
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected
                  ? (isDark ? Colors.white : const Color(0xFFFB7F2D))
                  : (isDark ? Colors.grey[500] : Colors.grey[500]),
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentButtonFixed(String label, int index, bool isDark) {
    final isSelected = selectedSegment == index;
    return GestureDetector(
      onTap: () => setState(() => selectedSegment = index),
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
                  )
                ]
              : [],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected
                ? (isDark ? Colors.white : const Color(0xFFFB7F2D))
                : (isDark ? Colors.grey[500] : Colors.grey[500]),
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildGroupCard(
    Map<String, dynamic> group,
    bool isDark,
    Color textPrimary,
    Color? textSecondary,
  ) {
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
                builder: (context) => ChatDetailScreen(group: group),
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
                color: group["color"],
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  group["initials"],
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
                          group["name"],
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
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE4D7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          "Due Dec 6",
                          style: TextStyle(
                            color: Color(0xFFE67E22),
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
                          group["description"],
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
                        group["timeLeft"],
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

  Widget _buildTitleHeader(bool isDark, Color? textPrimary, Color? textSecondary, List displayedGroups, int selectedSegment) {
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
              "${displayedGroups.length} ${selectedSegment == 0 ? 'active' : selectedSegment == 1 ? 'finished' : selectedSegment == 2 ? 'pending' : 'rejected'} groups",
              style: TextStyle(color: textSecondary, fontSize: 13),
            ),
            const SizedBox(width: 12),
            const Text('•', style: TextStyle(color: Colors.redAccent)),
            const SizedBox(width: 8),
            Text('59 new updates', style: TextStyle(color: const Color(0xFFFF6F21), fontSize: 13, fontWeight: FontWeight.w700)),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchHeader(bool isDark, Color? textPrimary, Color? textSecondary) {
    return Column(
      key: const ValueKey('search'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search input + filters
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
                          hintText: 'Search groups by name, category, ...',
                          hintStyle: TextStyle(color: textSecondary, fontSize: 13),
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
                      child: const Icon(Icons.close, size: 20, color: Colors.grey),
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
        // Filter chips
     
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
