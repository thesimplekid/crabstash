import './token.dart';
import './invoice.dart';

enum TransactionStatus { sent, received, pending, failed }

abstract class Transaction {
  TransactionStatus status;
  DateTime time;
  int amount;
  String mintUrl;

  Transaction(
      {required this.status,
      required this.time,
      required this.amount,
      required this.mintUrl});
}

class CashuTransaction extends Transaction {
  TokenData token;

  CashuTransaction(
      {required super.status,
      required super.time,
      required super.amount,
      required super.mintUrl,
      required this.token});

  Map<String, dynamic> toJson() => {
        'status': status.toString().split('.').last,
        'time': time.toIso8601String(),
        'amount': amount,
        'mint': mintUrl,
        'token': token.toJson(),
      };

  factory CashuTransaction.fromJson(Map<String, dynamic> json) {
    return CashuTransaction(
      status: TransactionStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
      ),
      time: DateTime.parse(json['time']),
      amount: json['amount'],
      mintUrl: json['mint'],
      token: TokenData.fromJson(json['token']),
    );
  }
}

class LightningTransaction extends Transaction {
  Invoice invoice;

  LightningTransaction(
      {required super.status,
      required super.time,
      required super.mintUrl,
      required super.amount,
      required this.invoice});

  Map<String, dynamic> toJson() => {
        'status': status.toString().split('.').last,
        'time': time.toIso8601String(),
        'amount': amount,
        'mint': mintUrl,
        'invoice': invoice.toJson(),
      };

  factory LightningTransaction.fromJson(Map<String, dynamic> json) {
    return LightningTransaction(
      status: TransactionStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
      ),
      time: DateTime.parse(json['time']),
      amount: json['amount'],
      mintUrl: json['mint'],
      invoice: Invoice.fromJson(json['invoice']),
    );
  }
}
