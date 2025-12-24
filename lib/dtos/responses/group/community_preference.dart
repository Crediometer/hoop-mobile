
class CommunityPreference {
  final String? id;
  final String userId;
  final List<String> preferredCategories;
  final double? preferredRadius;
  final bool notificationsEnabled;
  final bool emailNotifications;
  final bool pushNotifications;
  final String createdAt;
  final String updatedAt;

  CommunityPreference({
    this.id,
    required this.userId,
    required this.preferredCategories,
    this.preferredRadius,
    required this.notificationsEnabled,
    required this.emailNotifications,
    required this.pushNotifications,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CommunityPreference.fromJson(Map<String, dynamic> json) {
    return CommunityPreference(
      id: json['id'],
      userId: json['userId'] ?? '',
      preferredCategories: (json['preferredCategories'] as List?)?.cast<String>() ?? [],
      preferredRadius: json['preferredRadius']?.toDouble(),
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      emailNotifications: json['emailNotifications'] ?? true,
      pushNotifications: json['pushNotifications'] ?? true,
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'userId': userId,
      'preferredCategories': preferredCategories,
      if (preferredRadius != null) 'preferredRadius': preferredRadius,
      'notificationsEnabled': notificationsEnabled,
      'emailNotifications': emailNotifications,
      'pushNotifications': pushNotifications,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}