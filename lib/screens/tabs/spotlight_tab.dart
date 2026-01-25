import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hoop/components/indicators/loader.dart';
import 'package:hoop/components/state/empty_state.dart';
import 'package:hoop/dtos/responses/SpotlightVideo.dart';
import 'package:hoop/states/group_state.dart';
import 'package:hoop/utils/helpers/formatters/hoop_formatter.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:story_view/story_view.dart';

class ShinersTab extends StatefulWidget {
  const ShinersTab({super.key});

  @override
  State<ShinersTab> createState() => _ShinersTabState();
}

class _ShinersTabState extends State<ShinersTab> {
  SpotlightVideo? _selectedVideo;
  SpotlightVideo? _videoToPlay;
  YoutubePlayerController? _youtubeController;
  final StoryController _storyController = StoryController();

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
  void dispose() {
    _youtubeController?.dispose();
    _storyController.dispose();
    super.dispose();
  }

  void _handleVideoClick(SpotlightVideo video) {
    setState(() {
      _selectedVideo = video;
    });

    _showYoutubeVideoDetails(context);
  }

  void _handleWatchPreview(SpotlightVideo video) {
    setState(() {
      _videoToPlay = video;
      _selectedVideo = null;

      // Initialize YouTube player controller
      if (video.youtubeVideoId != null && video.youtubeVideoId!.isNotEmpty) {
        _youtubeController = YoutubePlayerController(
          initialVideoId: video.youtubeVideoId!,
          flags: const YoutubePlayerFlags(
            autoPlay: true,
            mute: false,
            controlsVisibleAtStart: true,
          ),
        );
      }
    });
  }

