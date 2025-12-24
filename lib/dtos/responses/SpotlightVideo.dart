// lib/models/spotlight_video.dart
import 'package:hoop/dtos/podos/enums/SpotlightVideoStatus.dart';

class SpotlightVideo {
  final int id;
  final String videoId;
  final String title;
  final String userName;
  final String userAvatar;
  final String? userBadge;
  final bool isVerified;
  final String description;
  final String youtubeVideoId;
  final String thumbnail;
  final String duration;
  final int views;
  final int likes;
  final String postedDate;
  final String category;
  final String achievement;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SpotlightVideoStatus status;

  SpotlightVideo({
    required this.id,
    required this.videoId,
    required this.title,
    required this.userName,
    required this.userAvatar,
    this.userBadge,
    required this.isVerified,
    required this.description,
    required this.youtubeVideoId,
    required this.thumbnail,
    required this.duration,
    required this.views,
    required this.likes,
    required this.postedDate,
    required this.category,
    required this.achievement,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
  });

  factory SpotlightVideo.fromJson(Map<String, dynamic> json) {
    return SpotlightVideo(
      id: json['id'] ?? 0,
      videoId: json['videoId'] ?? '',
      title: json['title'] ?? '',
      userName: json['userName'] ?? '',
      userAvatar: json['userAvatar'] ?? '',
      userBadge: json['userBadge'],
      isVerified: json['isVerified'] ?? false,
      description: json['description'] ?? '',
      youtubeVideoId: json['youtubeVideoId'] ?? '',
      thumbnail: json['thumbnail'] ?? '',
      duration: json['duration'] ?? '',
      views: json['views'] ?? 0,
      likes: json['likes'] ?? 0,
      postedDate: json['postedDate'] ?? '',
      category: json['category'] ?? '',
      achievement: json['achievement'] ?? '',
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      status: _parseSpotlightVideoStatus(json['status']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'videoId': videoId,
      'title': title,
      'userName': userName,
      'userAvatar': userAvatar,
      'userBadge': userBadge,
      'isVerified': isVerified,
      'description': description,
      'youtubeVideoId': youtubeVideoId,
      'thumbnail': thumbnail,
      'duration': duration,
      'views': views,
      'likes': likes,
      'postedDate': postedDate,
      'category': category,
      'achievement': achievement,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'status': status.name,
    };
  }

  static SpotlightVideoStatus _parseSpotlightVideoStatus(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE': return SpotlightVideoStatus.active;
      case 'INACTIVE': return SpotlightVideoStatus.inactive;
      case 'PENDING': return SpotlightVideoStatus.pending;
      default: return SpotlightVideoStatus.active;
    }
  }
}