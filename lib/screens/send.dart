import 'package:flutter/material.dart';

import '../screens/token_info.dart';
import '../shared/models/token.dart';
import '../shared/widgets/numeric_input.dart';

class SendToken extends StatefulWidget {
  final Function send;
  final int activeBalance;
  final Function decodeToken;
  final String? activeMint;

  const SendToken(
      {super.key,
      required this.send,
      required this.activeBalance,
      required this.decodeToken,
      required this.activeMint});

  @override
  SendTokenState createState() => SendTokenState();
}

class SendTokenState extends State<SendToken> {
  final receiveController = TextEditingController();

  TokenData? tokenData;
  int amountToSend = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Token'),
      ),
      body: Center(
        child: Column(
          children: [
            SizedBox(
              height: 100,
              child: NumericInput(
                onValueChanged: (String value) {
                  if (value.isNotEmpty) {
                    amountToSend = int.tryParse(value) ?? amountToSend;
                  }
                },
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // TODO: Alert dialog id balance not enough
                if (amountToSend <= widget.activeBalance && amountToSend > 0) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TokenInfo(
                        amount: amountToSend,
                        mintUrl: widget.activeMint,
                        send: widget.send,
                        decodeToken: widget.decodeToken,
                      ),
                    ),
                  );
                }
              },
              child: const Text('Create Token'),
            ),
          ],
        ),
      ),
    );
  }
}
