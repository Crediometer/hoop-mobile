// lib/services/transactions_http_service.dart
import 'dart:convert';
import 'package:hoop/dtos/podos/tokens/token_manager.dart';
import 'package:hoop/dtos/responses/ApiResponse.dart';
import 'package:hoop/dtos/responses/GeneralResponse/paginated_response.dart';
import 'package:hoop/dtos/responses/WalletPayment/balance.dart';
import 'package:hoop/dtos/responses/WalletPayment/balance_history.dart';
import 'package:hoop/dtos/responses/WalletPayment/transaction.dart';
import 'package:hoop/dtos/responses/WalletPayment/transaction_summary.dart';
import 'package:hoop/services/base_http.dart';


// Transactions HTTP Service that extends BaseHttpService
class TransactionsHttpService extends BaseHttpService {
  TransactionsHttpService({
    required String baseUrl,
  }) : super(baseUrl: baseUrl);

  // ========== TRANSACTION HISTORY ==========

  // Get transactions
  Future<ApiResponse<PaginatedResponse<Transaction>>> getTransactions({
    int page = 1,
    int size = 20,
    String? type,
    String? status,
    String? groupId,
  }) async {
    final params = {
      'page': page,
      'size': size,
      if (type != null) 'type': type,
      if (status != null) 'status': status,
      if (groupId != null) 'groupId': groupId,
    };

    return getTyped<PaginatedResponse<Transaction>>(
      'wallet/transactions',
      queryParameters: params,
      fromJson: (json) => PaginatedResponse<Transaction>.fromJson(
        json,
        (item) => Transaction.fromJson(item),
      ),
    );
  }

  // Get single transaction
  Future<ApiResponse<Transaction>> getTransaction(String id) async {
    return getTyped<Transaction>(
      'transactions/$id',
      fromJson: (json) => Transaction.fromJson(json),
    );
  }

  // Get transaction summary
  Future<ApiResponse<TransactionSummary>> getTransactionSummary({
    String period = 'month',
  }) async {
    return getTyped<TransactionSummary>(
      'wallet/transactions/summary',
      queryParameters: {'period': period},
      fromJson: (json) => TransactionSummary.fromJson(json),
    );
  }

  // ========== WITHDRAWALS ==========

  // Request withdrawal
  Future<ApiResponse<Transaction>> requestWithdrawal(double amount) async {
    return postTyped<Transaction>(
      'wallet/withdraw',
      body: {'amount': amount},
      fromJson: (json) => Transaction.fromJson(json),
    );
  }

  // Get transaction receipt
  Future<ApiResponse<Map<String, dynamic>>> getTransactionReceipt(
    String transactionId,
  ) async {
    return getTyped<Map<String, dynamic>>(
      'transactions/$transactionId/receipt',
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  // ========== BALANCE AND WALLET ==========

  // Get balance
  Future<ApiResponse<BalanceInfo>> getBalance() async {
    return getTyped<BalanceInfo>(
      'wallet/balance',
      fromJson: (json) => BalanceInfo.fromJson(json),
    );
  }

  // Get balance history
  Future<ApiResponse<List<BalanceHistoryItem>>> getBalanceHistory({
    String period = 'month',
  }) async {
    return getTyped<List<BalanceHistoryItem>>(
      'wallet/balance-history',
      queryParameters: {'period': period},
      fromJson: (json) {
        if (json is List) {
          return json.map((item) => BalanceHistoryItem.fromJson(item)).toList();
        }
        return [];
      },
    );
  }
}

// Singleton instance
TransactionsHttpService? _transactionsServiceInstance;

TransactionsHttpService getTransactionsService({
  required String baseUrl,
  required TokenManager tokenManager,
}) {
  _transactionsServiceInstance ??= TransactionsHttpService(
    baseUrl: baseUrl,
  );
  return _transactionsServiceInstance!;
}
