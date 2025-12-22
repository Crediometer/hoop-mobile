import 'package:flutter/material.dart';

class ShinersTab extends StatefulWidget {
  const ShinersTab({super.key});

  @override
  State<ShinersTab> createState() => _ShinersTabState();
}

class _ShinersTabState extends State<ShinersTab> {
  final List<Map<String, dynamic>> spotlightStories = [
    {
      "id": 1,
      "title": "Apple Watch Series 10 Review: This is It?",
      "author": "EKUNDAYO",
      "category": "TOP SAVER",
      "imageUrl": "https://via.placeholder.com/400x300?text=Apple+Watch",
      "badge": "🏆 Achievement: I STARTED ANOTHER APPLICATION OUT THERE, BUT IT TURNS OUT TO BE THE BEST THING THAT HAPPENED TO ME IN 2022",
      "description": "So... this is the big \"redesign\", eh? Get \$350 off the EightSleep Pod 4 Ultra or \$200 off the Pod 4 at...",
      "views": "4.6M",
      "likes": "106.5K",
      "timeAgo": "1 years ago",
      "tags": ["Realtor", "Youth"],
    },
    {
      "id": 2,
      "title": "5 Best Foods for Hormone Balance",
      "author": "DR. SARAH",
      "category": "WELLNESS",
      "imageUrl": "https://via.placeholder.com/400x300?text=Foods+Hormone",
      "badge": "🌟 Health Tip",
      "description": "Learn the top 5 foods that help balance your hormones naturally and improve your overall health.",
      "views": "2.3M",
      "likes": "89.2K",
      "timeAgo": "2 months ago",
      "tags": ["Health", "Nutrition"],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xff0E1318) : Colors.grey[50];
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.white54 : Colors.black54;
    final textTertiary = isDark ? Colors.white30 : Colors.black38;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Spotlight",
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white10 : Colors.grey[100],
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            onPressed: () {},
                            icon: Icon(
                              Icons.search,
                              color: textPrimary,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          "Real success stories from our community",
                          style: TextStyle(color: textSecondary, fontSize: 14),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {},
                          child: Text(
                            "Live YouTube Data",
                            style: TextStyle(
                              color: const Color(0xFF00BCD4),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // SPOTLIGHT STORIES LIST
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: List.generate(
                    spotlightStories.length,
                    (index) => _buildStoryCard(
                      spotlightStories[index],
                      isDark,
                      textPrimary,
                      textSecondary,
                      textTertiary,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoryCard(
    Map<String, dynamic> story,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color textTertiary,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1D27) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // IMAGE SECTION WITH GRADIENT OVERLAY
          Stack(
            children: [
              // Placeholder image with gradient
              Container(
                height: 240,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  gradient: LinearGradient(
                    colors: [
                      Colors.deepPurple.shade400,
                      Colors.pink.shade300,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.image,
                    size: 80,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
              ),

              // Author avatar
              Positioned(
                left: 16,
                bottom: 16,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B6B),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      story["author"].toString().isNotEmpty
                          ? story["author"].toString()[0]
                          : "E",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // CONTENT SECTION
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Author + Category
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          story["author"],
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            "TOP SAVER",
                            style: TextStyle(
                              color: Color(0xFF2E7D32),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      Icons.favorite_border,
                      color: textTertiary,
                      size: 20,
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ACHIEVEMENT BADGE
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.green.shade900.withOpacity(0.3)
                        : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF4CAF50).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "🏆",
                        style: TextStyle(fontSize: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          story["badge"],
                          style: TextStyle(
                            color: const Color(0xFF4CAF50),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // TITLE
                Text(
                  story["title"],
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 10),

                // DESCRIPTION
                Text(
                  story["description"],
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 12),

                // ENGAGEMENT METRICS
                Row(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.visibility_outlined,
                          size: 16,
                          color: textTertiary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          story["views"],
                          style: TextStyle(
                            color: textTertiary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    Row(
                      children: [
                        Icon(
                          Icons.favorite_border,
                          size: 16,
                          color: textTertiary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          story["likes"],
                          style: TextStyle(
                            color: textTertiary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: textTertiary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      story["timeAgo"],
                      style: TextStyle(
                        color: textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // TAGS
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(
                    (story["tags"] as List).length,
                    (index) {
                      final tag = (story["tags"] as List)[index];
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.1)
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.grey[700],
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
