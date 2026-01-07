
// lib/models/transaction_summary.dart
class TransactionSummary {
  final double totalContributions;
  final double totalWithdrawals;
  final double totalPenalties;
  final double netAmount;
  final int transactionCount;
  final String period;

  TransactionSummary({
    required this.totalContributions,
    required this.totalWithdrawals,
    required this.totalPenalties,
    required this.netAmount,
    required this.transactionCount,
    required this.period,
  });

  factory TransactionSummary.fromJson(Map<String, dynamic> json) {
    return TransactionSummary(
      totalContributions: (json['totalContributions'] ?? 0).toDouble(),
      totalWithdrawals: (json['totalWithdrawals'] ?? 0).toDouble(),
      totalPenalties: (json['totalPenalties'] ?? 0).toDouble(),
      netAmount: (json['netAmount'] ?? 0).toDouble(),
      transactionCount: json['transactionCount'] ?? 0,
      period: json['period'] ?? 'month',
    );
  }
}
