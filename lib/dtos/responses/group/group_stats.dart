// lib/models/group_stats.dart
class GroupStats {
  final int totalContributions;
  final double totalAmount;
  final int completedCycles;
  final int activeMembers;
  final int pendingContributions;

  GroupStats({
    required this.totalContributions,
    required this.totalAmount,
    required this.completedCycles,
    required this.activeMembers,
    required this.pendingContributions,
  });

  factory GroupStats.fromJson(Map<String, dynamic> json) {
    return GroupStats(
      totalContributions: json['totalContributions'] ?? 0,
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      completedCycles: json['completedCycles'] ?? 0,
      activeMembers: json['activeMembers'] ?? 0,
      pendingContributions: json['pendingContributions'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalContributions': totalContributions,
      'totalAmount': totalAmount,
      'completedCycles': completedCycles,
      'activeMembers': activeMembers,
      'pendingContributions': pendingContributions,
    };
  }

  // Optional: Copy with method
  GroupStats copyWith({
    int? totalContributions,
    double? totalAmount,
    int? completedCycles,
    int? activeMembers,
    int? pendingContributions,
  }) {
    return GroupStats(
      totalContributions: totalContributions ?? this.totalContributions,
      totalAmount: totalAmount ?? this.totalAmount,
      completedCycles: completedCycles ?? this.completedCycles,
      activeMembers: activeMembers ?? this.activeMembers,
      pendingContributions: pendingContributions ?? this.pendingContributions,
    );
  }

  // Helper getters
  double get averageContribution => totalContributions > 0 
      ? totalAmount / totalContributions 
      : 0.0;

  double get completionPercentage => completedCycles > 0 && activeMembers > 0
      ? (completedCycles / activeMembers) * 100
      : 0.0;

  String get formattedTotalAmount => '\$${totalAmount.toStringAsFixed(2)}';
  String get formattedAverageContribution => '\$${averageContribution.toStringAsFixed(2)}';
}