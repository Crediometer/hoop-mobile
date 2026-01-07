import 'package:hoop/dtos/podos/enums/TransactionStatus.dart';
import 'package:hoop/dtos/podos/enums/TransactionType.dart';

class Transaction {
  final String id;
  final String userId;
  final String? groupId;
  final TransactionType type;
  final double amount;
  final String currency;
  final TransactionStatus status;
  final String description;
  final String? reference;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? failureReason;

  Transaction({
    required this.id,
    required this.userId,
    this.groupId,
    required this.type,
    required this.amount,
    this.currency = 'USD',
    required this.status,
    required this.description,
    this.reference,
    this.metadata,
    required this.createdAt,
    this.completedAt,
    this.failureReason,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      groupId: json['groupId'],
      type: _parseTransactionType(json['type']),
      amount: (json['amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'USD',
      status: _parseTransactionStatus(json['status']),
      description: json['description'] ?? '',
      reference: json['reference'],
      metadata: json['metadata'] != null 
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
      createdAt: DateTime.parse(json['createdAt']),
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt'])
          : null,
      failureReason: json['failureReason'],
    );
  }

  static TransactionType _parseTransactionType(String type) {
    switch (type) {
      case 'contribution': return TransactionType.contribution;
      case 'withdrawal': return TransactionType.withdrawal;
      case 'penalty': return TransactionType.penalty;
      case 'refund': return TransactionType.refund;
      case 'transfer': return TransactionType.transfer;
      default: return TransactionType.contribution;
    }
  }

  static TransactionStatus _parseTransactionStatus(String status) {
    switch (status) {
      case 'pending': return TransactionStatus.pending;
      case 'completed': return TransactionStatus.completed;
      case 'failed': return TransactionStatus.failed;
      case 'cancelled': return TransactionStatus.cancelled;
      default: return TransactionStatus.pending;
    }
  }
}
