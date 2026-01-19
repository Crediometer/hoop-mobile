import 'package:flutter/material.dart';
import 'package:hoop/components/indicators/loader.dart';
import 'package:hoop/components/state/empty_state.dart';
import 'package:hoop/dtos/responses/SpotlightVideo.dart';
import 'package:hoop/states/group_state.dart';
import 'package:hoop/utils/helpers/formatters/hoop_formatter.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

class ShinersTab extends StatefulWidget {
  const ShinersTab({super.key});

  @override
  State<ShinersTab> createState() => _ShinersTabState();
}

class _ShinersTabState extends State<ShinersTab> {
  @override
  void initState() {
    super.initState();
    // Load spotlights when tab initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<GroupCommunityProvider>();
      if (provider.spotlight.isEmpty && !provider.isFetchingSpotlight) {
        provider.getSpotlights();
      }
    });
  }

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
        child: Consumer<GroupCommunityProvider>(
          builder: (context, provider, child) {
            final spotlightList = provider.spotlight;
            final isLoading = provider.isFetchingSpotlight;

            return RefreshIndicator(
              onRefresh: () async {
                await provider.refreshSpotlights();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // HEADER
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
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
                              Row(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white10
                                          : Colors.grey[100],
                                      shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      onPressed: () {},
                                      icon: Icon(
                                        Iconsax.search_favorite,
                                        color: textPrimary,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white10
                                          : Colors.grey[100],
                                      shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      onPressed: () =>
                                          provider.refreshSpotlights(),
                                      icon: Icon(
                                        Iconsax.refresh,
                                        color: textPrimary,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  "Real success stories from our community",
                                  style: TextStyle(
                                    color: textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 2.5),
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

                    if (isLoading && spotlightList.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 200.0),
                        child: Center(
                          child: WaveLoader(
                            size: 150, // Custom size
                            waveDuration: Duration(
                              seconds: 3,
                            ), // Custom animation duration
                          ),
                        ),
                      ),

                    if (spotlightList.isEmpty && !isLoading)
                      Padding(
                        padding: const EdgeInsets.only(top: 200.0),
                        child: HoopEmptyState(
                          subtitle: "You might be the shiner!",
                          title: "No spotlight stories yet",
                          iconData: Icons.videocam_off_outlined,
                          onPress: () async {
                            await provider.refreshSpotlights();
                          },
                          secondaryActionText: "Refresh Stories",
                        ),
                      ),

                    if (spotlightList.isNotEmpty && !isLoading)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: List.generate(
                            spotlightList.length,
                            (index) => _buildStoryCard(
                              spotlightList[index],
                              isDark,
                              textPrimary,
                              textSecondary,
                              textTertiary,
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 20),

                    // Loading indicator at bottom if loading more
                    if (isLoading && spotlightList.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: const Color(0xFFF97316),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStoryCard(
    SpotlightVideo spotlight,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color textTertiary,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1D27) : Colors.white,
        borderRadius: BorderRadius.circular(10),
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
          // VIDEO/IMAGE SECTION
          Stack(
            children: [
              // Video thumbnail or image
              Container(
                height: 240,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  image:
                      spotlight.thumbnail != null &&
                          spotlight.thumbnail!.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(spotlight.thumbnail!),
                          fit: BoxFit.cover,
                        )
                      : null,
                  gradient: LinearGradient(
                    colors: [Colors.deepPurple.shade400, Colors.pink.shade300],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child:
                    spotlight.thumbnail == null || spotlight.thumbnail!.isEmpty
                    ? Center(
                        child: Icon(
                          Icons.videocam,
                          size: 80,
                          color: Colors.white.withOpacity(0.3),
                        ),
                      )
                    : null,
              ),

              // Play button overlay
              if (spotlight.youtubeVideoId != null &&
                  spotlight.youtubeVideoId!.isNotEmpty)
                Positioned.fill(
                  child: Center(
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.play_arrow,
                        size: 40,
                        color: Colors.white,
                      ),
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
                    color: _getAvatarColor(spotlight.userName ?? 'A'),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      spotlight?.userAvatar ?? "-",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
              ),

              // Category badge
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    spotlight.category?.isNotEmpty == true
                        ? spotlight.category!.toUpperCase()
                        : 'SPOTLIGHT',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
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
                          spotlight.userName ?? 'Anonymous',
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
                            color: _getCategoryColor(spotlight.category),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            (spotlight.category?.isNotEmpty == true
                                ? spotlight.category!.toUpperCase()
                                : 'SPOTLIGHT'),
                            style: TextStyle(
                              color: _getCategoryTextColor(spotlight.category),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () {
                        // TODO: Implement like functionality
                      },
                      icon: Icon(
                        spotlight.isLiked == true
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: spotlight.isLiked == true
                            ? Colors.red
                            : textTertiary,
                        size: 20,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ACHIEVEMENT BADGE (if available)
                if (spotlight.achievement != null &&
                    spotlight.achievement!.isNotEmpty)
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
                        const Text("🏆", style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            spotlight.achievement!,
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

                if (spotlight.achievement != null &&
                    spotlight.achievement!.isNotEmpty)
                  const SizedBox(height: 14),

                // TITLE
                Text(
                  spotlight.title ?? '-',
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
                  spotlight.description ?? '-',
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                  maxLines: 3,
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
                          HoopFormatters.formatSocialCount(
                            spotlight.views ?? 0,
                          ),
                          style: TextStyle(color: textTertiary, fontSize: 12),
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
                          HoopFormatters.formatSocialCount(
                            spotlight.likes ?? 0,
                          ),
                          style: TextStyle(color: textTertiary, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    Icon(Icons.access_time, size: 16, color: textTertiary),
                    const SizedBox(width: 6),
                    Text(
                      HoopFormatters.formatTimeAgo(
                        HoopFormatters.formatDate(spotlight.createdAt!),
                      ),
                      style: TextStyle(color: textTertiary, fontSize: 12),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // TAGS
                if (spotlight.tags != null && spotlight.tags!.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: spotlight.tags!
                        .map(
                          (tag) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.1)
                                  : Colors.grey[200],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white70
                                    : Colors.grey[700],
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int min(int a, int b) => a < b ? a : b;

  Color _getAvatarColor(String name) {
    final colors = [
      const Color(0xFFFF6B6B),
      const Color(0xFF4ECDC4),
      const Color(0xFF45B7D1),
      const Color(0xFF96CEB4),
      const Color(0xFFFECA57),
      const Color(0xFFFF9FF3),
    ];
    final index = name.isNotEmpty ? name.codeUnitAt(0) % colors.length : 0;
    return colors[index];
  }

  Color _getCategoryColor(String? category) {
    switch (category?.toLowerCase()) {
      case 'top saver':
        return const Color(0xFFE8F5E9);
      case 'wellness':
        return const Color(0xFFE3F2FD);
      case 'investment':
        return const Color(0xFFF3E5F5);
      case 'business':
        return const Color(0xFFFFF3E0);
      default:
        return const Color(0xFFF5F5F5);
    }
  }

  Color _getCategoryTextColor(String? category) {
    switch (category?.toLowerCase()) {
      case 'top saver':
        return const Color(0xFF2E7D32);
      case 'wellness':
        return const Color(0xFF1565C0);
      case 'investment':
        return const Color(0xFF7B1FA2);
      case 'business':
        return const Color(0xFFEF6C00);
      default:
        return const Color(0xFF616161);
    }
  }
}
