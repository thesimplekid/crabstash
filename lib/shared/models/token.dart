class TokenData {
  String encodedToken;
  String mint;
  int amount;
  bool? spendable;
  String? memo;

  TokenData(
      {required this.encodedToken,
      required this.mint,
      required this.amount,
      required this.memo});

  @override
  String toString() {
    return 'Mint: $mint, Amount: $amount';
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {
      'encodedToken': encodedToken,
      'mint': mint,
      'amount': amount,
    };
    if (spendable != null) {
      json['spendable'] = spendable;
    }
    if (memo != null) {
      json['memo'] = memo;
    }

    return json;
  }

  factory TokenData.fromJson(Map<String, dynamic> json) {
    return TokenData(
      encodedToken: json['encodedToken'],
      mint: json['mint'],
      amount: json['amount'],
      memo: json.containsKey('memo') ? json['memo'] : null,
      // spendable: json.containsKey('spendable') ? json['spendable'] : null,
    );
  }
}
