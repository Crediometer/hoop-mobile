// DTO for community preferences
class CommunityPreferences {
  final bool goGlobal;
  final num distanceRadius;
  final String preferredGroupSize;
  final num contributionMin;
  final num contributionMax;
  final num totalPotMin;
  final num totalPotMax;
  final bool groupRecommendations;
  final bool nearbyAlerts;
  final bool communityNotifications;
  final bool autoJoinGroups;

  CommunityPreferences({
    this.goGlobal = true,
    this.distanceRadius = 25,
    this.preferredGroupSize = 'MEDIUM',
    this.contributionMin = 5000,
    this.contributionMax = 50000,
    this.totalPotMin = 50000,
    this.totalPotMax = 500000,
    this.groupRecommendations = true,
    this.nearbyAlerts = true,
    this.communityNotifications = true,
    this.autoJoinGroups = false,
  });

  // Convert to Map for API
  Map<String, dynamic> toJson() => {
    'goGlobal': goGlobal,
    'distanceRadius': distanceRadius,
    'preferredGroupSize': preferredGroupSize,
    'contributionMin': contributionMin,
    'contributionMax': contributionMax,
    'totalPotMin': totalPotMin,
    'totalPotMax': totalPotMax,
    'groupRecommendations': groupRecommendations,
    'nearbyAlerts': nearbyAlerts,
    'communityNotifications': communityNotifications,
    'autoJoinGroups': autoJoinGroups,
  };

  // Factory method to convert from API response (CommunityPreference)
  factory CommunityPreferences.fromCommunityPreference(CommunityPreferences? pref) {
    if (pref == null) {
      return CommunityPreferences(); // Return defaults if no preferences exist
    }

    // Convert BigDecimal to int for Flutter
    int contributionMin = pref.contributionMin?.toInt() ?? 5000;
    int contributionMax = pref.contributionMax?.toInt() ?? 50000;
    int totalPotMin = pref.totalPotMin?.toInt() ?? 50000;
    int totalPotMax = pref.totalPotMax?.toInt() ?? 500000;

    return CommunityPreferences(
      goGlobal: pref.goGlobal ?? true,
      distanceRadius: pref.distanceRadius ?? 25,
      preferredGroupSize: _convertGroupSizeToString(pref.preferredGroupSize),
      contributionMin: contributionMin,
      contributionMax: contributionMax,
      totalPotMin: totalPotMin,
      totalPotMax: totalPotMax,
      groupRecommendations: pref.groupRecommendations ?? true,
      nearbyAlerts: pref.nearbyAlerts ?? true,
      communityNotifications: pref.communityNotifications ?? true,
      autoJoinGroups: pref.autoJoinGroups ?? false,
    );
  }

  // Helper method to convert GroupSize enum to string
  static String _convertGroupSizeToString(dynamic groupSize) {
    if (groupSize == null) return 'MEDIUM';
    
    if (groupSize is String) {
      return groupSize;
    }
    
    // If it's an enum object, get its name
    try {
      final groupSizeStr = groupSize.toString();
      // Extract the enum name from toString() which usually returns "GroupSize.MEDIUM"
      if (groupSizeStr.contains('.')) {
        return groupSizeStr.split('.').last;
      }
      return groupSizeStr;
    } catch (e) {
      return 'MEDIUM';
    }
  }

  // Convert CommunityPreferences to Map for API update
  Map<String, dynamic> toApiMap() {
    return {
      'goGlobal': goGlobal,
      'distanceRadius': distanceRadius,
      'preferredGroupSize': preferredGroupSize,
      'contributionMin': contributionMin,
      'contributionMax': contributionMax,
      'totalPotMin': totalPotMin,
      'totalPotMax': totalPotMax,
      'groupRecommendations': groupRecommendations,
      'nearbyAlerts': nearbyAlerts,
      'communityNotifications': communityNotifications,
      'autoJoinGroups': autoJoinGroups,
    };
  }

  factory CommunityPreferences.fromJson(Map<String, dynamic> json) {
    return CommunityPreferences(
      goGlobal: json['goGlobal'] ?? true,
      distanceRadius: json['distanceRadius'] ?? 25,
      preferredGroupSize: json['preferredGroupSize'] ?? 'MEDIUM',
      contributionMin: json['contributionMin'] ?? 5000,
      contributionMax: json['contributionMax'] ?? 50000,
      totalPotMin: json['totalPotMin'] ?? 50000,
      totalPotMax: json['totalPotMax'] ?? 500000,
      groupRecommendations: json['groupRecommendations'] ?? true,
      nearbyAlerts: json['nearbyAlerts'] ?? true,
      communityNotifications: json['communityNotifications'] ?? true,
      autoJoinGroups: json['autoJoinGroups'] ?? false,
    );
  }

  CommunityPreferences copyWith({
    bool? goGlobal,
    num? distanceRadius,
    String? preferredGroupSize,
    num? contributionMin,
    num? contributionMax,
    num? totalPotMin,
    num? totalPotMax,
    bool? groupRecommendations,
    bool? nearbyAlerts,
    bool? communityNotifications,
    bool? autoJoinGroups,
  }) {
    return CommunityPreferences(
      goGlobal: goGlobal ?? this.goGlobal,
      distanceRadius: distanceRadius ?? this.distanceRadius,
      preferredGroupSize: preferredGroupSize ?? this.preferredGroupSize,
      contributionMin: contributionMin ?? this.contributionMin,
      contributionMax: contributionMax ?? this.contributionMax,
      totalPotMin: totalPotMin ?? this.totalPotMin,
      totalPotMax: totalPotMax ?? this.totalPotMax,
      groupRecommendations: groupRecommendations ?? this.groupRecommendations,
      nearbyAlerts: nearbyAlerts ?? this.nearbyAlerts,
      communityNotifications: communityNotifications ?? this.communityNotifications,
      autoJoinGroups: autoJoinGroups ?? this.autoJoinGroups,
    );
  }
}