// lib/models/group.dart
class Group {
  final String id;
  final String name;
  final String description;
  final String status;
  final String category;
  final int maxMembers;
  final int currentMembers;
  final double contributionAmount;
  final String contributionFrequency;
  final String startDate;
  final String? endDate;
  final bool isPublic;
  final String creatorId;
  final String createdAt;
  final String updatedAt;
  final bool allowMessage;
  final bool allowVideoCall;
  final double? latitude;
  final double? longitude;

  Group({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
    required this.category,
    required this.maxMembers,
    required this.currentMembers,
    required this.contributionAmount,
    required this.contributionFrequency,
    required this.startDate,
    this.endDate,
    required this.isPublic,
    required this.creatorId,
    required this.createdAt,
    required this.updatedAt,
    this.allowMessage = true,
    this.allowVideoCall = true,
    this.latitude,
    this.longitude,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'pending',
      category: json['category'] ?? 'general',
      maxMembers: json['maxMembers'] ?? 0,
      currentMembers: json['currentMembers'] ?? 0,
      contributionAmount: (json['contributionAmount'] ?? 0).toDouble(),
      contributionFrequency: json['contributionFrequency'] ?? 'monthly',
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'],
      isPublic: json['isPublic'] ?? true,
      creatorId: json['creatorId'] ?? '',
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      allowMessage: json['allowMessage'] ?? true,
      allowVideoCall: json['allowVideoCall'] ?? true,
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'status': status,
      'category': category,
      'maxMembers': maxMembers,
      'currentMembers': currentMembers,
      'contributionAmount': contributionAmount,
      'contributionFrequency': contributionFrequency,
      'startDate': startDate,
      'endDate': endDate,
      'isPublic': isPublic,
      'creatorId': creatorId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'allowMessage': allowMessage,
      'allowVideoCall': allowVideoCall,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
