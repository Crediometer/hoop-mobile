// lib/models/balance_history.dart
class BalanceHistoryItem {
  final DateTime date;
  final double balance;

  BalanceHistoryItem({
    required this.date,
    required this.balance,
  });

  factory BalanceHistoryItem.fromJson(Map<String, dynamic> json) {
    return BalanceHistoryItem(
      date: DateTime.parse(json['date']),
      balance: (json['balance'] ?? 0).toDouble(),
    );
  }
}