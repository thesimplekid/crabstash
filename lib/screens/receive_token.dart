import 'package:crabstash/shared/models/transaction.dart';
import 'package:flutter/material.dart';
import 'package:cashu/cashu.dart';

import '../shared/models/token.dart';
import '../shared/widgets/add_mint.dart';
import '../screens/create_invoice.dart';

class ReceviceToken extends StatefulWidget {
  final Function decodeToken;
  final Function receiveToken;
  final Function addMint;
  final Function setInvoices;
  final Map<String, int> mints;
  final Cashu cashu;
  final String? activeWallet;
  final List<LightningTransaction> pendingInvoices;
  final List<LightningTransaction> invoices;

  const ReceviceToken({
    super.key,
    required this.decodeToken,
    required this.activeWallet,
    required this.pendingInvoices,
    required this.receiveToken,
    required this.mints,
    required this.invoices,
    required this.addMint,
    required this.cashu,
    required this.setInvoices,
  });

  @override
  ReceiveTokenState createState() => ReceiveTokenState();
}

class ReceiveTokenState extends State<ReceviceToken> {
  final receiveController = TextEditingController();

  TokenData? tokenData;

  @override
  void initState() {
    super.initState();

    // Start listening to changes.
    receiveController.addListener(_decodeToken);
  }

  Future<void> _decodeToken() async {
    String tokenText = receiveController.text;
    TokenData newTokenData = await widget.decodeToken(tokenText);
    setState(() {
      tokenData = newTokenData;
    });
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is removed from the widget tree.
    // This also removes the _printLatestValue listener.
    receiveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receive Token'),
      ),
      body: Center(
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Receive Token',
              ),
              onChanged: (value) async {
                await _decodeToken();
              },
              controller: receiveController,
            ),
            if (tokenData == null)
              Flexible(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 70),
                  ),
                  onPressed: () {
                    if (widget.activeWallet != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CreateInvoice(
                            cashu: widget.cashu,
                            mints: widget.mints,
                            activeMint: widget.activeWallet!,
                            pendingInvoices: widget.pendingInvoices,
                            invoices: widget.invoices,
                            setInvoices: widget.setInvoices,
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text('Create Invoice'),
                ),
              ),
            if (tokenData != null)
              Column(
                children: [
                  Text('Mint:  ${tokenData!.mint}'),
                  Text("${tokenData!.amount.toString()} sats"),
                  ElevatedButton(
                    onPressed: () {
                      // Check token is valid

                      if (tokenData != null) {
                        // Check if mint is trusted
                        if (!widget.mints.containsKey(tokenData!.mint)) {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) => AddMintDialog(
                                "Do you trust this mint?",
                                "A Mint does not know your activity, but it does control the funds",
                                tokenData!.mint,
                                widget.addMint,
                                null),
                          );
                        } else {
                          widget.receiveToken();
                          Navigator.of(context).pop();
                        }
                      }
                    },
                    child: const Text('Redeam'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
