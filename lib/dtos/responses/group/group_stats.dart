
// lib/models/
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
}


