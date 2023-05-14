enum InvoiceStatus { sent, received, pending, failed }

class Invoice {
  InvoiceStatus status;
  DateTime time;
  String? invoice;
  String hash;
  int amount;
  String mintUrl;
  String? memo;

  Invoice(
      {required this.status,
      required this.time,
      required this.hash,
      required this.amount,
      required this.mintUrl,
      this.memo,
      this.invoice});

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {
      'status': status.toString().split('.').last,
      'time': time.toIso8601String(),
      'invoice': invoice,
      'hash': hash,
      'amount': amount,
      'mint_url': mintUrl,
    };
    if (memo != null) {
      json['memo'] = memo;
    }
    return json;
  }

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      status: InvoiceStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
      ),
      time: DateTime.parse(json['time']),
      invoice: json['invoice'],
      hash: json['hash'],
      amount: json['amount'],
      mintUrl: json['mint_url'],
      memo: json.containsKey('memo') ? json['memo'] : null,
    );
  }
}
