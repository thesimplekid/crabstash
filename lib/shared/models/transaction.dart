import './token.dart';

enum TransactionStatus { sent, received, pending }

class Transaction {
  TransactionStatus status;
  DateTime time;
  TokenData token;

  Transaction({required this.status, required this.time, required this.token});

  Map<String, dynamic> toJson() => {
        'status': status.toString().split('.').last,
        'time': time.toIso8601String(),
        'token': token.toJson(),
      };

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      status: TransactionStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
      ),
      time: DateTime.parse(json['time']),
      token: TokenData.fromJson(json['token']),
    );
  }
}