  Future<void> _handleWatchOnYouTube(String videoId) async {
    final url = 'https://www.youtube.com/watch?v=$videoId';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  Future<void> _handleShare(SpotlightVideo video) async {
    final url = 'https://www.youtube.com/watch?v=${video.youtubeVideoId}';

    // For web, you might use the share_plus package for cross-platform sharing
    // For now, we'll just copy to clipboard
    await Clipboard.setData(ClipboardData(text: url));

    // Show a snackbar or toast
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Video link copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _openStoryView(List<SpotlightVideo> videos) {
    final storyItems = videos.map((video) {
      if (video.thumbnail != null && video.thumbnail!.isNotEmpty) {
        return StoryItem.pageImage(
          url: video.thumbnail!,
          caption: Text(video.title ?? ''),
          controller: _storyController,
          duration: Duration(seconds: 5),
        );
      } else {
        return StoryItem.text(
          title: video.title ?? 'No Title',
          backgroundColor: Colors.blue,
        );
      }
    }).toList();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          body: StoryView(
            storyItems: storyItems,
            controller: _storyController,
            inline: false,
            repeat: false,
            onComplete: () {
              Navigator.pop(context);
            },
            onVerticalSwipeComplete: (direction) {
              if (direction == Direction.down) {
                Navigator.pop(context);
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPlayerModal() {
    if (_videoToPlay == null) return SizedBox.shrink();

    return Material(
      color: Colors.black,
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.5)),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFF97316), Color(0xFF0E1318)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      _videoToPlay!.userAvatar ?? "A",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _videoToPlay!.userName ?? 'Anonymous',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${_videoToPlay!.duration ?? "0:00"} • Preview',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _videoToPlay = null;
                      _youtubeController?.pause();
                    });
                  },
                  icon: Icon(Icons.close, color: Colors.white70),
                ),
              ],
            ),
          ),

          // YouTube Player
          Expanded(
            child: Center(
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(maxWidth: 800),
                child: _youtubeController != null
                    ? YoutubePlayer(
                        controller: _youtubeController!,
                        showVideoProgressIndicator: true,
                        progressIndicatorColor: Color(0xFFF97316),
                        progressColors: ProgressBarColors(
                          playedColor: Color(0xFFF97316),
                          handleColor: Color(0xFFF97316),
                        ),
                        onReady: () {
                          print('YouTube player is ready');
                        },
                      )
                    : Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFF97316),
                        ),
                      ),
              ),
            ),
          ),

          // Footer
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.5)),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _handleWatchOnYouTube(_videoToPlay!.youtubeVideoId!);
                  setState(() {
                    _videoToPlay = null;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Color(0xFF0E1318),
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.open_in_new, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Watch Full Video on YouTube',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoDetailsModal() {
    if (_selectedVideo == null) return SizedBox.shrink();

    return GestureDetector(
      onTap: () => setState(() => _selectedVideo = null),
      child: Container(
        color: Colors.black54,
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFF97316), Color(0xFF0E1318)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              _selectedVideo!.userAvatar ?? "A",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedVideo!.userName ?? 'Anonymous',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                HoopFormatters.formatTimeAgo(
                                  HoopFormatters.formatDate(
                                    _selectedVideo!.createdAt!,
                                  ),
                                ),
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () =>
                              setState(() => _selectedVideo = null),
                          icon: Icon(Icons.close, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Thumbnail
                          Container(
                            height: 200,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              image:
                                  _selectedVideo!.thumbnail != null &&
                                      _selectedVideo!.thumbnail!.isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(
                                        _selectedVideo!.thumbnail!,
                                      ),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
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
                          SizedBox(height: 16),

                          // Title
                          Text(
                            _selectedVideo!.title ?? '-',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 12),

                          // Description
                          Text(
                            _selectedVideo!.description ?? '-',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                              height: 1.4,
                            ),
                          ),
                          SizedBox(height: 16),

                          // Stats
                          Row(
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.visibility_outlined,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    HoopFormatters.formatSocialCount(
                                      _selectedVideo!.views ?? 0,
                                    ),
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'views',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(width: 20),
                              Row(
                                children: [
                                  Icon(
                                    Icons.favorite_border,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    HoopFormatters.formatSocialCount(
                                      _selectedVideo!.likes ?? 0,
                                    ),
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'likes',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 16),

                          // Tags
                          if (_selectedVideo!.tags != null &&
                              _selectedVideo!.tags!.isNotEmpty)
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _selectedVideo!.tags!
                                  .map(
                                    (tag) => Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        tag,
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),

                  // Action Buttons
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              _handleWatchPreview(_selectedVideo!);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF0E1318),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.play_arrow, size: 20),
                                SizedBox(width: 8),
                                Text('Watch Preview'),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              _handleWatchOnYouTube(
                                _selectedVideo!.youtubeVideoId!,
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(color: Color(0xFF0E1318)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.open_in_new, size: 20),
                                SizedBox(width: 8),
                                Text('Full Video'),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        IconButton(
                          onPressed: () => _handleShare(_selectedVideo!),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.grey[100],
                            padding: EdgeInsets.all(12),
                          ),
                          icon: Icon(Icons.share, color: Color(0xFF0E1318)),
                        ),
                      ],
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

  Widget _buildStoryView(
    List<SpotlightVideo> videos,
    bool isDark,
    Color textPrimary,
  ) {
    if (videos.isEmpty) {
      return Container(
        height: 120,
        child: Center(
          child: Text(
            'No stories available',
            style: TextStyle(color: textPrimary),
          ),
        ),
      );
    }

    return Column(
      children: [
        // Story View Horizontal Scroll
        Container(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final video = videos[index];
              return GestureDetector(
                onTap: () {
                  // Open full story view
                  _openStoryView(videos);
                },
                child: Container(
                  width: 120,
                  margin: EdgeInsets.only(right: 12, left: index == 0 ? 16 : 0),
                  child: Column(
                    children: [
                      // Story Circle
                      Container(
                        width: 80,
                        height: 80,
                        margin: EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFFF97316), Color(0xFF0E1318)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            video.userAvatar ?? "A",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      // User Name
                      Text(
                        video.userName ?? 'Anonymous',
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      // Video Title
                      Text(
                        video.title ?? '',
                        style: TextStyle(
                          color: textPrimary.withOpacity(0.7),
                          fontSize: 10,
                        ),
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 20),

        // Story Cards Grid
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: List.generate(
              videos.length,
              (index) => GestureDetector(
                onTap: () => _handleVideoClick(videos[index]),
                child: _buildStoryCard(
                  videos[index],
                  isDark,
                  textPrimary,
                  textPrimary.withOpacity(0.7),
                  textPrimary.withOpacity(0.5),
                ),
              ),
            ),
          ),
        ),
      ],
    );
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
        child: Stack(
          children: [
            Consumer<GroupCommunityProvider>(
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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

                              // Segmented control for List View / Story View
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
                          _buildStoryView(spotlightList, isDark, textPrimary),

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
            // Modals
            if (_selectedVideo != null)
              Positioned.fill(child: _buildVideoDetailsModal()),
            if (_videoToPlay != null)
              Positioned.fill(child: _buildVideoPlayerModal()),
          ],
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
                      spotlight.userAvatar ?? "A",
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

  void _showYoutubeVideoDetails(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.85,
          maxChildSize: 0.85,
          expand: false,
          builder: (context, controller) {
            return _buildVideoDetailsModal();
          },
        );
      },
    );
  }
}
