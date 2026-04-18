class WalletModel {
  final String id;
  final String userId;
  final double balance;
  final String currency;
  final List<TransactionModel> transactions;
  final double totalCredited;
  final double totalDebited;

  WalletModel({
    required this.id,
    required this.userId,
    this.balance = 0,
    this.currency = 'INR',
    this.transactions = const [],
    this.totalCredited = 0,
    this.totalDebited = 0,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      id: json['_id'] ?? '',
      userId: json['userId'] ?? '',
      balance: (json['balance'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'INR',
      transactions: json['transactions'] != null
          ? (json['transactions'] as List)
              .map((t) => TransactionModel.fromJson(t))
              .toList()
          : [],
      totalCredited: (json['totalCredited'] ?? 0).toDouble(),
      totalDebited: (json['totalDebited'] ?? 0).toDouble(),
    );
  }
}

class TransactionModel {
  final String id;
  final String type; // credit / debit
  final double amount;
  final String description;
  final String referenceType;
  final String referenceId;
  final double balanceAfter;
  final DateTime createdAt;

  TransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    this.referenceType = '',
    this.referenceId = '',
    this.balanceAfter = 0,
    required this.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['_id'] ?? '',
      type: json['type'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      description: json['description'] ?? '',
      referenceType: json['referenceType'] ?? '',
      referenceId: json['referenceId'] ?? '',
      balanceAfter: (json['balanceAfter'] ?? 0).toDouble(),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  bool get isCredit => type == 'credit';
}
