// lib/services/youtube_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

// YouTube Video Data model
class YouTubeVideoData {
  final String videoId;
  final String title;
  final String description;
  final String thumbnailUrl;
  final String duration; // Formatted duration (e.g., "1:15")
  final int viewCount;
  final int likeCount;
  final String channelTitle;
  final String publishedAt;
  final List<String> tags;

  YouTubeVideoData({
    required this.videoId,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.duration,
    required this.viewCount,
    required this.likeCount,
    required this.channelTitle,
    required this.publishedAt,
    required this.tags,
  });
}

// YouTube Service
class YouTubeService {
  static const String _apiBaseUrl = 'https://www.googleapis.com/youtube/v3';
  final String _apiKey;

  YouTubeService({required String apiKey}) : _apiKey = apiKey;

  // Parse ISO 8601 duration format (e.g., "PT1M15S") to readable format
  static String _parseYouTubeDuration(String duration) {
    final match = RegExp(r'PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?').firstMatch(duration);
    
    if (match == null) return '0:00';
    
    final hours = int.tryParse(match.group(1) ?? '0') ?? 0;
    final minutes = int.tryParse(match.group(2) ?? '0') ?? 0;
    final seconds = int.tryParse(match.group(3) ?? '0') ?? 0;
    
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  // Format date to relative time
  static String _formatRelativeTime(String dateString) {
    final date = DateTime.parse(dateString);
    final now = DateTime.now();
    final diffInSeconds = now.difference(date).inSeconds;
    
    if (diffInSeconds < 60) return 'Just now';
    if (diffInSeconds < 3600) return '${(diffInSeconds / 60).floor()} minutes ago';
    if (diffInSeconds < 86400) return '${(diffInSeconds / 3600).floor()} hours ago';
    if (diffInSeconds < 604800) return '${(diffInSeconds / 86400).floor()} days ago';
    if (diffInSeconds < 2592000) return '${(diffInSeconds / 604800).floor()} weeks ago';
    if (diffInSeconds < 31536000) return '${(diffInSeconds / 2592000).floor()} months ago';
    return '${(diffInSeconds / 31536000).floor()} years ago';
  }

  // Fetch video data from YouTube API
  Future<YouTubeVideoData?> fetchYouTubeVideoData(String videoId) async {
    try {
      final url = '$_apiBaseUrl/videos?part=snippet,contentDetails,statistics&id=$videoId&key=$_apiKey';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        print('YouTube API error: ${response.statusCode} ${response.reasonPhrase}');
        return null;
      }

      final data = json.decode(response.body);
      
      if (data['items'] == null || data['items'].isEmpty) {
        print('Video not found: $videoId');
        return null;
      }

      final video = data['items'][0];
      final snippet = video['snippet'];
      final statistics = video['statistics'];
      final contentDetails = video['contentDetails'];

      return YouTubeVideoData(
        videoId: videoId,
        title: snippet['title'] ?? '',
        description: snippet['description'] ?? '',
        thumbnailUrl: snippet['thumbnails']['maxres']?['url'] ?? 
                     snippet['thumbnails']['high']?['url'] ?? 
                     snippet['thumbnails']['default']['url'],
        duration: _parseYouTubeDuration(contentDetails['duration']),
        viewCount: int.tryParse(statistics['viewCount'] ?? '0') ?? 0,
        likeCount: int.tryParse(statistics['likeCount'] ?? '0') ?? 0,
        channelTitle: snippet['channelTitle'] ?? '',
        publishedAt: _formatRelativeTime(snippet['publishedAt']),
        tags: (snippet['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      );
    } catch (error) {
      print('Error fetching YouTube video data: $error');
      return null;
    }
  }

  // Fetch multiple videos data
  Future<List<YouTubeVideoData>> fetchMultipleYouTubeVideos(List<String> videoIds) async {
    try {
      final ids = videoIds.join(',');
      final url = '$_apiBaseUrl/videos?part=snippet,contentDetails,statistics&id=$ids&key=$_apiKey';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        print('YouTube API error: ${response.statusCode}');
        return [];
      }

      final data = json.decode(response.body);
      
      if (data['items'] == null || data['items'].isEmpty) {
        return [];
      }

      final videos = <YouTubeVideoData>[];
      for (final video in data['items']) {
        final snippet = video['snippet'];
        final statistics = video['statistics'];
        final contentDetails = video['contentDetails'];

        videos.add(YouTubeVideoData(
          videoId: video['id'],
          title: snippet['title'] ?? '',
          description: snippet['description'] ?? '',
          thumbnailUrl: snippet['thumbnails']['maxres']?['url'] ?? 
                       snippet['thumbnails']['high']?['url'] ?? 
                       snippet['thumbnails']['default']['url'],
          duration: _parseYouTubeDuration(contentDetails['duration']),
          viewCount: int.tryParse(statistics['viewCount'] ?? '0') ?? 0,
          likeCount: int.tryParse(statistics['likeCount'] ?? '0') ?? 0,
          channelTitle: snippet['channelTitle'] ?? '',
          publishedAt: _formatRelativeTime(snippet['publishedAt']),
          tags: (snippet['tags'] as List<dynamic>?)?.cast<String>() ?? [],
        ));
      }

      return videos;
    } catch (error) {
      print('Error fetching YouTube videos data: $error');
      return [];
    }
  }

  // Check if YouTube API key is configured
  bool isYouTubeApiConfigured() {
    return _apiKey.isNotEmpty && _apiKey != 'YOUR_YOUTUBE_API_KEY_HERE';
  }
}

// Singleton instance
YouTubeService? _youTubeServiceInstance;

YouTubeService getYouTubeService({required String apiKey}) {
  _youTubeServiceInstance ??= YouTubeService(apiKey: apiKey);
  return _youTubeServiceInstance!;
}