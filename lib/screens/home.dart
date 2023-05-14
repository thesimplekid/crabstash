import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../screens/send_token.dart';
import '../screens/receive_token.dart';
import '../shared/models/transaction.dart';
import '../shared/models/token.dart';
import '../shared/utils.dart';

class Home extends StatefulWidget {
  final int balance;
  final int activeBalance;
  final String? activeMint;
  final List<Transaction> pendingTransactions;
  final List<Transaction> transactions;
  final Map<String, int> mints;
  final TokenData? tokenData;
  final Function decodeToken;
  final Function receiveToken;
  final Function clearToken;
  final Function send;
  final Function addMint;
  final Function checkTransactionStatus;

  const Home(
      {super.key,
      required this.balance,
      required this.activeBalance,
      required this.activeMint,
      required this.pendingTransactions,
      required this.transactions,
      required this.mints,
      required this.decodeToken,
      required this.receiveToken,
      required this.clearToken,
      required this.send,
      required this.addMint,
      required this.checkTransactionStatus,
      this.tokenData});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  _HomeState();
  int amountToSend = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(top: 20.0),
        child: Column(
          children: [
            SizedBox(
              height: 120.0,
              child: Column(
                children: [
                  const Text(
                    "Active Mint Balance",
                    style: TextStyle(
                      fontSize: 18.0,
                    ),
                  ),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.activeBalance.toString(),
                          style: const TextStyle(
                            fontSize: 60.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ), // Balance Text
                        const SizedBox(
                          height: 60.0,
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Text(" sats"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ), // Balance Container
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.balance),
                  Text(
                    " Total Balance: ${widget.balance.toString()} sats",
                    style: const TextStyle(
                      fontSize: 20.0,
                    ),
                  )
                ],
              ),
            ),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.home),
                  Flexible(
                    child: Text(
                      (widget.activeMint != null)
                          ? " ${widget.activeMint!}"
                          : ' No Mint set',
                      style: const TextStyle(
                        fontSize: 20.0,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  if (widget.pendingTransactions.isNotEmpty)
                    //crossAxisAlignment: CrossAxisAlignment.start,
                    const Text(
                      "Pending Transactions",
                    ),
                  Flexible(
                    child: TransactionList(
                      transactions: widget.pendingTransactions,
                      checkSpendable: widget.checkTransactionStatus,
                      sendToken: _sendTokenDialog,
                    ),
                  ),
                  const Text(
                    "Transactions",
                    textAlign: TextAlign.left,
                  ),
                  Flexible(
                    child: TransactionList(
                        transactions: widget.transactions,
                        checkSpendable: null,
                        sendToken: _sendTokenDialog),
                  ),
                ],
              ),
            ),
            Row(
              // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 70),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SendToken(
                            decodeToken: widget.decodeToken,
                            send: widget.send,
                            activeMint: widget.activeMint,
                            activeBalance: widget.activeBalance,
                          ),
                        ),
                      );
                    },
                    child: const Text('Send'),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 70),
                    ),
                    onPressed: () {
                      widget.clearToken();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReceviceToken(
                            decodeToken: widget.decodeToken,
                            receiveToken: widget.receiveToken,
                            mints: widget.mints,
                            addMint: widget.addMint,
                          ),
                        ),
                      );
                    },
                    child: const Text('Receive'),
                  ),
                ),
              ], // Button row children
            ), // Button Row
          ], // body children
        ), // Body column
      ),
    );
  } // Build widget

  void _sendTokenDialog(int amount, TokenData? token) async {
    late TokenData tokenData;
    if (token == null) {
      String result = await widget.send(amount);
      tokenData = await widget.decodeToken(result);
    } else {
      tokenData = token;
    }

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Send'),
            content: SizedBox(
              height: 200,
              child: Column(
                children: [
                  SizedBox(
                    height: 50,
                    child: SingleChildScrollView(
                      child: Text(tokenData.encodedToken),
                    ),
                  ),
                  Wrap(
                    children: [
                      Text(
                        "Mint: ${tokenData.mint}",
                      ), // Mint Text
                    ],
                  ), // Wrap
                  Text("Amount: ${tokenData.amount} sat(s)")
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: tokenData.encodedToken),
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Copied to clipboard'),
                      ),
                    );
                  }
                },
                child: const Text('Copy'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }
}

class TransactionList extends StatelessWidget {
  final List<Transaction> transactions;
  final Function? checkSpendable;
  final Function sendToken;

  const TransactionList({
    super.key,
    required this.transactions,
    required this.checkSpendable,
    required this.sendToken,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: ListView.builder(
        reverse: true,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: transactions.length,
        itemBuilder: (BuildContext context, int index) {
          IconData statusIcon = Icons.pending;
          Transaction transaction = transactions[index];
          Text amountText;
          switch (transaction.status) {
            case TransactionStatus.sent:
              statusIcon = Icons.call_made;
              amountText = Text(
                "${transaction.token.amount} sats",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w100,
                  color: Colors.red,
                ),
              );
              break;
            case TransactionStatus.received:
              statusIcon = Icons.call_received;
              amountText = Text(
                "${transaction.token.amount} sats",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w100,
                  color: Colors.green,
                ),
              );
              break;
            default:
              amountText = Text(
                "${transaction.token.amount} sats",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w100,
                  color: Colors.red,
                ),
              );
          }

          return GestureDetector(
            onTap: () {
              sendToken(transaction.token.amount, transaction.token);
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon),
                if (checkSpendable != null)
                  GestureDetector(
                    onTap: () {
                      checkSpendable!(transaction);
                    },
                    child: const Icon(Icons.refresh),
                  ),
                const Spacer(),
                Column(
                  children: [
                    Text(
                      transaction.token.memo ?? "No Memo",
                      style: const TextStyle(fontSize: 20),
                    ),
                    Text(
                      formatTimeAgo(transaction.time),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w100,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                amountText,
              ],
            ),
          );
        },
      ),
    );
  }
}
