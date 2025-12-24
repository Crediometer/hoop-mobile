// lib/models/balance.dart
class BalanceInfo {
  final double availableBalance;
  final double totalInGroups;
  final double pendingTransactions;
  final String currency;

  BalanceInfo({
    required this.availableBalance,
    required this.totalInGroups,
    required this.pendingTransactions,
    required this.currency,
  });

  factory BalanceInfo.fromJson(Map<String, dynamic> json) {
    return BalanceInfo(
      availableBalance: (json['availableBalance'] ?? 0).toDouble(),
      totalInGroups: (json['totalInGroups'] ?? 0).toDouble(),
      pendingTransactions: (json['pendingTransactions'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'USD',
    );
  }
}